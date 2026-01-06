import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import 'create_trip_step1.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int selectedTab = 0;

  final List<String> tabs = [
    'Overview',
    'Attractions',
    'Activities',
    'Tips',
  ];

  // Branding Palette
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                const SizedBox(height: 24),
                _tabs(),
                const SizedBox(height: 12),
                _tabContent(),
                const SizedBox(height: 120), // Space for bottom button
              ],
            ),
          ),
          _persistentBottomAction(destination),
        ],
      ),
    );
  }

  // ================= HEADER (IMMERSIVE) =================
  Widget _header(BuildContext context) {
    final destination = widget.destination;

    return Container(
      height: 380,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              destination.image,
              fit: BoxFit.cover,
            ),
            // Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: _circularIconButton(Icons.arrow_back, () => Navigator.pop(context)),
            ),
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      destination.state.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destination.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TABS (FLOATING DESIGN) =================
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: active ? darkNavy : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: active
                    ? [BoxShadow(color: darkNavy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= TAB CONTENT =================
  Widget _tabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getContentBody(),
      ),
    );
  }

  Widget _getContentBody() {
    switch (selectedTab) {
      case 0: return _overview();
      case 1: return _simpleList(['Pantai Cenang', 'Langkawi Cable Car', 'Kilim Geoforest Park', 'Eagle Square']);
      case 2: return _simpleList(['Island hopping', 'Snorkeling', 'Jet ski', 'Mangrove tour']);
      case 3: return _simpleList(['Best visited outside monsoon', 'Rent a car or scooter', 'Bring cash for island trips', 'Book activities early']);
      default: return const SizedBox();
    }
  }

  // ================= OVERVIEW (STYLIZED CARDS) =================
  Widget _overview() {
    final d = widget.destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoCard(Icons.wb_sunny_rounded, 'Best Time', d.bestTime),
            _infoCard(Icons.payments_rounded, 'Avg Cost', d.avgCost),
            _infoCard(Icons.timer_rounded, 'Duration', d.duration),
          ],
        ),
        const SizedBox(height: 32),
        _sectionTitle('About'),
        const SizedBox(height: 8),
        Text(d.about, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15)),
        const SizedBox(height: 32),
        _sectionTitle('Highlights'),
        const SizedBox(height: 12),
        ...d.highlights.map((item) => _checkItem(item)),
      ],
    );
  }

  // ================= REUSABLE COMPONENTS =================
  Widget _circularIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: darkNavy, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkNavy));
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.check, color: primaryBlue, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: darkNavy, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _simpleList(List<String> items) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ...items.map((item) => _checkItem(item)),
      ],
    );
  }

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            minimumSize: const Size.fromHeight(56),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTripStep1(presetDestination: destination.name),
              ),
            );
          },
          child: Text(
            'Plan Trip to ${destination.name}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}