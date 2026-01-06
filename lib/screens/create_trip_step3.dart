import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trip_service.dart';

class CreateTripStep3 extends StatefulWidget {
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final String transport;
  final List<String> activities;

  const CreateTripStep3({
    super.key,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.transport,
    required this.activities,
  });

  @override
  State<CreateTripStep3> createState() => _CreateTripStep3State();
}

class _CreateTripStep3State extends State<CreateTripStep3> {
  final TextEditingController budgetController = TextEditingController();

  // CutiMate Branding
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Color(0xFF1B4E6B)),
        title: Text(
          'Final Review',
          style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Final Stepper State (Completion)
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Container(color: primaryBlue), // 100% Filled
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review your trip',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Almost there! Check your details before we create your itinerary.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  _summaryCard(),

                  const SizedBox(height: 32),

                  Text(
                    'Estimated Budget (RM)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkNavy),
                  ),
                  const SizedBox(height: 16),

                  _budgetInput(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomCTA(),
    );
  }

  // ================= STYLIZED COMPONENTS =================

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _row(Icons.location_on_rounded, 'Destination', widget.destination),
          _divider(),
          _row(Icons.calendar_month_rounded, 'Dates', 
            '${widget.startDate.day}/${widget.startDate.month} - ${widget.endDate.day}/${widget.endDate.month}'),
          _divider(),
          _row(Icons.people_alt_rounded, 'Group Size', '${widget.travelers} Travelers'),
          _divider(),
          _row(Icons.directions_bus_rounded, 'Transport', widget.transport),
          _divider(),
          _row(Icons.local_activity_rounded, 'Activities', 
            widget.activities.isEmpty ? 'General Exploring' : widget.activities.join(', ')),
        ],
      ),
    );
  }

  Widget _budgetInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Text('RM', style: TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkNavy),
              decoration: const InputDecoration(
                hintText: 'e.g. 2500',
                hintStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 24, color: Colors.grey.shade100);

  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ElevatedButton(
        onPressed: _createTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text(
          'Confirm & Create Trip',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================= LOGIC (UNCHANGED) =================
  Future<void> _createTrip() async {
    if (budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your budget')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bool isGroupTrip = widget.travelers > 1;

    final trip = Trip(
      id: '',
      ownerUid: user.uid,
      title: widget.destination,
      destination: widget.destination,
      startDate: widget.startDate,
      endDate: widget.endDate,
      travelers: widget.travelers,
      transport: widget.transport,
      accommodation: '',
      budget: double.tryParse(budgetController.text) ?? 0,
      activities: widget.activities,
      itinerary: [],
      expenses: [],
      tasks: [],
      checklist: [],
      messages: [],
      isGroup: isGroupTrip,
      groupName: isGroupTrip ? "${widget.destination} Trip Group" : '',
      members: [user.email ?? 'Unknown'],
    );

    await TripService.saveTrip(trip);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}