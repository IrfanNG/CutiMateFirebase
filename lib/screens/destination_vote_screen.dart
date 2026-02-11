import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/destination_service.dart'; // Added import

/// ===============================================================
/// DESTINATION VOTE SCREEN (SOCIAL UX)
/// ---------------------------------------------------------------
/// Enhanced voting experience with:
/// - Vote Progress Dashboard (Header)
/// - Interactive Cards (Select/Unselect)
/// - Social Proof (Avatar piles of who voted)
/// ===============================================================
class DestinationVoteScreen extends StatefulWidget {
  final String tripId;

  const DestinationVoteScreen({super.key, required this.tripId});

  @override
  State<DestinationVoteScreen> createState() => _DestinationVoteScreenState();
}

class _DestinationVoteScreenState extends State<DestinationVoteScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  // pollFixed removed as it was for static data sync

  // Colors
  final Color primaryOrange = const Color(0xFFFF7F50); // Coral Orange
  final Color darkNavy = const Color(0xFF111827); // Dark
  final Color cardBg = Colors.white;
  final Color bgLight = const Color(0xFFF6F7F9);

  @override
  void initState() {
    super.initState();
  }

  /// Create fresh poll if none exists
  Future<void> _createFreshPoll() async {
    try {
      // 1. Fetch Trip Data to get current destination
      final tripSnap = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (!tripSnap.exists) return;
      final tripData = tripSnap.data()!;
      final String currentDestination = tripData['destination'] ?? 'Malaysia';

      // 2. Fetch Similar Destinations
      // This will return [original, similar1, similar2, ...]
      final candidates = await DestinationService.getSimilarDestinations(
        currentDestination,
      );

      // 3. Create Options
      final List<Map<String, dynamic>> options = candidates.map((d) {
        return {
          "name": d.name,
          "image": d.image,
          "votes": [], // list of user IDs
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection("trips")
          .doc(widget.tripId)
          .collection("votes")
          .doc("destinationPoll")
          .set({
            "question": "Which destination is best?",
            "isClosed": false,
            "options": options,
          });
    } catch (e) {
      debugPrint("Error creating poll: $e");
    }
  }

  /// Toggle Vote: If already voted for this, remove. If not, add (and remove from others).
  Future<void> _vote(String optionName) async {
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.tripId)
        .collection("votes")
        .doc("destinationPoll");

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      List options = List.from(data["options"]);

      // Check current vote status
      bool alreadyVotedForThis = false;

      // 1. Remove user from ALL options first (to ensure single choice)
      for (var o in options) {
        final votes = o["votes"] as List;
        if (votes.contains(uid)) {
          if (o["name"] == optionName) {
            alreadyVotedForThis = true; // User tapped same option -> Unvote
          }
          votes.remove(uid);
        }
      }

      // 2. If it wasn't a "retract" tap, add vote to target
      if (!alreadyVotedForThis) {
        for (var o in options) {
          if (o["name"] == optionName) {
            (o["votes"] as List).add(uid);
            break;
          }
        }
      }

      transaction.update(docRef, {"options": options});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text(
          "Group Vote",
          style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. Listen to Trip Document (to get member count)
        stream: FirebaseFirestore.instance
            .collection("trips")
            .doc(widget.tripId)
            .snapshots(),
        builder: (context, tripSnap) {
          if (!tripSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tripData = tripSnap.data!.data() as Map<String, dynamic>?;
          if (tripData == null) {
            return const Center(child: Text("Trip not found"));
          }

          // Get total members
          final members = List<String>.from(
            tripData['members'] ?? [],
          ); // list of emails usually roughly
          // Fallback: if 'travelers' count exists use that, or members list length
          final totalMembers = members.isEmpty
              ? (tripData['travelers'] ?? 1)
              : members.length;

          // 2. Listen to Poll Document
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("trips")
                .doc(widget.tripId)
                .collection("votes")
                .doc("destinationPoll")
                .snapshots(),
            builder: (context, pollSnap) {
              // Handle "No Poll Created Yet"
              if (!pollSnap.hasData || !pollSnap.data!.exists) {
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: _createFreshPoll,
                    icon: const Icon(Icons.poll),
                    label: const Text("Start Destination Vote"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              }

              final pollData = pollSnap.data!.data() as Map<String, dynamic>;
              final List options = List.from(pollData["options"]);

              // CALCULATE STATS
              final allVotes = <String>{}; // unique user IDs who voted
              Map<String, dynamic>? winner;
              int maxVotes = 0;

              for (var o in options) {
                final votes = o["votes"] as List;
                if (votes.length > maxVotes) {
                  maxVotes = votes.length;
                  winner = o;
                }
                for (var v in votes) {
                  allVotes.add(v);
                }
              }
              final votedCount = allVotes.length;
              final progress = (totalMembers > 0)
                  ? (votedCount / totalMembers)
                  : 0.0;

              return Column(
                children: [
                  // === WINNER HUD ===
                  if (winner != null && maxVotes > 0)
                    _buildWinnerWidget(winner, maxVotes),

                  // === DASHBOARD ===
                  _buildStatusDashboard(votedCount, totalMembers, progress),

                  // === OPTIONS LIST ===
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return _buildVoteCard(options[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ================= WINNER WIDGET =================
  Widget _buildWinnerWidget(Map<String, dynamic> option, int votes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryOrange, primaryOrange.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Favorite",
                  style: TextStyle(
                    color: Color(0xFFFF7F50).withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  option["name"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$votes votes",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: option["image"].startsWith('http')
                ? Image.network(
                    option["image"],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 20),
                      );
                    },
                  )
                : Image.asset(
                    option["image"],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
          ),
        ],
      ),
    );
  }

  // ================= DASHBOARD WIDGET =================
  Widget _buildStatusDashboard(int votedCount, int total, double progress) {
    bool isComplete = votedCount >= total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        isComplete ? Colors.green : primaryOrange,
                      ),
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: darkNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? "Voting Complete!" : "Voting in Progress",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? Colors.green : darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$votedCount of $total members have voted",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= VOTE CARD WIDGET =================
  Widget _buildVoteCard(Map<String, dynamic> option) {
    final votes = option["votes"] as List;
    final bool isSelected = votes.contains(user.uid);
    final int count = votes.length;

    return GestureDetector(
      onTap: () => _vote(option["name"]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: primaryOrange, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: option["image"].startsWith('http')
                  ? Image.network(
                      option["image"],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 24),
                        );
                      },
                    )
                  : Image.asset(
                      option["image"],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option["name"],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryOrange : Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: primaryOrange,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Avatar Pile / Vote Count
                  Row(
                    children: [
                      // Fake "Face Pile" (just using generated colors/initials since we have UIDs)
                      // In a real app, you'd map UIDs to User Profiles.
                      if (count > 0)
                        SizedBox(
                          height: 24,
                          width: (count > 3 ? 3 : count) * 18.0 + 10,
                          child: Stack(
                            children: List.generate(
                              count > 3 ? 3 : count,
                              (i) => Positioned(
                                left: i * 16.0,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor:
                                        Colors.primaries[option["name"].length %
                                            Colors.primaries.length],
                                    child: Icon(
                                      Icons.person,
                                      size: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      Text(
                        count == 0 ? "Be the first to vote" : "$count votes",
                        style: TextStyle(
                          fontSize: 12,
                          color: count > 0
                              ? primaryOrange
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
