import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import 'create_trip_step1.dart';

/// ===============================================================
/// DESTINATION DETAIL SCREEN
/// ---------------------------------------------------------------
/// This screen displays full detailed information about a selected
/// travel destination such as overview, activities, attractions,
/// best travel time, cost, and highlights.
///
/// User can also directly start planning a trip from this page.
/// ===============================================================
class DestinationDetailScreen extends StatefulWidget {
  final Destination destination; // Selected destination object

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  /// Controls which tab is currently selected
  int selectedTab = 0;

  /// Tab menu labels
  final List<String> tabs = ['Overview', 'Attractions', 'Activities', 'Tips'];

  /// ===============================================================
  /// MAIN PAGE STRUCTURE
  /// ===============================================================
  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      /// Entire page UI uses Stack to allow floating bottom button
      body: Stack(
        children: [
          /// Main scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                const SizedBox(height: 24),
                _tabs(),
                const SizedBox(height: 12),
                _tabContent(),
                const SizedBox(height: 120), // Space to avoid FAB overlapping
              ],
            ),
          ),

          /// Fixed persistent bottom button
          _persistentBottomAction(destination),
        ],
      ),
    );
  }

  // ====================================================================
  // ===================== HEADER (IMAGE + TITLE) =======================
  // ====================================================================

  /// Large immersive header with:
  /// - Destination photo
  /// - Gradient overlay
  /// - Back button
  /// - Destination name and state label
  // ====================================================================
  // ===================== HEADER (IMAGE + TITLE) =======================
  // ====================================================================

  /// Large immersive header with:
  /// - Destination photo
  /// - Gradient overlay
  /// - Back button
  /// - Destination name and state label
  Widget _header(BuildContext context) {
    final destination = widget.destination;

    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// Destination background image
          destination.image.startsWith('http')
              ? Image.network(
                  destination.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              : Image.asset(destination.image, fit: BoxFit.cover),

          /// Dark to transparent gradient to improve text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          /// Back button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white, // Minimal white circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),

          /// Bottom title + state label
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// State tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    destination.state.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// Destination Name
                Text(
                  destination.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // ============================= TABS =================================
  // ====================================================================

  /// Horizontal tab selector UI
  // ====================================================================
  // ============================= TABS =================================
  // ====================================================================

  /// Horizontal tab selector UI - Simple Line Tabs
  Widget _tabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final active = selectedTab == index;

          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: active
                    ? Border(
                        bottom: BorderSide(
                          color: const Color(0xFFFF7F50),
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: active
                        ? const Color(0xFFFF7F50)
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ====================================================================
  // ======================= TAB CONTENT AREA ===========================
  // ====================================================================

  Widget _tabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getContentBody(),
      ),
    );
  }

  /// Switches UI display content according to selected tab
  Widget _getContentBody() {
    final d = widget.destination;

    switch (selectedTab) {
      case 0:
        return _overview();
      case 1:
        return _simpleList(
          d.attractions.isNotEmpty
              ? d.attractions
              : [
                  'Explore the surroundings',
                  'Local landmarks',
                  'Photo opportunities',
                ],
        );
      case 2:
        return _simpleList(
          d.activities.isNotEmpty
              ? d.activities
              : ['Sightseeing', 'Relaxing', 'Walking'],
        );
      case 3:
        return _simpleList(
          d.tips.isNotEmpty
              ? d.tips
              : [
                  'Check opening hours',
                  'Wear comfortable shoes',
                  'Stay hydrated',
                ],
        );
      default:
        return const SizedBox();
    }
  }

  // ====================================================================
  // ============================ OVERVIEW ==============================
  // ====================================================================

  /// Displays details such as:
  /// - Best travel time
  /// - Average cost
  /// - Duration recommendation
  /// - About description
  /// - Highlights list
  Widget _overview() {
    final d = widget.destination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        /// Row of 3 information cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoCard(Icons.wb_sunny_rounded, 'Best Time', d.bestTime),
            _infoCard(Icons.payments_rounded, 'Avg Cost', d.avgCost),
            _infoCard(Icons.timer_rounded, 'Duration', d.duration),
            _infoCard(Icons.timer_rounded, 'Duration', d.duration),
          ],
        ),

        const SizedBox(height: 24),

        // WARNING BANNER: If this is an API result (non-curated)
        if (d.isCurated != true) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Limited Information",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This destination was found via search. Suitability for children, elderly, or terrain details are not verified.",
                        style: TextStyle(
                          color: Colors.orange.shade900.withOpacity(0.8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),

        _sectionTitle('About'),
        const SizedBox(height: 8),

        /// About description paragraph
        Text(
          d.about,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.6,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 32),

        _sectionTitle('Highlights'),
        const SizedBox(height: 12),

        /// Highlight bullet list
        ...d.highlights.map((item) => _checkItem(item)),
      ],
    );
  }

  // ====================================================================
  // ===================== REUSABLE UI COMPONENTS =======================
  // ====================================================================

  /// Small info card showing time / cost / duration
  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) / 3,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  /// Bullet list item with check icon
  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFFFF7F50), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Used for Attractions / Activities / Tips tab
  Widget _simpleList(List<String> items) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ...items.map((item) => _checkItem(item)),
      ],
    );
  }

  // ====================================================================
  // ======================= PLAN TRIP BUTTON ===========================
  // ====================================================================

  /// Sticky bottom button that allows user to
  /// immediately start planning a trip to this destination
  Widget _persistentBottomAction(Destination destination) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,

      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),

        /// Button → navigates to CreateTrip Step 1
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7F50),
            minimumSize: const Size.fromHeight(56),
            shadowColor: const Color(0xFFFF7F50).withOpacity(0.5),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreateTripStep1(presetDestinationObj: widget.destination),
              ),
            );
          },
          child: Text(
            'Plan Trip to ${destination.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
