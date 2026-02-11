import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'explore_screen.dart';
import 'groups_screen.dart';
import 'profile_screen.dart';
import 'create_trip_step1.dart';
import 'trip_detail_screen.dart';
import 'all_trips_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ===============================================================
/// HOME SCREEN
/// ---------------------------------------------------------------
/// Main landing screen of the app.
/// Handles:
/// - Bottom navigation
/// - Home dashboard
/// - Upcoming trips
/// - Navigation to other main features
/// ===============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Current index for BottomNavigationBar
  int _currentIndex = 0;

  /// CutiMate theme colors
  final Color bgLight = const Color(0xFFF6F7F9);

  /// ===============================================================
  /// Returns the page based on selected bottom navigation index
  /// ===============================================================
  Widget _getPage() {
    switch (_currentIndex) {
      case 0:
        return _home();
      case 1:
        return ExploreScreen(onBack: () => setState(() => _currentIndex = 0));
      case 2:
        return const GroupsScreen();
      case 3:
        return ProfileScreen(
          onBack: () {
            // Return to Home tab when exiting profile
            setState(() => _currentIndex = 0);
          },
        );
      default:
        return _home();
    }
  }

  /// ===============================================================
  /// MAIN UI BUILD
  /// ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      /// Display selected page
      body: _getPage(),

      /// Bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(
            0xFFFF7F50,
          ), // Coral Orange for selected
          unselectedItemColor: Colors
              .grey
              .shade500, // Slightly darker grey for better visibility
          /// Change tab when tapped
          onTap: (i) => setState(() => _currentIndex = i),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // HOME DASHBOARD CONTENT
  // ===============================================================
  Widget _home() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Header + Overlapping Plan Card
          // Fixed height stack to ensure the overlapping card is fully hit-testable
          SizedBox(
            height: 380, // 320 (Hero) + 60 (Overhang)
            child: Stack(
              children: [
                // Background Section
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 320,
                  child: _buildHeroSection(),
                ),
                // Card
                Positioned(
                  bottom: 0, // Aligns to bottom of 380px, so 60px below image
                  left: 20,
                  right: 20,
                  child: _buildPlanJourneyCard(),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ), // Reduced spacing since stack now includes the 60px overhang
          // 2. Upcoming Trips
          _upcomingTrip(),

          const SizedBox(height: 10),

          // 3. Shared Trips (Replaced Saved Destinations)
          _buildSharedTrips(),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  // ===============================================================
  // HERO SECTION
  // Background Image + Greeting + Profile Icon
  // ===============================================================
  Widget _buildHeroSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      height: 320, // Tall header for background image
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070&auto=format&fit=crop', // Scenic mountain/lake background
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Greeting Text with FutureBuilder for Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),

                      // Fetch user name
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String name = "Traveler";
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null && data.containsKey('name')) {
                              name = data['name'];
                              // Get first name only if it's long?
                              // name = name.split(' ').first;
                            }
                          } else if (user?.displayName != null) {
                            name = user!.displayName!;
                          }

                          return Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Profile Avatar
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12',
                        ), // Mock profile
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // PLAN JOURNEY CARD (CTA)
  // Overlaps the hero section
  // ===============================================================
  Widget _buildPlanJourneyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95), // Glassmorphism-ish
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READY FOR ADVENTURE?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan your next journey',
            style: TextStyle(
              fontSize: 20, // Increased size
              fontWeight: FontWeight
                  .bold, // Serif-style font would be nice here if available
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
              fontFamily: 'serif', // Trying generic serif for elegance
            ),
          ),
          const SizedBox(height: 20),

          // Create New Trip Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTripStep1()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFF7F50,
                ), // Coral color from mockup
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create New Trip',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // UPCOMING TRIPS SECTION (Allocated for "My Trips")
  // Loads owned trips using Firebase streams
  // Horizontal ListView
  // ===============================================================
  Widget _upcomingTrip() {
    final user = FirebaseAuth.instance.currentUser!;

    final ownedTrips = FirebaseFirestore.instance
        .collection('trips')
        .where('ownerUid', isEqualTo: user.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: ownedTrips,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        var trips = docs
            .map((d) => Trip.fromJson(d.id, d.data() as Map<String, dynamic>))
            .toList();

        // Filter out past trips (keep trips ending today or in future)
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        trips = trips.where((t) {
          return !t.endDate.isBefore(todayStart);
        }).toList();

        // Sort by start date
        trips.sort((a, b) => a.startDate.compareTo(b.startDate));

        return Column(
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upcoming Trips",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AllTripsScreen(type: TripListType.upcoming),
                        ),
                      );
                    },
                    child: Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7F50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (trips.isEmpty)
              _buildEmptyNotification("You have no upcoming trips.")
            else
              SizedBox(
                height: 240,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: trips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return _tripCard(trips[index]);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // SHARED TRIPS SECTION
  // Replaces "Saved Destinations"
  // Loads trips where user is a member (invited)
  // Grid Layout
  // ===============================================================
  Widget _buildSharedTrips() {
    final user = FirebaseAuth.instance.currentUser!;

    final invitedTrips = FirebaseFirestore.instance
        .collection('trips')
        .where('members', arrayContains: user.email)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: invitedTrips,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Loading state for shared section
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        final tripsData = docs
            .map((d) => Trip.fromJson(d.id, d.data() as Map<String, dynamic>))
            .toList();

        // Filter OUT trips where I am the owner AND past trips
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final trips = tripsData.where((t) {
          if (t.ownerUid == user.uid) return false;
          return !t.endDate.isBefore(todayStart);
        }).toList();

        // Sort by start date
        trips.sort((a, b) => a.startDate.compareTo(b.startDate));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Shared Trips",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AllTripsScreen(type: TripListType.shared),
                        ),
                      );
                    },
                    child: Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7F50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (trips.isEmpty)
                _buildEmptyNotification("No shared trips yet.")
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, // Taller for grid cards
                  ),
                  itemBuilder: (context, index) {
                    return _sharedTripGridCard(trips[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // HELPER: Empty State Text
  // ===============================================================
  Widget _buildEmptyNotification(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // TRIP CARD (Horizontal List Item)
  // For "Upcoming Trips"
  // ===============================================================
  Widget _tripCard(Trip trip) {
    final daysLeft = trip.startDate.difference(DateTime.now()).inDays;
    String badgeText = daysLeft > 0
        ? "$daysLeft DAYS LEFT"
        : (daysLeft == 0 ? "TODAY" : "ONGOING");
    if (daysLeft < 0 && trip.endDate.isBefore(DateTime.now())) {
      badgeText = "COMPLETED";
    }

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
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: Colors.grey.shade300, height: 160),
                  ),
                ),
                if (daysLeft >= 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info Area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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

  // ===============================================================
  // SHARED TRIP GRID CARD
  // For "Shared Trips"
  // ===============================================================
  Widget _sharedTripGridCard(Trip trip) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: Colors.grey.shade200),
                    ),
                  ),
                  // Shared Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        size: 14,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${trip.travelers} Members",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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

  // Helper to get consistent placeholder images
  String _getImageForDestination(String destination) {
    String lower = destination.toLowerCase();
    if (lower.contains('bali')) {
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1000';
    }
    if (lower.contains('kyoto')) {
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=1000';
    }
    if (lower.contains('paris')) {
      return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000';
    }
    if (lower.contains('tokyo')) {
      return 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=1000';
    }
    if (lower.contains('new york')) {
      return 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=1000';
    }
    if (lower.contains('london')) {
      return 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=1000';
    }

    // Default random-ish based on length to be deterministic per load
    return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000';
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}";
  }
}
