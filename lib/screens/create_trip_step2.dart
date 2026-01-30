import 'package:flutter/material.dart';
import 'create_trip_step3.dart';

import '../data/destination_data.dart';

/// =======================================================
/// CREATE TRIP – STEP 2
/// User sets: Travelers profile, Transport mode, Activities
/// Includes Smart Recommendations based on group composition.
/// =======================================================
class CreateTripStep2 extends StatefulWidget {
  final String destination; // Destination chosen in Step 1
  final DateTime startDate; // Start date from Step 1
  final DateTime endDate; // End date from Step 1

  const CreateTripStep2({
    super.key,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CreateTripStep2> createState() => _CreateTripStep2State();
}

class _CreateTripStep2State extends State<CreateTripStep2> {
  /// Travelers Profile
  int adults = 1;
  int children = 0;
  int elderly = 0;
  bool hasStroller = false;
  bool hasMobilityIssues = false;

  /// Computed total travelers
  int get totalTravelers => adults + children + elderly;

  /// Selected transport type
  String selectedTransport = '';

  /// Selected accommodation type
  String selectedAccommodation = '';

  /// Stores selected activities (multiple selection allowed)
  final Set<String> selectedActivities = {};

  /// Available transport types
  final List<String> transports = ['Flight', 'Car', 'Train', 'Ferry'];

  /// Available accommodation types
  final List<String> accommodations = [
    'Hotel',
    'Airbnb',
    'Resort',
    'Hostel',
    'Homestay',
  ];

  /// Available activity categories
  final List<String> activities = [
    'Beach',
    'Hiking',
    'Food',
    'Shopping',
    'Culture',
    'Adventure',
  ];

  /// =======================================================
  /// MAIN UI BUILD
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

        /// Back button to return to Step 1
        leading: const BackButton(color: Colors.black87),

        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),

      /// ================= PAGE CONTENT =================
      body: Column(
        children: [
          /// Progress bar (Step 2 of 3)
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.66, // 66% progress indicator
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7F50),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          /// Scrollable Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ---------------- RECOMMENDATION / WARNING CARD ----------------
                  _recommendationSection(),
                  const SizedBox(height: 24),

                  /// ---------------- TRAVELER PROFILE ----------------
                  const Text(
                    'Who is going?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _profileCard(
                    child: Column(
                      children: [
                        _counterRow(
                          "Adults",
                          "Age 13-59",
                          adults,
                          (v) => setState(() => adults = v),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.grey.shade100),
                        ),
                        _counterRow(
                          "Children",
                          "Age 0-12",
                          children,
                          (v) => setState(() => children = v),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.grey.shade100),
                        ),
                        _counterRow(
                          "Elderly",
                          "Age 60+",
                          elderly,
                          (v) => setState(() => elderly = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Extra Toggles
                  Row(
                    children: [
                      Expanded(
                        child: _toggleCard(
                          "Baby Stroller",
                          Icons.child_friendly_rounded,
                          hasStroller,
                          (v) => setState(() => hasStroller = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _toggleCard(
                          "Mobility Aid",
                          Icons.accessible_rounded,
                          hasMobilityIssues,
                          (v) => setState(() => hasMobilityIssues = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// ---------------- TRANSPORT SECTION ----------------
                  const Text(
                    'How will you travel?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Select ONE transport option
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: transports.map((t) {
                      final bool selected = selectedTransport == t;
                      return _chip(t, selected, () {
                        setState(() => selectedTransport = t);
                      });
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  /// ---------------- ACCOMMODATION SECTION ----------------
                  const Text(
                    'Where will you stay?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Select ONE accommodation option
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: accommodations.map((t) {
                      final bool selected = selectedAccommodation == t;
                      return _chip(t, selected, () {
                        setState(() => selectedAccommodation = t);
                      });
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  /// ---------------- ACTIVITIES SECTION ----------------
                  const Text(
                    'What do you want to do?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Multi-select activity chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: activities.map((a) {
                      final bool selected = selectedActivities.contains(a);
                      return _chip(a, selected, () {
                        setState(() {
                          /// Toggle selection
                          selected
                              ? selectedActivities.remove(a)
                              : selectedActivities.add(a);
                        });
                      });
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// Bottom next button
      bottomNavigationBar: _bottomCTA(),
    );
  }

  // ======================================================
  // UI COMPONENTS
  // ======================================================

  /// =======================================================
  /// BOTTOM CONTINUE BUTTON
  /// Validates input & navigates to Step 3
  /// =======================================================
  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (totalTravelers < 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('At least 1 traveler is required'),
                ),
              );
              return;
            }

            /// Ensure transport is selected
            if (selectedTransport.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select transport')),
              );
              return;
            }

            /// Ensure accommodation is selected
            if (selectedAccommodation.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select accommodation')),
              );
              return;
            }

            /// Move to Step 3 with collected data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTripStep3(
                  destination: widget.destination,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  travelers: totalTravelers,
                  transport: selectedTransport,
                  accommodation: selectedAccommodation,
                  activities: selectedActivities.toList(),
                ),
              ),
            );
          },

          /// Button Style
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7F50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          child: const Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// =======================================================
  /// RECOMMENDATION LOGIC & UI
  /// =======================================================
  List<String> _getWarnings() {
    List<String> warnings = [];

    // Find destination metadata
    // In a real app, this might be an ID lookup. Here we match by name.
    final dest = allDestinations.firstWhere(
      (d) => d.name.toLowerCase() == widget.destination.toLowerCase(),
      orElse: () => allDestinations.first, // Fallback if custom destination
    );

    // Rule 1: Elderly & Physical Demand
    if (elderly > 0 && dest.physicalDemand == 'High') {
      warnings.add(
        "⚠️ This destination involves high physical exertion which may be difficult for elderly travelers.",
      );
    }

    // Rule 2: Children & Child Friendliness
    if (children > 0 && !dest.childFriendly) {
      warnings.add(
        "⚠️ This destination is not flagged as child-friendly. Some activities might be unsuitable.",
      );
    }

    // Rule 3: Elderly & Elder Friendliness
    if (elderly > 0 && !dest.elderFriendly) {
      warnings.add(
        "⚠️ Facilities for elderly travelers might be limited here.",
      );
    }

    // Rule 4: Mobility & Terrain
    if (hasMobilityIssues && dest.terrainType != 'Flat') {
      warnings.add(
        "⚠️ The terrain is ${dest.terrainType}, which may act as a barrier for mobility aids.",
      );
    }

    // Rule 5: Stroller & Terrain
    if (hasStroller && dest.terrainType == 'Steep') {
      warnings.add("⚠️ Steep terrain may make using a stroller challenging.");
    }

    // Rule 6: Activity-Level Warnings (Dynamic)
    if (selectedActivities.contains('Hiking') &&
        (elderly > 0 || hasMobilityIssues)) {
      warnings.add(
        "⚠️ 'Hiking' may be strenuous for elderly members or those with mobility concerns.",
      );
    }

    if (selectedActivities.contains('Adventure') &&
        (children > 0 || hasMobilityIssues)) {
      warnings.add(
        "⚠️ 'Adventure' activities might not be suitable for young children or mobility restricted travelers.",
      );
    }

    return warnings;
  }

  Widget _recommendationSection() {
    final warnings = _getWarnings();

    if (warnings.isEmpty) {
      // Positive Reinforcement
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Great choice! ${widget.destination} is suitable for your group.",
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show Warnings
    return Column(
      children: warnings
          .map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// =======================================================
  /// PROFILE WIDGETS
  /// =======================================================
  Widget _profileCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _counterRow(
    String label,
    String sub,
    int value,
    Function(int) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                sub,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        _counterButton(Icons.remove, () {
          if (value > 0) onChanged(value - 1);
        }),
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        _counterButton(Icons.add, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }

  Widget _toggleCard(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFF7F50) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? const Color(0xFFFF7F50) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: value ? Colors.white : Colors.black54, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// =======================================================
  /// SELECTABLE CHIP (Used for Transport + Activities)
  /// Supports both single-select & multi-select behaviors
  /// =======================================================
  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7F50) : Colors.white,
          borderRadius: BorderRadius.circular(16),

          /// Border changes based on selection
          border: Border.all(
            color: selected ? const Color(0xFFFF7F50) : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7F50).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),

        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
