import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int selectedTab = 0;
  final List<String> tabs = ['Itinerary', 'Budget', 'Group', 'Checklist', 'Tasks'];

  // Theme Colors
  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgGray = const Color(0xFFF6F7F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: CustomScrollView(
        slivers: [
          // 1. SMALLER STYLISH HEADER
          SliverAppBar(
            expandedHeight: 100, // Reduced from 140
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14), // Adjusted padding
              title: Text(
                widget.trip.destination,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryBlue, primaryBlue.withOpacity(0.9)],
                  ),
                ),
              ),
            ),
          ),

          // 2. CONTENT AREA
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _summaryDashboard(),
                const SizedBox(height: 24),
                _tabNavigation(),
                const SizedBox(height: 20),
                _tabContent(),
                const SizedBox(height: 120), // Padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  // ================= SUMMARY DASHBOARD =================
  Widget _summaryDashboard() {
    final trip = widget.trip;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _dashItem(Icons.people_outline, '${trip.travelers}', 'Pax'),
                _dashItem(Icons.account_balance_wallet_outlined, 'RM ${trip.budget.toStringAsFixed(0)}', 'Budget'),
                _dashItem(Icons.local_taxi_outlined, trip.transport, 'Mode'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 24),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // ================= PILL TAB NAVIGATION =================
  Widget _tabNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? darkNavy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active
                    ? [BoxShadow(color: darkNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ================= TAB CONTENT SWITCHER =================
  Widget _tabContent() {
    switch (selectedTab) {
      case 0: return _itinerary();
      case 1: return _budget();
      case 2: return _group();
      case 3: return _checklist();
      case 4: return _tasks();
      default: return const SizedBox();
    }
  }

  // ================= ITINERARY =================
  Widget _itinerary() {
    if (widget.trip.itinerary.isEmpty) return _emptyState('No activities planned', Icons.map_outlined);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: widget.trip.itinerary.length,
      itemBuilder: (context, index) {
        final item = widget.trip.itinerary[index];
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                  Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(item.time, style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.note, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= BUDGET =================
  Widget _budget() {
    final expenses = widget.trip.expenses;
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final perPerson = widget.trip.travelers == 0 ? 0.0 : totalSpent / widget.trip.travelers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue, darkNavy]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: darkNavy.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Expenditure', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('RM ${totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text('Average RM ${perPerson.toStringAsFixed(2)} / person', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty) _emptyState('No expenses recorded', Icons.account_balance_wallet_outlined)
          else ...expenses.map((e) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text('RM ${e.amount.toStringAsFixed(2)}', style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  // ================= GROUP =================
  Widget _group() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...widget.trip.members.map((m) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: primaryBlue.withOpacity(0.1), child: Text(m[0], style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))),
              title: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Member', style: TextStyle(fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatScreen(trip: widget.trip))),
              icon: const Icon(Icons.forum_rounded, color: Colors.white),
              label: const Text('Enter Group Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHECKLIST & TASKS =================
  Widget _checklist() {
    return Column(
      children: widget.trip.checklist.map((item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CheckboxListTile(
          value: item.isChecked,
          title: Text(item.title, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
          onChanged: (v) => setState(() => item.isChecked = v!),
          activeColor: primaryBlue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      )).toList(),
    );
  }

  Widget _tasks() {
    return Column(
      children: widget.trip.tasks.map((task) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: CheckboxListTile(
          value: task.completed,
          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          onChanged: (v) => setState(() => task.completed = v!),
          activeColor: primaryBlue,
        ),
      )).toList(),
    );
  }

  // ================= UTILS =================
  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      backgroundColor: darkNavy,
      onPressed: _showQuickActions,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Add Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  void _showQuickActions() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),

          const SizedBox(height: 24),

          _actionTile(Icons.map_outlined, "Add Itinerary",
              () => _addItinerary(sheetContext)),
          _actionTile(Icons.receipt_long_outlined, "Log Expense",
              () => _addExpense(sheetContext)),
          _actionTile(Icons.person_add_alt_1_outlined, "Invite Friend",
              () => _inviteMember(sheetContext)),
          _actionTile(Icons.task_alt_rounded, "Create Task",
              () => _addTask(sheetContext)),
        ],
      ),
    ),
  );
}

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: bgGray, child: Icon(icon, color: darkNavy, size: 20)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }
  void _addItinerary(BuildContext sheetContext) {
  final title = TextEditingController();
  final time = TextEditingController();
  final note = TextEditingController();

  showDialog(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Add Itinerary"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: time, decoration: const InputDecoration(labelText: "Time (e.g 10:00 AM)")),
          TextField(controller: note, decoration: const InputDecoration(labelText: "Note")),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.trip.itinerary.add(
                ItineraryItem(
                  title: title.text,
                  time: time.text,
                  note: note.text,
                ),
              );
            });

            Navigator.pop(dialogContext);   // close dialog
            Navigator.pop(sheetContext);    // close sheet
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

void _addExpense(BuildContext sheetContext) {
  final title = TextEditingController();
  final amount = TextEditingController();

  showDialog(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Log Expense"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (RM)")),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.trip.expenses.add(
                ExpenseItem(
                  title: title.text,
                  amount: double.tryParse(amount.text) ?? 0,
                ),
              );
            });

            Navigator.pop(dialogContext);
            Navigator.pop(sheetContext);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

void _inviteMember(BuildContext sheetContext) {
  final email = TextEditingController();

  showDialog(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Invite Member"),
      content: TextField(
        controller: email,
        decoration: const InputDecoration(labelText: "Email"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.trip.members.add(email.text);
            });

            Navigator.pop(dialogContext);
            Navigator.pop(sheetContext);
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}

void _addTask(BuildContext sheetContext) {
  final task = TextEditingController();

  showDialog(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Create Task"),
      content: TextField(
        controller: task,
        decoration: const InputDecoration(labelText: "Task name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.trip.tasks.add(TaskItem(title: task.text));
            });

            Navigator.pop(dialogContext);
            Navigator.pop(sheetContext);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

}