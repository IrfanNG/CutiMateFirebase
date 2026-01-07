import 'package:flutter/material.dart';
import 'package:cutimateapp/screens/trip_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trip_service.dart';
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

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgLight = const Color(0xFFF6F7F9);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

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
      final unique = {
        for (var d in docs) d.id: d,
      }.values.toList();

      return unique
          .map((d) =>
              Trip.fromJson(d.id, d.data() as Map<String, dynamic>))
          .toList();
    },
  );
}

  // 🔐 ASK PASSWORD DIALOG
  Future<String?> _askPassword() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Password"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Enter your password",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
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
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final trips = snapshot.data!;
          final groupTripsCount = trips.where((t) => t.isGroup).length;
          final destinationsCount =
              trips.map((t) => t.destination).toSet().length;

          return SingleChildScrollView(
            child: Column(
              children: [
                _header(),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _stats(trips.length, groupTripsCount, destinationsCount),
                ),
                _sectionTitle('Account'),
                _accountSection(),
                const SizedBox(height: 20),
                _sectionTitle('Settings'),
                _settingsSection(),
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, darkNavy],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack,
              ),
              const Text(
                'My Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration:
                const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded,
                  size: 50, color: Color(0xFF1BA0E2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900),
          ),
          Text(
            email,
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10)),
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
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: darkNavy)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey.shade100);

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: darkNavy,
              letterSpacing: 0.5),
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
          _tile(Icons.auto_awesome_motion_rounded, 'Trip History', _openTripHistory),
        ],
      ),
    );
  }

  Widget _settingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _tile(Icons.notifications_none_rounded, 'Notifications', () {}),
          _tile(Icons.logout_rounded, 'Sign Out', _signOut, danger: true),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap,
      {bool danger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: danger ? Colors.red.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: danger ? Colors.red : primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: danger ? Colors.red : darkNavy,
            fontSize: 15,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey.shade300),
        onTap: onTap,
      ),
    );
  }

  // ================= ACTIONS =================
  void _openTripHistory() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 24),

          // Editable Name
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: "Full Name",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Read-only Email
          TextField(
            controller: TextEditingController(text: email),
            enabled: false,
            decoration: InputDecoration(
              labelText: "Email (cannot be changed)",
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BA0E2),
              foregroundColor: Colors.white,
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
                  .update({
                'name': nameCtrl.text.trim(),
              });

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

  Widget _buildEditField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
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
