import 'package:flutter/material.dart';
import 'package:cutimateapp/screens/trip_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import 'package:rxdart/rxdart.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  bool loadingUser = true;

  final Color bgLight = const Color(0xFFFCFCFC); // Matches Explore
  final Color accentYellow = const Color(0xFFFFC107); // Matches Explore

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        name = doc['name'] ?? 'Traveler';
        email = doc['email'] ?? user.email!;
        loadingUser = false;
      });
    }
  }

  Stream<List<Trip>> _loadProfileTrips() {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email!;

    final ownedTrips = FirebaseFirestore.instance
        .collection('trips')
        .where('ownerUid', isEqualTo: user.uid)
        .snapshots();

    final invitedTrips = FirebaseFirestore.instance
        .collection('trips')
        .where('members', arrayContains: email)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<Trip>>(
      ownedTrips,
      invitedTrips,
      (a, b) {
        final docs = [...a.docs, ...b.docs];

        // remove duplicates
        final unique = {for (var d in docs) d.id: d}.values.toList();

        return unique
            .map((d) => Trip.fromJson(d.id, d.data() as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: StreamBuilder<List<Trip>>(
        stream: _loadProfileTrips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || loadingUser) {
            return Center(
              child: CircularProgressIndicator(color: accentYellow),
            );
          }

          final trips = snapshot.data!;
          final groupTripsCount = trips.where((t) => t.isGroup).length;
          final destinationsCount = trips
              .map((t) => t.destination)
              .toSet()
              .length;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _header(),
                // Overlap Stats
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _stats(
                    trips.length,
                    groupTripsCount,
                    destinationsCount,
                  ),
                ),

                const SizedBox(height: 10),
                _sectionTitle('Account'),
                _accountSection(),

                const SizedBox(height: 24),
                _sectionTitle('Settings'),
                _settingsSection(),

                const SizedBox(height: 40),

                // Version/Footer
                Text(
                  "Cutimate v1.0.0",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        60,
        20,
        50,
      ), // Extra bottom padding for stats overlap
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontFamily: 'Serif',
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // Balance
            ],
          ),
          const SizedBox(height: 32),

          // Profile Pic with Ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentYellow.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Colors.black45,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Serif',
              color: Color(0xFF1F2937),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ================= STATS =================
  Widget _stats(int trips, int groups, int destinations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7F50), // Coral Orange
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7F50).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(trips.toString(), 'Trips'),
            _divider(),
            _statItem(groups.toString(), 'Groups'),
            _divider(),
            _statItem(destinations.toString(), 'Places'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.white24);

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  // ================= SECTIONS =================
  Widget _accountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _tile(Icons.person_outline_rounded, 'Edit Profile', _editProfile),
          const SizedBox(height: 12),
          _tile(Icons.history_rounded, 'Trip History', _openTripHistory),
        ],
      ),
    );
  }

  Widget _settingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _tile(Icons.notifications_outlined, 'Notifications', () {}),
          const SizedBox(height: 12),
          _tile(Icons.logout_rounded, 'Sign Out', _signOut, danger: true),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 6,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: danger
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: danger ? Colors.red.shade400 : Colors.black87,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: danger ? Colors.red.shade400 : const Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // ================= ACTIONS =================
  void _openTripHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TripHistoryScreen()),
    );
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Update Profile',
              style: TextStyle(
                fontFamily: 'Serif',
                color: Color(0xFF1F2937),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Editable Name
            const Text(
              "Full Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Read-only Email
            const Text(
              "Email (cannot be changed)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: email),
              enabled: false,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade400,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow, // Use yellow
                foregroundColor: Colors.black87,
                elevation: 0,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'name': nameCtrl.text.trim()});

                setState(() => name = nameCtrl.text.trim());

                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
