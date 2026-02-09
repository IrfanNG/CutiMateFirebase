import 'package:flutter/material.dart';
import 'create_trip_step2.dart';
import '../models/destination_model.dart';
import '../data/destination_data.dart';
import '../services/destination_service.dart';

/// =======================================================
/// CREATE TRIP – STEP 1
/// User selects destination + travel dates (API Powered)
/// This is the first step in the trip creation wizard.
/// =======================================================
class CreateTripStep1 extends StatefulWidget {
  final String?
  presetDestination; // Optional preset destination (e.g. clicked from Explore)
  final Destination? presetDestinationObj; // Optional full object

  const CreateTripStep1({
    super.key,
    this.presetDestination,
    this.presetDestinationObj,
  });

  @override
  State<CreateTripStep1> createState() => _CreateTripStep1State();
}

class _CreateTripStep1State extends State<CreateTripStep1> {
  /// Controller for destination text input
  final TextEditingController destinationController = TextEditingController();

  /// Selected destination object
  Destination? _selectedDestination;

  /// Selected trip start + end dates
  DateTime? startDate;
  DateTime? endDate;

  /// =======================================================
  /// INIT STATE
  /// If trip was created from Explore Page,
  /// we auto-fill the destination text field.
  /// =======================================================
  @override
  void initState() {
    super.initState();

    // Priority 1: Full Object passed (e.g. from DestinationDetailScreen)
    if (widget.presetDestinationObj != null) {
      _selectedDestination = widget.presetDestinationObj;
      destinationController.text = widget.presetDestinationObj!.name;
    }
    // Priority 2: String passed (legacy/fallback)
    else if (widget.presetDestination != null) {
      destinationController.text = widget.presetDestination!;
      // Attempt to find the preset destination object in local data
      try {
        _selectedDestination = allDestinations.firstWhere(
          (d) => d.name == widget.presetDestination,
        );
      } catch (_) {
        // Preset string doesn't match any known destination
      }
    }
  }

  /// =======================================================
  /// DATE PICKER
  /// Reusable function to pick either start date or end date
  /// =======================================================
  Future<void> _pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),

      /// Custom themed date picker to match branding
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7F50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    /// If user selected a date → update UI
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

  /// =======================================================
  /// MAIN UI BUILD
  /// =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          'Plan New Trip',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      /// ================= PAGE BODY =================
      body: Column(
        children: [
          /// Step progress bar (Step 1 of 3)
          _progressBar(),

          /// Scrollable form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -------- DESTINATION TITLE --------
                  const Text(
                    'Where to?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your destination to start the adventure.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  /// Destination Input Field (Autocomplete)
                  _inputWrapper(
                    icon: Icons.location_on_rounded,
                    child: Autocomplete<Destination>(
                      initialValue: TextEditingValue(
                        text: destinationController.text,
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        final query = textEditingValue.text;
                        if (query.isEmpty) {
                          return const Iterable<Destination>.empty();
                        }

                        // 1. Local Search (Instant)
                        final localMatches = allDestinations.where((
                          Destination option,
                        ) {
                          return option.name.toLowerCase().contains(
                                query.toLowerCase(),
                              ) ||
                              option.state.toLowerCase().contains(
                                query.toLowerCase(),
                              );
                        }).toList();

                        // 2. API Search (Network) - Only if length > 2
                        if (query.length > 2) {
                          try {
                            // Simple debounce by waiting? No, standard Future.delayed might be enough for a demo
                            // or imply user stopped typing.
                            // For simplicity in this demo, we await directly but the UI handles async.
                            final apiMatches =
                                await DestinationService.searchDestinations(
                                  query,
                                );

                            // Merge without duplicates (by name)
                            // We prefer local matches because they have curated photos
                            for (var apiDest in apiMatches) {
                              // Check if already in localMatches
                              if (!localMatches.any(
                                (l) => l.name == apiDest.name,
                              )) {
                                localMatches.add(apiDest);
                              }
                            }
                          } catch (e) {
                            debugPrint("Search Error: $e");
                          }
                        }

                        return localMatches;
                      },
                      displayStringForOption: (Destination option) =>
                          option.name,
                      onSelected: (Destination selection) {
                        setState(() {
                          _selectedDestination = selection;
                          destinationController.text = selection.name;
                        });
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Sync with our main controller if user types manually
                            /// Note: We need to keep `destinationController` in sync.
                            /// However, `Autocomplete` has its own controller.
                            /// We'll listen to it.
                            textEditingController.addListener(() {
                              destinationController.text =
                                  textEditingController.text;
                            });

                            // If we have an initial value (e.g. from Explore), set it
                            if (destinationController.text.isNotEmpty &&
                                textEditingController.text.isEmpty) {
                              textEditingController.text =
                                  destinationController.text;
                            }

                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Langkawi, Penang',
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width -
                                  90, // Adjust width
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Destination option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        option.image,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ), // In real app use NetworkImage
                                    title: Text(
                                      option.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      option.state,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// -------- DATE SECTION --------
                  const Text(
                    'Dates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Start Date & End Date side-by-side
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

      /// Bottom NEXT button
      bottomNavigationBar: _bottomCTA(),
    );
  }

  // ======================================================
  // UI COMPONENTS
  // ======================================================

  /// ---------------- STEP PROGRESS BAR ----------------
  Widget _progressBar() {
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.33, // Shows 1/3 progress (Step 1 of 3)
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF7F50), // Coral Orange
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- INPUT WRAPPER STYLING ----------------
  /// Reusable styled container for text fields
  Widget _inputWrapper({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF7F50), size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// ---------------- DATE SELECTOR CARD ----------------
  Widget _dateCard({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    bool hasValue = value != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFFF7F50) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? const Color(0xFFFF7F50) : Colors.grey.shade300,
          ),
          boxShadow: hasValue
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7F50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Label text
            Text(
              label,
              style: TextStyle(
                color: hasValue ? Colors.white.withOpacity(0.9) : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            /// Icon + Date Display
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: hasValue ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  hasValue ? '${value.day}/${value.month}' : 'Select',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasValue ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- BOTTOM NEXT BUTTON ----------------
  Widget _bottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),

      child: ElevatedButton(
        /// Validate Inputs Before Moving to Step 2
        onPressed: () async {
          if (destinationController.text.isEmpty ||
              startDate == null ||
              endDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select your destination and dates'),
              ),
            );
            return;
          }

          Destination? finalDest = _selectedDestination;

          // If no destination selected from list (manual entry), try to fetch it
          if (finalDest == null) {
            // Show simple loading feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verifying destination...')),
            );

            try {
              final results = await DestinationService.searchDestinations(
                destinationController.text.trim(),
              );
              if (results.isNotEmpty) {
                finalDest = results.first;
              }
            } catch (e) {
              debugPrint("Error fetching manual destination: $e");
            }
          }

          // Fallback if still null
          finalDest ??= Destination(
            name: destinationController.text,
            state: 'Unknown',
            category: 'Custom',
            image: 'assets/penang.jpg', // Fallback
            rating: 0.0,
            bestTime: '',
            avgCost: '',
            duration: '',
            about: '',
            highlights: [],
            childFriendly: true,
            elderFriendly: true,
            physicalDemand: 'Low',
            terrainType: 'Flat',
          );

          /// Move to Step 2, passing collected data
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTripStep2(
                  destination: finalDest!,
                  startDate: startDate!,
                  endDate: endDate!,
                ),
              ),
            );
          }
        },

        /// Button style
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7F50),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: const Color(0xFFFF7F50).withOpacity(0.4),
        ),

        /// Button text
        child: const Text(
          'Next Step',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
