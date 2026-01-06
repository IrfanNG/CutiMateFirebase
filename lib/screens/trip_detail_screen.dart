import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int selectedTab = 0;
  final List<String> tabs = ['Itinerary', 'Budget', 'Group', 'Checklist', 'Tasks'];

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);
  final Color bgGray = const Color(0xFFF6F7F9);

  late List<ItineraryItem> itinerary;
  late List<ExpenseItem> expenses;
  late List<String> members;
  late List<TaskItem> tasks;
  late List<ChecklistItem> checklist;

  @override
  void initState() {
    super.initState();
    itinerary = List.from(widget.trip.itinerary);
    expenses = List.from(widget.trip.expenses);
    members = List.from(widget.trip.members);
    tasks = List.from(widget.trip.tasks);
    checklist = List.from(widget.trip.checklist);
  }

  Future<void> _saveToFirestore() async {
    final tripDoc =
        FirebaseFirestore.instance.collection("trips").doc(widget.trip.id);

    await tripDoc.update({
      "itinerary": itinerary
          .map((e) => {"title": e.title, "time": e.time, "note": e.note})
          .toList(),
      "expenses": expenses
          .map((e) => {"title": e.title, "amount": e.amount})
          .toList(),
      "members": members,
      "tasks": tasks
          .map((e) => {"title": e.title, "completed": e.completed})
          .toList(),
      "checklist":
          checklist.map((e) => {"title": e.title, "checked": e.isChecked}).toList()
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                widget.trip.destination,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _summaryDashboard(),
                const SizedBox(height: 24),
                _tabNavigation(),
                const SizedBox(height: 20),
                _tabContent(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  Widget _summaryDashboard() {
    final trip = widget.trip;
    final today = DateTime.now();

    final isPastTrip = trip.endDate.isBefore(
      DateTime(today.year, today.month, today.day),
    );

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
                  offset: const Offset(0, 10))
            ]),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPastTrip
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPastTrip ? "COMPLETED" : "ACTIVE",
                style: TextStyle(
                    color: isPastTrip ? Colors.red : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dashItem(Icons.people_outline, '${trip.travelers}', 'Pax'),
              _dashItem(Icons.account_balance_wallet_outlined,
                  'RM ${trip.budget.toStringAsFixed(0)}', 'Budget'),
              _dashItem(Icons.local_taxi_outlined, trip.transport, 'Mode'),
            ],
          )
        ]),
      ),
    );
  }

  Widget _dashItem(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: primaryBlue, size: 24),
      const SizedBox(height: 6),
      Text(value,
          style:
              const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? darkNavy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: darkNavy.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                    color:
                        active ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabContent() {
    switch (selectedTab) {
      case 0:
        return _itinerary();
      case 1:
        return _budget();
      case 2:
        return _group();
      case 3:
        return _checklist();
      case 4:
        return _tasks();
      default:
        return const SizedBox();
    }
  }

  // -------- ITINERARY --------
  Widget _itinerary() {
    if (itinerary.isEmpty) {
      return _emptyState("No activities planned", Icons.map_outlined);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: itinerary.length,
      itemBuilder: (context, index) {
        final item = itinerary[index];

        return IntrinsicHeight(
          child: Row(children: [
            Column(children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
              ),
              Expanded(
                  child: Container(
                      width: 2, color: Colors.grey.shade300)),
            ]),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10)
                    ]),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(item.time,
                              style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.note,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13)),
                    ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  // -------- BUDGET --------
  Widget _budget() {
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final remaining = widget.trip.budget - totalSpent;
    final perPerson = widget.trip.travelers == 0
        ? 0.0
        : totalSpent / widget.trip.travelers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ===== SUMMARY CARD =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue, darkNavy]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: darkNavy.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Trip Budget Summary",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // TOTAL BUDGET
                Text(
                  "Total Budget: RM ${widget.trip.budget.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                // TOTAL SPENT
                Text(
                  "Total Spent: RM ${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                // REMAINING
                Text(
                  "Remaining: RM ${remaining.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.lightGreenAccent : Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // COST SPLIT
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Each person pays: RM ${perPerson.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== EXPENSE LIST =====
          if (expenses.isEmpty)
            _emptyState("No expenses recorded",
                Icons.account_balance_wallet_outlined)
          else
            ...expenses.map(
              (e) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(e.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    "RM ${e.amount.toStringAsFixed(2)}",
                    style: TextStyle(
                        color: darkNavy, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------- GROUP --------
  Widget _group() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ...members.map((m) => Card(
              child: ListTile(
                leading: CircleAvatar(
                    child: Text(m[0].toUpperCase())),
                title: Text(m),
              ),
            )),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      TripChatScreen(trip: widget.trip))),
          icon: const Icon(Icons.chat),
          label: const Text("Enter Group Chat"),
        )
      ]),
    );
  }

  // -------- CHECKLIST --------
  Widget _checklist() {
  if (checklist.isEmpty) {
    return _emptyState("No checklist yet", Icons.checklist_rounded);
  }

  return Column(
    children: checklist.map((item) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CheckboxListTile(
          value: item.isChecked,
          title: Text(
            item.title,
            style: TextStyle(
              decoration: item.isChecked
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          onChanged: (v) {
            setState(() {
              item.isChecked = v!;
            });

            FirebaseFirestore.instance
                .collection('trips')
                .doc(widget.trip.id)
                .update({
              'checklist': checklist.map((c) => c.toMap()).toList(),
            });
          },
          activeColor: primaryBlue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    ).toList(),
  );
}

  // -------- TASKS --------
  Widget _tasks() {
    return Column(
      children: tasks
          .map((task) => CheckboxListTile(
                value: task.completed,
                onChanged: (v) =>
                    setState(() => task.completed = v!),
                title: Text(task.title),
              ))
          .toList(),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Column(children: [
      const SizedBox(height: 40),
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 10),
      Text(text,
          style: TextStyle(color: Colors.grey.shade500)),
    ]);
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      backgroundColor: darkNavy,
      foregroundColor: Colors.white,     // <-- makes text + icon white
      onPressed: _showQuickActions,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "Add Plan",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= ACTIONS =================
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
         _actionTile(Icons.map_outlined, "Add Itinerary",
            () => _addItinerary(sheetContext)),
        _actionTile(Icons.receipt_long_outlined, "Log Expense",
            () => _addExpense(sheetContext)),
        _actionTile(Icons.person_add_alt_1_outlined, "Invite Member",
            () => _inviteMember(sheetContext)),
        _actionTile(Icons.checklist_rounded, "Add Checklist",
            () => _addChecklist(sheetContext)),
        _actionTile(Icons.task_alt_rounded, "Add New Task",
            () => _addTask(sheetContext)),
        ],
      ),
    );
  }

  Widget _actionTile(
          IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      );

  // ---- ADD FORMS ----
  void _addItinerary(BuildContext ctx) {
    final t = TextEditingController();
    final ti = TextEditingController();
    final n = TextEditingController();

    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text("Add Itinerary"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: ti, decoration: const InputDecoration(labelText: "Time")),
                  TextField(controller: n, decoration: const InputDecoration(labelText: "Note")),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      ItineraryItem item = ItineraryItem(
                          title: t.text, time: ti.text, note: n.text);
                      setState(() => itinerary.add(item));
                      await _saveToFirestore();
                      Navigator.pop(ctx);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _addExpense(BuildContext ctx) {
    final t = TextEditingController();
    final a = TextEditingController();

    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text("Log Expense"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: a, decoration: const InputDecoration(labelText: "Amount")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() =>
                          expenses.add(ExpenseItem(title: t.text, amount: double.tryParse(a.text) ?? 0)));
                      await _saveToFirestore();
                      Navigator.pop(ctx);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _inviteMember(BuildContext ctx) {
    final e = TextEditingController();

    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text("Invite Member"),
              content: TextField(controller: e, decoration: const InputDecoration(labelText: "Email")),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => members.add(e.text));
                      await _saveToFirestore();
                      Navigator.pop(ctx);
                    },
                    child: const Text("Add"))
              ],
            ));
  }

  void _addChecklist(BuildContext sheetContext) {
  final item = TextEditingController();

  showDialog(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Add Checklist Item"),
      content: TextField(
        controller: item,
        decoration: const InputDecoration(labelText: "Checklist item"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (item.text.trim().isEmpty) return;

            // Update UI list
            setState(() {
              checklist.add(
                ChecklistItem(
                  title: item.text.trim(),
                  isChecked: false,
                ),
              );
            });

            // Save to Firestore
            await FirebaseFirestore.instance
                .collection('trips')
                .doc(widget.trip.id)
                .update({
              'checklist': checklist.map((c) => c.toMap()).toList(),
            });

            Navigator.pop(dialogContext); // close dialog
            Navigator.pop(sheetContext);  // close bottom sheet
          },
          child: const Text("Save"),
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
      title: const Text("Add New Task"),
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
          onPressed: () async {
            if (task.text.trim().isEmpty) return;

            // Update UI
            setState(() {
              tasks.add(
                TaskItem(
                  title: task.text.trim(),
                  completed: false,
                ),
              );
            });

            // Save to Firestore
            await FirebaseFirestore.instance
                .collection('trips')
                .doc(widget.trip.id)
                .update({
              'tasks': tasks.map((t) => t.toMap()).toList(),
            });

            Navigator.pop(dialogContext);  // close dialog
            Navigator.pop(sheetContext);   // close bottom sheet
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
}
