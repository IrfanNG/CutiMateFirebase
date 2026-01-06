import 'package:flutter/material.dart';
import 'create_trip_step3.dart';

class CreateTripStep2 extends StatefulWidget {
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

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
  int travelers = 1;
  String selectedTransport = '';
  final Set<String> selectedActivities = {};

  final List<String> transports = ['Flight', 'Car', 'Train', 'Ferry'];
  final List<String> activities = [
    'Beach',
    'Hiking',
    'Food',
    'Shopping',
    'Culture',
    'Adventure'
  ];

  // UI Palette
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
          'Trip Details',
          style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // ✅ FIXED: Progress Stepper for 3-step flow (Step 2 of 3)
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.66, // 66% progress for Step 2
              child: Container(
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How many travelers?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B4E6B)),
                  ),
                  const SizedBox(height: 16),

                  _card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _counterButton(Icons.remove, () {
                          if (travelers > 1) setState(() => travelers--);
                        }),
                        Text(
                          travelers.toString(),
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900, color: darkNavy),
                        ),
                        _counterButton(Icons.add, () {
                          setState(() => travelers++);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'How will you travel?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B4E6B)),
                  ),
                  const SizedBox(height: 16),

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

                  const Text(
                    'What do you want to do?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B4E6B)),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: activities.map((a) {
                      final bool selected = selectedActivities.contains(a);
                      return _chip(a, selected, () {
                        setState(() {
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
      bottomNavigationBar: _bottomCTA(),
    );
  }

  // ================= STYLIZED COMPONENTS =================

  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (selectedTransport.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select transport')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTripStep3(
                  destination: widget.destination,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  travelers: travelers,
                  transport: selectedTransport,
                  activities: selectedActivities.toList(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Continue',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? primaryBlue : Colors.grey.shade300),
          boxShadow: selected ? [
            BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : darkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}