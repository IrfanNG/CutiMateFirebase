import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetOverviewScreen extends StatelessWidget {
  const BudgetOverviewScreen({super.key});

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Color(0xFF1B4E6B)),
        title: Text(
          'Budget Overview',
          style: TextStyle(
              color: darkNavy, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),

      // 🔥 LIVE FIRESTORE DATA
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('ownerUid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return _empty();

          final trips = docs.map((d) => Trip.fromJson(d.id, d.data())).toList();

          double totalBudget = 0;
          double totalSpent = 0;

          for (final trip in trips) {
            totalBudget += trip.budget;
            totalSpent += trip.expenses.fold(
              0.0,
              (sum, e) => sum + e.amount,
            );
          }

          final remaining = totalBudget - totalSpent;

          return Column(
            children: [
              _summaryHeader(totalBudget, totalSpent, remaining),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Trip Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: darkNavy,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...trips.map((trip) {
                      final spent = trip.expenses.fold(
                        0.0,
                        (sum, e) => sum + e.amount,
                      );

                      return _tripBudgetCard(trip, spent);
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= SUMMARY HEADER =================
  Widget _summaryHeader(double budget, double spent, double remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkNavy, const Color(0xFF2A6E91)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text("Total Remaining",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  "RM ${remaining.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _headerInfo("Budget", budget, Colors.white),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _headerInfo("Spent", spent, Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "RM ${value.toStringAsFixed(0)}",
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // ================= TRIP CARD =================
  Widget _tripBudgetCard(Trip trip, double spent) {
    final progress =
        trip.budget == 0 ? 0 : (spent / trip.budget).clamp(0.0, 1.0);
    final overBudget = spent > trip.budget;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(trip.destination,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: darkNavy)),
            if (overBudget)
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent)
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("RM ${spent.toStringAsFixed(0)} spent",
                style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(
              "Limit: RM ${trip.budget.toStringAsFixed(0)}",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // PROGRESS BAR
        Stack(children: [
          Container(
              height: 8,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10))),
          FractionallySizedBox(
              widthFactor: progress.toDouble(),
              child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: overBudget ? Colors.redAccent : primaryBlue,
                      borderRadius: BorderRadius.circular(10))))
        ])
      ]),
    );
  }

  // ================= EMPTY =================
  Widget _empty() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text("No transactions yet",
            style: TextStyle(
                color: darkNavy.withOpacity(0.5),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Create a trip to start tracking your budget.",
            style: TextStyle(color: Colors.grey))
      ],
    ));
  }
}
  