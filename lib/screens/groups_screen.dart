import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'trip_detail_screen.dart';

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
      body: CustomScrollView(
        slivers: [
          // 1. MODERN APP BAR
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: bgLight,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'My Groups',
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.group_add_rounded, color: primaryBlue, size: 22),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),

          // 2. CONTENT AREA
          StreamBuilder<List<Trip>>(
            stream: TripService.loadGroupTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: primaryBlue)),
                );
              }

              final trips = snapshot.data ?? [];
              final user = FirebaseAuth.instance.currentUser;

              if (user == null || trips.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              final userGroups = trips.where(
                (t) => t.ownerUid == user.uid || t.members.contains(user.email),
              ).toList();

              if (userGroups.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(message: 'You are not in any group yet'));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
    );
  }

  // ================= STYLIZED GROUP CARD =================
  Widget _groupCard(Trip trip) {
    final user = FirebaseAuth.instance.currentUser!;
    final bool isOwner = trip.ownerUid == user.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon/Avatar Representation
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.groups_3_rounded, color: primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destination,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: darkNavy
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOwner ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOwner ? "OWNER" : "JOINED",
                      style: TextStyle(
                        color: isOwner ? Colors.green.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Info Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: bgLight.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Member Stack (Visual Simulation)
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: Stack(
                      children: List.generate(
                        trip.members.length > 3 ? 3 : trip.members.length,
                        (i) => Positioned(
                          left: i * 15,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: primaryBlue.withAlpha(150),
                              child: Text(
                                trip.members[i][0].toUpperCase(),
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${trip.members.length} Members',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
              ],
            ),
            child: Icon(Icons.group_off_rounded, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            "Adventure is better together",
            style: TextStyle(color: darkNavy, fontSize: 18, fontWeight: FontWeight.bold),
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