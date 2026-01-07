import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/destination_model.dart';
import '../data/destinations_data.dart';

class DestinationVoteScreen extends StatefulWidget {
  final String tripId;

  const DestinationVoteScreen({super.key, required this.tripId});

  @override
  State<DestinationVoteScreen> createState() => _DestinationVoteScreenState();
}

class _DestinationVoteScreenState extends State<DestinationVoteScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool pollFixed = false;

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  void initState() {
    super.initState();
    print("🔥 DEST COUNT = ${destinations.length}");
  }

  /// CREATE POLL
  Future<void> _createFreshPoll() async {
    final List<Map<String, dynamic>> options =
        destinations.map((d) {
      return {
        "name": d.name,
        "image": d.image,
        "votes": [],
      };
    }).toList();

    await FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.tripId)
        .collection("votes")
        .doc("destinationPoll")
        .set({
      "question": "Where should we go?",
      "isClosed": false,
      "options": options,
    });

    print("✅ Poll Created with ${options.length} destinations");
  }

  /// VOTE
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

      for (var o in options) {
        if ((o["votes"] as List).contains(uid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You already voted!")),
          );
          return;
        }
      }

      for (var o in options) {
        if (o["name"] == optionName) {
          (o["votes"] as List).add(uid);
        }
      }

      transaction.update(docRef, {"options": options});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Vote Destination"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("trips")
            .doc(widget.tripId)
            .collection("votes")
            .doc("destinationPoll")
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: ElevatedButton(
                onPressed: _createFreshPoll,
                child: const Text("Start Destination Vote"),
              ),
            );
          }

          final data = snapshot.data!;
          final List options = List.from(data["options"]);

          if (!pollFixed && options.length != destinations.length) {
            pollFixed = true;
            _createFreshPoll();
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["question"],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: darkNavy),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final option = options[i];
                      final votes = option["votes"] as List;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                option["image"],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option["name"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${votes.length} votes",
                                    style: const TextStyle(
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.how_to_vote),
                              onPressed: () => _vote(option["name"]),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
