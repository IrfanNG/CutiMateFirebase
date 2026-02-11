import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/destination_model.dart'; // Import Destination Model
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trip_service.dart';

/// =======================================================
/// CREATE TRIP – STEP 3 (FINAL REVIEW & CONFIRMATION)
/// User reviews trip details and enters budget.
/// This screen completes the trip creation process.
/// =======================================================
class CreateTripStep3 extends StatefulWidget {
  final Destination destination; // Destination chosen in Step 1
  final DateTime startDate; // Trip start date
  final DateTime endDate; // Trip end date
  final int travelers; // Number of travelers
  final String transport; // Chosen transport type
  final String accommodation; // Chosen accommodation type
  final List<String> activities; // Chosen activities list

  const CreateTripStep3({
    super.key,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.transport,
    required this.accommodation,
    required this.activities,
  });

  @override
  State<CreateTripStep3> createState() => _CreateTripStep3State();
}

class _CreateTripStep3State extends State<CreateTripStep3> {
  /// Input controller for user budget value
  final TextEditingController budgetController = TextEditingController();

  /// =======================================================
  /// MAIN BUILD UI
  /// =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        /// Back button to previous screen
        leading: const BackButton(color: Colors.black87),

        title: const Text(
          'Final Review',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      /// ================= PAGE BODY =================
      body: Column(
        children: [
          /// Progress bar fully completed (Step 3 of 3)
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Container(color: const Color(0xFFFF7F50)),
          ),

          /// Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Page title
                  const Text(
                    'Review your trip',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// Page subtitle
                  Text(
                    'Almost there! Check your details before we create your itinerary.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  /// Summary trip info card
                  _summaryCard(),

                  const SizedBox(height: 32),

                  /// Budget section title
                  const Text(
                    'Estimated Budget (RM)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Budget input field
                  _budgetInput(),
                ],
              ),
            ),
          ),
        ],
      ),

      /// Bottom confirmation button
      bottomNavigationBar: _bottomCTA(),
    );
  }

  // ===================================================================
  // ===================== STYLIZED UI COMPONENTS ======================
  // ===================================================================

  /// =======================================================
  /// TRIP SUMMARY CARD
  /// Displays all selected trip information
  /// =======================================================
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),

      /// Content Rows
      child: Column(
        children: [
          _row(
            Icons.location_on_outlined,
            'Destination',
            widget.destination.name,
          ),
          _divider(),

          _row(
            Icons.calendar_month_outlined,
            'Dates',
            '${widget.startDate.day}/${widget.startDate.month} - ${widget.endDate.day}/${widget.endDate.month}',
          ),
          _divider(),

          _row(
            Icons.people_outline,
            'Group Size',
            '${widget.travelers} Travelers',
          ),
          _divider(),

          _row(Icons.directions_bus_outlined, 'Transport', widget.transport),
          _divider(),

          _row(Icons.hotel_outlined, 'Accommodation', widget.accommodation),
          _divider(),

          _row(
            Icons.local_activity_outlined,
            'Activities',
            widget.activities.isEmpty
                ? 'General Exploring'
                : widget.activities.join(', '),
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// BUDGET INPUT FIELD UI
  /// =======================================================
  Widget _budgetInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          /// Static RM label
          const Text(
            'RM',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black45,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),

          /// Budget numeric input field
          Expanded(
            child: TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 2500',
                hintStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================================================
  /// STANDARD ROW LAYOUT
  /// Used across summary card items
  /// =======================================================
  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 12),

          /// Label text
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),

          /// Value text
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Divider between summary rows
  Widget _divider() => Divider(height: 24, color: Colors.grey.shade100);

  /// =======================================================
  /// BOTTOM CONFIRM BUTTON
  /// Triggers trip creation process
  /// =======================================================
  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ElevatedButton(
        onPressed: _createTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7F50),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Confirm & Create Trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // ============================ LOGIC ================================
  // ===================================================================

  /// =======================================================
  /// CREATE TRIP FUNCTION
  /// 1. Validates budget input
  /// 2. Builds Trip model
  /// 3. Saves trip to Firestore using TripService
  /// 4. Redirects user back to Home Screen
  /// =======================================================
  Future<void> _createTrip() async {
    /// Budget validation
    if (budgetController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your budget')));
      return;
    }

    /// Get logged-in Firebase user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    /// Check if trip is group trip or solo
    final bool isGroupTrip = widget.travelers > 1;

    final trip = Trip(
      id: '',
      ownerUid: user.uid,
      title: widget.destination.name,
      destination: widget.destination.name,
      startDate: widget.startDate,
      endDate: widget.endDate,
      travelers: widget.travelers,
      transport: widget.transport,
      accommodation: widget.accommodation,
      budget: double.tryParse(budgetController.text) ?? 0,
      imageUrl: widget.destination.image, // Use destination image
      activities: widget.activities,

      /// Empty lists initially
      itinerary: [],
      expenses: [],
      tasks: [],
      checklist: [],
      messages: [],

      /// Group-related settings
      isGroup: isGroupTrip,
      groupName: isGroupTrip ? "${widget.destination.name} Trip Group" : '',
      members: [user.email ?? 'Unknown'],
    );

    /// Save trip to Firestore
    await TripService.saveTrip(trip);

    if (!mounted) {
      return;
    }

    /// Navigate user back to Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
