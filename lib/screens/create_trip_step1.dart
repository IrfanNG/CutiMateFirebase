import 'package:flutter/material.dart';
import 'create_trip_step2.dart';

class CreateTripStep1 extends StatefulWidget {
  final String? presetDestination;

  const CreateTripStep1({
    super.key,
    this.presetDestination,
  });

  @override
  State<CreateTripStep1> createState() => _CreateTripStep1State();
}

class _CreateTripStep1State extends State<CreateTripStep1> {
  final TextEditingController destinationController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  // CutiMate Branding
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  void initState() {
    super.initState();
    if (widget.presetDestination != null) {
      destinationController.text = widget.presetDestination!;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plan New Trip',
          style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _progressBar(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where to?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your destination to start the adventure.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
                  _inputWrapper(
                    icon: Icons.location_on_rounded,
                    child: TextField(
                      controller: destinationController,
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Langkawi, Penang',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Dates',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkNavy),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _dateCard(
                          label: 'DEPARTURE',
                          value: startDate,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dateCard(
                          label: 'RETURN',
                          value: endDate,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
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

  // ================= UI COMPONENTS =================

  Widget _progressBar() {
  return Container(
    height: 4,
    width: double.infinity,
    color: Colors.grey.shade200,
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: 0.33, // 1/3 progress
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
  );
}

  Widget _inputWrapper({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _dateCard({required String label, required DateTime? value, required VoidCallback onTap}) {
    bool hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasValue ? primaryBlue : Colors.transparent, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: hasValue ? primaryBlue : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  hasValue ? '${value.day}/${value.month}' : 'Select',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasValue ? darkNavy : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ElevatedButton(
        onPressed: () {
          if (destinationController.text.isEmpty || startDate == null || endDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select your destination and dates')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTripStep2(
                destination: destinationController.text,
                startDate: startDate!,
                endDate: endDate!,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text(
          'Next Step',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}