import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../services/destination_service.dart';

/// ===============================================================
/// EDIT TRIP SCREEN (REDESIGNED)
/// ---------------------------------------------------------------
/// This screen allows the user to edit an existing trip.
/// Updated to match the Coral Orange modern theme.
/// ===============================================================
class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final formKey = GlobalKey<FormState>();

  // Theme Colors
  final Color primaryCoral = const Color(0xFFFF7F50);
  final Color bgLight = const Color(0xFFF6F7F9);
  final Color darkNavy = const Color(0xFF111827);

  // Controllers
  late TextEditingController title;
  late TextEditingController destination;
  late TextEditingController travelers;
  late TextEditingController transport;
  late TextEditingController accommodation;
  late TextEditingController budget;

  // Usage Variables
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

  // ... (inside _EditTripScreenState)

  // UPDATE LOGIC
  Future<void> updateTrip() async {
    if (!formKey.currentState!.validate()) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7F50)),
        ),
      ),
    );

    String? newImageUrl = widget.trip.imageUrl;

    // Cascading Update: If destination changed, fetch new image
    if (destination.text.trim().toLowerCase() !=
        widget.trip.destination.trim().toLowerCase()) {
      try {
        final results = await DestinationService.searchDestinations(
          destination.text.trim(),
        );
        if (results.isNotEmpty) {
          newImageUrl = results.first.image;
        }
      } catch (e) {
        debugPrint("Error fetching new image: $e");
      }
    }

    final updatedTrip = widget.trip.copyWith(
      title: title.text,
      destination: destination.text,
      travelers: int.parse(travelers.text),
      transport: transport.text,
      accommodation: accommodation.text,
      budget: double.parse(budget.text),
      startDate: startDate,
      endDate: endDate,
      imageUrl: newImageUrl,
    );

    await FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.trip.id)
        .update(updatedTrip.toJson());

    if (mounted) {
      Navigator.pop(context); // Close loading
      Navigator.pop(context, updatedTrip); // Return updated trip
    }
  }

  // DATE PICKER
  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryCoral, // Coral Calendar Head
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

  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          // 1. Custom Header
          _buildCustomHeader(),

          // 2. Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GENERAL
                    _sectionLabel("GENERAL INFORMATION"),
                    _buildTextField(
                      title,
                      "Trip Title",
                      Icons.edit_note_rounded,
                    ),
                    _buildTextField(
                      destination,
                      "Destination",
                      Icons.place_rounded,
                    ),
                    const SizedBox(height: 24),

                    // DATES
                    _sectionLabel("DATE & DURATION"),
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                            "Start Date",
                            startDate,
                            () => pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateTile(
                            "End Date",
                            endDate,
                            () => pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PLANNING
                    _sectionLabel("PLANNING DETAILS"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            travelers,
                            "Travelers",
                            Icons.people_outline,
                            isNum: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            budget,
                            "Budget (RM)",
                            Icons.payments_outlined,
                            isNum: true,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      transport,
                      "Transport Mode",
                      Icons.local_taxi_rounded,
                    ),
                    _buildTextField(
                      accommodation,
                      "Accommodation",
                      Icons.hotel_rounded,
                    ),
                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCoral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 8,
                          shadowColor: primaryCoral.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CUSTOM HEADER =================
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          Text(
            'Edit Trip',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkNavy,
            ),
          ),
          const SizedBox(width: 44), // Spacer for centering
        ],
      ),
    );
  }

  // ================= WIDGETS =================
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontWeight: FontWeight.w600, color: darkNavy),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryCoral, size: 22), // Coral icons
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: primaryCoral,
                ),
                const SizedBox(width: 8),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
