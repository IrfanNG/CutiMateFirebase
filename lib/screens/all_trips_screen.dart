import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import 'trip_detail_screen.dart';

enum TripListType { upcoming, shared }

class AllTripsScreen extends StatelessWidget {
  final TripListType type;

  const AllTripsScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = type == TripListType.upcoming
        ? "Upcoming Trips"
        : "Shared Trips";
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    Query query;

    if (type == TripListType.upcoming) {
      query = FirebaseFirestore.instance
          .collection('trips')
          .where('ownerUid', isEqualTo: user.uid);
    } else {
      query = FirebaseFirestore.instance
          .collection('trips')
          .where('members', arrayContains: user.email);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        var trips = docs
            .map((d) => Trip.fromJson(d.id, d.data() as Map<String, dynamic>))
            .toList();

        final now = DateTime.now();

        // Filter and Sort
        if (type == TripListType.upcoming) {
          trips = trips.where((t) {
            final tripEnd = DateTime(
              t.endDate.year,
              t.endDate.month,
              t.endDate.day,
              23,
              59,
              59,
            );
            return tripEnd.isAfter(now);
          }).toList();
        } else {
          // Shared: Exclude own trips just in case AND filter past trips
          trips = trips.where((t) {
            if (t.ownerUid == user.uid) return false;
            final tripEnd = DateTime(
              t.endDate.year,
              t.endDate.month,
              t.endDate.day,
              23,
              59,
              59,
            );
            return tripEnd.isAfter(now);
          }).toList();
        }

        trips.sort((a, b) => a.startDate.compareTo(b.startDate));

        if (trips.isEmpty) {
          return Center(
            child: Text(
              "No ${type == TripListType.upcoming ? 'upcoming' : 'shared'} trips found",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildTripCard(context, trips[index]);
          },
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    String imageUrl = (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
        ? trip.imageUrl!
        : _getImageForDestination(trip.destination);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade300, width: 120),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      trip.destination,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageForDestination(String destination) {
    String lower = destination.toLowerCase();
    if (lower.contains('bali'))
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1000';
    if (lower.contains('kyoto'))
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=1000';
    if (lower.contains('paris'))
      return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000';
    return 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070&auto=format&fit=crop';
  }

  String _formatDate(DateTime date) {
    const months = [
      "OCT",
      "NOV",
      "DEC",
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
    ];
    return "${months[(date.month % 12 + 9) % 12]} ${date.day}";
  }
}
