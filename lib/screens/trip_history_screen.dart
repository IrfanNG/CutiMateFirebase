import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import 'trip_detail_screen.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trip History',
          style: TextStyle(
            color: darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),

      body: StreamBuilder<List<Trip>>(
        stream: TripService.loadUserTrips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          final allTrips = snapshot.data!;
          final today = DateTime.now();

          // FILTER ONLY PAST TRIPS
          final pastTrips = allTrips
              .where((t) => t.endDate.isBefore(
                    DateTime(today.year, today.month, today.day),
                  ))
              .toList();

          if (pastTrips.isEmpty) return _emptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: pastTrips.length,
            itemBuilder: (context, index) {
              final trip = pastTrips[index];
              return _tripCard(context, trip);
            },
          );
        },
      ),
    );
  }

  Widget _tripCard(BuildContext context, Trip trip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trip.destination.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: trip.isGroup ? const Color(0xFFEAF5FD) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              trip.isGroup ? 'Group Trip' : 'Solo Trip',
                              style: TextStyle(
                                color: trip.isGroup ? primaryBlue : Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trip.groupName.isEmpty ? trip.destination : trip.groupName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year} — '
                            '${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.8),
                      Row(
                        children: [
                          _infoChip(Icons.people_outline_rounded, '${trip.travelers} Pax'),
                          const SizedBox(width: 16),
                          _infoChip(Icons.account_balance_wallet_outlined, 'RM ${trip.budget.toStringAsFixed(0)}'),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'Your travel diary is empty',
            style: TextStyle(
              color: darkNavy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Past trips will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
