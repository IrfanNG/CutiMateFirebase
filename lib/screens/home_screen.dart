import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'explore_screen.dart';
import 'groups_screen.dart';
import 'profile_screen.dart';
import 'create_trip_step1.dart';
import 'trip_detail_screen.dart';
import 'budget_overview_screen.dart';
import '/services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // CutiMate Theme Colors
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgLight = const Color(0xFFF6F7F9);

  Widget _getPage() {
    switch (_currentIndex) {
      case 0:
        return _home();
      case 1:
        return const ExploreScreen();
      case 2:
        return const GroupsScreen();
      case 3:
        return ProfileScreen(
          onBack: () {
            setState(() => _currentIndex = 0);
          },
        );
      default:
        return _home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: _getPage(),
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
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Groups'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // ================= HOME =================
  Widget _home() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4E6B)),
            ),
          ),
          const SizedBox(height: 12),
          _services(),
          const SizedBox(height: 32),
          _upcomingTrip(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, primaryBlue.withBlue(230)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CutiMate',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              const Text(
                'Where to next?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 3),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: bgLight,
                child: Icon(Icons.person_rounded, color: primaryBlue, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _services() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _service(Icons.add_location_alt_rounded, 'New Trip', () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripStep1()));
          }),
          _service(Icons.map_rounded, 'Explore', () {
            setState(() => _currentIndex = 1);
          }),
          _service(Icons.people_alt_rounded, 'Groups', () {
            setState(() => _currentIndex = 2);
          }),
          _service(Icons.account_balance_wallet_rounded, 'Budget', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetOverviewScreen()));
          }),
        ],
      ),
    );
  }

  Widget _service(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: primaryBlue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkNavy)),
        ],
      ),
    );
  }

  // ================= UPCOMING TRIP =================
  Widget _upcomingTrip() {
    return StreamBuilder<List<Trip>>(
      stream: TripService.loadUserTrips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];
        if (trips.isEmpty) {
          return _buildEmptyState();
        }

        final today = DateTime.now();
        final upcoming = trips.where((t) => t.endDate.isAfter(today) || _isSameDay(t.endDate, today)).toList();
        final past = trips.where((t) => t.endDate.isBefore(today)).toList();

        upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
        past.sort((a, b) => b.startDate.compareTo(a.startDate));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Adventures'),
                const SizedBox(height: 12),
                ...upcoming.map((trip) => _tripCard(trip, isPast: false)).toList(),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionHeader('Past Memories'),
                const SizedBox(height: 12),
                ...past.map((trip) => _tripCard(trip, isPast: true)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.beach_access_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No trips planned yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _tripCard(Trip trip, {bool isPast = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Blue accent bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey : primaryBlue,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
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
                          Text(
                            trip.destination,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _badge(Icons.people_outline_rounded, '${trip.travelers} Pax'),
                          const SizedBox(width: 12),
                          _badge(Icons.payments_outlined, 'RM ${trip.budget.toStringAsFixed(0)}'),
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
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: darkNavy),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: darkNavy, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}