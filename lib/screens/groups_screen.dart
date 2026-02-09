import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'trip_detail_screen.dart';
import 'create_trip_step1.dart';

/// ===============================================================
/// GROUPS SCREEN
/// ---------------------------------------------------------------
/// This screen displays all group trips the user is involved in.
/// A user can:
/// - View trips they own
/// - View trips they joined as a participant
/// - Tap a group to open trip details
/// ===============================================================
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // ===============================================================
  // MAIN UI BUILD
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9), // Light background
      body: CustomScrollView(
        slivers: [
          // 1. Hero Header
          SliverToBoxAdapter(child: _buildHeroHeader()),

          // 2. Group List Content
          StreamBuilder<List<Trip>>(
            stream: TripService.loadGroupTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final trips = snapshot.data ?? [];
              final user = FirebaseAuth.instance.currentUser;

              if (user == null || trips.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              final userGroups = trips.where((t) {
                return t.ownerUid == user.uid || t.members.contains(user.email);
              }).toList();

              if (userGroups.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    message: 'You are not in any group yet',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _groupCard(userGroups[index]),
                    childCount: userGroups.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Optional: FAB for creating group if needed (reserved)
      // floatingActionButton: FloatingActionButton(...)
    );
  }

  // ===============================================================
  // HERO HEADER
  // ===============================================================
  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=2000', // Friends jumping/traveling
              ),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Travel Groups",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Plan and collaborate with friends",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Add Group Button (Floating)
        Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripStep1()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7F50), // Coral
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7F50).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // MODERN GROUP CARD
  // ===============================================================
  Widget _groupCard(Trip trip) {
    // Helper to get image based on destination
    String imageUrl = (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
        ? trip.imageUrl!
        : _getImageForDestination(trip.destination);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // "Shared" Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_rounded,
                          size: 14,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${trip.members.length} Members",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.destination,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Members Avatars
                  Row(
                    children: [
                      SizedBox(
                        height: 32,
                        width: 100, // Roughly enough for 3 stacked
                        child: Stack(
                          children: List.generate(
                            trip.members.length > 4 ? 4 : trip.members.length,
                            (i) {
                              return Positioned(
                                left: i * 20.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Text(
                                      trip.members[i][0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Optional: "View Chat" or status
                      Text(
                        "Active Group",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
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

  String _getImageForDestination(String destination) {
    String lower = destination.toLowerCase();
    if (lower.contains('bali'))
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1000';
    if (lower.contains('kyoto'))
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=1000';
    if (lower.contains('paris'))
      return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000';
    if (lower.contains('tokyo'))
      return 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=1000';
    if (lower.contains('new york'))
      return 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=1000';
    if (lower.contains('london'))
      return 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=1000';
    // Default
    return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000';
  }

  // ===============================================================
  // EMPTY STATE UI
  // ===============================================================
  Widget _buildEmptyState({String message = 'No group trips yet'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.luggage_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Adventure is better together",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
