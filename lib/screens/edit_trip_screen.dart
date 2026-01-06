import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final formKey = GlobalKey<FormState>();

  // Theme Colors - Same as Detail Screen
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgGray = const Color(0xFFF6F7F9);

  late TextEditingController title;
  late TextEditingController destination;
  late TextEditingController travelers;
  late TextEditingController transport;
  late TextEditingController accommodation;
  late TextEditingController budget;

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.trip.title);
    destination = TextEditingController(text: widget.trip.destination);
    travelers = TextEditingController(text: widget.trip.travelers.toString());
    transport = TextEditingController(text: widget.trip.transport);
    accommodation = TextEditingController(text: widget.trip.accommodation);
    budget = TextEditingController(text: widget.trip.budget.toString());
    startDate = widget.trip.startDate;
    endDate = widget.trip.endDate;
  }

  Future<void> updateTrip() async {
    if (!formKey.currentState!.validate()) return;

    final updatedTrip = widget.trip.copyWith(
      title: title.text,
      destination: destination.text,
      travelers: int.parse(travelers.text),
      transport: transport.text,
      accommodation: accommodation.text,
      budget: double.parse(budget.text),
      startDate: startDate,
      endDate: endDate,
    );

    // Show loading overlay
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    await FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.trip.id)
        .update(updatedTrip.toJson());

    if (mounted) {
      Navigator.pop(context); // Pop loading
      Navigator.pop(context, updatedTrip); // Return to detail
    }
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryBlue, onPrimary: Colors.white, onSurface: darkNavy),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked;
        else endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        title: const Text("Edit Trip Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _sectionLabel("GENERAL INFORMATION"),
            _buildTextField(title, "Trip Title", Icons.edit_note_rounded),
            _buildTextField(destination, "Destination", Icons.place_rounded),
            
            const SizedBox(height: 24),
            _sectionLabel("DATE & DURATION"),
            Row(
              children: [
                Expanded(child: _dateTile("Start Date", startDate, () => pickDate(true))),
                const SizedBox(width: 12),
                Expanded(child: _dateTile("End Date", endDate, () => pickDate(false))),
              ],
            ),

            const SizedBox(height: 24),
            _sectionLabel("PLANNING DETAILS"),
            Row(
              children: [
                Expanded(child: _buildTextField(travelers, "Travelers", Icons.people_outline, isNum: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(budget, "Budget (RM)", Icons.payments_outlined, isNum: true)),
              ],
            ),
            _buildTextField(transport, "Transport Mode", Icons.local_taxi_rounded),
            _buildTextField(accommodation, "Accommodation", Icons.hotel_rounded),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: updateTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: darkNavy.withOpacity(0.4),
              ),
              child: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNum = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: primaryBlue),
                const SizedBox(width: 8),
                Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}