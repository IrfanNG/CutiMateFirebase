import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// =============================
/// BUDGET OVERVIEW SCREEN
/// Shows summary of all trips' budget, spending,
/// and remaining balance using live Firestore data.
/// =============================
class BudgetOverviewScreen extends StatelessWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// =============================
      /// APP BAR
      /// =============================
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Budget Overview',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      /// =============================
      /// LISTEN TO FIRESTORE LIVE DATA
      /// =============================
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('trips')
            // Only show trips created by logged-in owner
            .where(
              'ownerUid',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          /// Show loading spinner while waiting for data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          /// If no trips exist, show empty state UI
          if (docs.isEmpty) return _empty();

          /// Convert Firestore documents → Trip Model
          final trips = docs.map((d) => Trip.fromJson(d.id, d.data())).toList();

          double totalBudget = 0;
          double totalSpent = 0;

          /// Calculate total budget + total spending
          for (final trip in trips) {
            totalBudget += trip.budget;
            totalSpent += trip.expenses.fold(0.0, (sum, e) => sum + e.amount);
          }

          /// Remaining balance across all trips
          final remaining = totalBudget - totalSpent;

          return Column(
            children: [
              /// Summary header card UI
              _summaryHeader(totalBudget, totalSpent, remaining),

              /// =============================
              /// LIST OF EACH TRIP BUDGET CARD
              /// =============================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Trip Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Loop through trips and show each one
                    ...trips.map((trip) {
                      final spent = trip.expenses.fold(
                        0.0,
                        (sum, e) => sum + e.amount,
                      );

                      return _tripBudgetCard(context, trip, spent);
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ======================================================
  // UI COMPONENTS
  // ======================================================

  /// =============================
  /// SUMMARY HEADER CARD
  /// Shows overall budget status
  /// =============================
  Widget _summaryHeader(double budget, double spent, double remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Remaining",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),

                /// Remaining Money
                Text(
                  "RM ${remaining.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: remaining >= 0 ? Color(0xFF111827) : Colors.red,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 20),

                /// Total Budget VS Spent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _headerInfo("Budget", budget, Colors.black87),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    _headerInfo("Spent", spent, Colors.black87),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small info display inside summary header
  Widget _headerInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "RM ${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// =============================
  /// INDIVIDUAL TRIP BUDGET CARD
  /// Shows spending progress for each trip
  /// =============================
  Widget _tripBudgetCard(BuildContext context, Trip trip, double spent) {
    /// Calculate progress bar value safely
    final progress = trip.budget == 0
        ? 0
        : (spent / trip.budget).clamp(0.0, 1.0);

    /// Check if over budget
    final overBudget = spent > trip.budget;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),

      /// Card content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Trip Name
              Text(
                trip.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),

              /// Warning icon if overspent
              if (overBudget)
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                ),
            ],
          ),
          const SizedBox(height: 12),

          /// Budget text info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RM ${spent.toStringAsFixed(0)} spent",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "Limit: RM ${trip.budget.toStringAsFixed(0)}",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// =============================
          /// PROGRESS BAR
          /// =============================
          Stack(
            children: [
              /// Background bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// Filled progress bar
              FractionallySizedBox(
                widthFactor: progress.toDouble(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: overBudget
                        ? Colors.redAccent
                        : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// =============================
  /// EMPTY STATE UI
  /// Shown when user has no trips
  /// =============================
  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "No transactions yet",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create a trip to start tracking your budget.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
