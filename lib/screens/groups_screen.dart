import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'trip_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // CutiMate Theme Colors
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgLight = const Color(0xFFF6F7F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      // Using a cleaner AppBar that fits the modern travel theme
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          'My Groups',
          style: TextStyle(
            color: darkNavy, 
            fontWeight: FontWeight.w900, 
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add_rounded, color: primaryBlue),
            onPressed: () {
              // Action to create/join new group could go here
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<List<Trip>>(
        stream: TripService.loadGroupTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final trips = snapshot.data ?? [];
          final user = FirebaseAuth.instance.currentUser;

          if (user == null || trips.isEmpty) {
            return _buildEmptyState();
          }

          final userGroups = trips.where(
            (t) => t.ownerUid == user.uid || t.members.contains(user.email),
          ).toList();

          if (userGroups.isEmpty) {
            return _buildEmptyState(message: 'You are not in any group yet');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: userGroups.length,
            itemBuilder: (context, index) => _groupCard(userGroups[index]),
          );
        },
      ),
    );
  }

  // ================= GROUP CARD =================
  Widget _groupCard(Trip trip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Decorative side accent
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryBlue, primaryBlue.withOpacity(0.5)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.groupName.isEmpty ? trip.destination : trip.groupName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Member Count Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.people_alt_rounded, size: 14, color: primaryBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${trip.members.length} members',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date Info
                            Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No group trips yet'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}