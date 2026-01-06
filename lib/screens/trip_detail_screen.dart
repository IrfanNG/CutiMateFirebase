
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_trip_screen.dart';

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
    await FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.trip.id)
        .update({
      "itinerary":
          itinerary.map((e) => {"title": e.title, "time": e.time, "note": e.note}).toList(),
      "expenses":
          expenses.map((e) => {"title": e.title, "amount": e.amount}).toList(),
      "members": members,
      "tasks":
          tasks.map((e) => {"title": e.title, "completed": e.completed}).toList(),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _confirmDeleteTrip,
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final updatedTrip = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditTripScreen(trip: widget.trip),
                    ),
                  );

                  if (updatedTrip != null) {
                    setState(() {
                      widget.trip.title = updatedTrip.title;
                      widget.trip.destination = updatedTrip.destination;
                      widget.trip.startDate = updatedTrip.startDate;
                      widget.trip.endDate = updatedTrip.endDate;
                      widget.trip.travelers = updatedTrip.travelers;
                      widget.trip.transport = updatedTrip.transport;
                      widget.trip.accommodation = updatedTrip.accommodation;
                      widget.trip.budget = updatedTrip.budget;
                    });
                  }
                },
              ),
            ],
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
                  fontSize: 18,
                ),
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
  void _confirmDeleteTrip() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Trip?"),
      content: const Text(
          "This action cannot be undone. Do you really want to delete this trip?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () async {
            Navigator.pop(context);
            await _deleteTrip();
          },
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}
Future<void> _deleteTrip() async {
  try {
    final tripRef = FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.trip.id);

    // Delete Subcollections (messages, etc.)
    await _deleteSubCollection(tripRef, "messages");

    // Delete main trip
    await tripRef.delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip deleted successfully")),
    );

    Navigator.pop(context); // go back to previous screen
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Delete failed: $e")),
    );
  }
}
Future<void> _deleteSubCollection(
    DocumentReference parentRef, String collectionName) async {
  final snapshots = await parentRef.collection(collectionName).get();

  for (var doc in snapshots.docs) {
    await doc.reference.delete();
  }
}
void _editTripDetails() {
  final title = TextEditingController(text: widget.trip.title);
  final destination = TextEditingController(text: widget.trip.destination);
  final travelers = TextEditingController(text: widget.trip.travelers.toString());
  final transport = TextEditingController(text: widget.trip.transport);
  final accommodation = TextEditingController(text: widget.trip.accommodation);
  final budget = TextEditingController(text: widget.trip.budget.toString());

  DateTime start = widget.trip.startDate;
  DateTime end = widget.trip.endDate;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Trip Details"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "Trip Title")),
            TextField(controller: destination, decoration: const InputDecoration(labelText: "Destination")),

            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => start = picked);
                    }
                  },
                  child: Text("Start: ${start.day}/${start.month}/${start.year}"),
                ),

                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: end,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => end = picked);
                    }
                  },
                  child: Text("End: ${end.day}/${end.month}/${end.year}"),
                ),
              ],
            ),

            TextField(
              controller: travelers,
              decoration: const InputDecoration(labelText: "Travelers"),
              keyboardType: TextInputType.number,
            ),

            TextField(controller: transport, decoration: const InputDecoration(labelText: "Transport")),
            TextField(controller: accommodation, decoration: const InputDecoration(labelText: "Accommodation")),

            TextField(
              controller: budget,
              decoration: const InputDecoration(labelText: "Budget (RM)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            await _saveTripDetails(
              title.text,
              destination.text,
              start,
              end,
              int.tryParse(travelers.text) ?? 1,
              transport.text,
              accommodation.text,
              double.tryParse(budget.text) ?? 0,
            );

            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
Future<void> _saveTripDetails(
  String title,
  String destination,
  DateTime start,
  DateTime end,
  int travelers,
  String transport,
  String accommodation,
  double budget,
) async {

  await FirebaseFirestore.instance
      .collection("trips")
      .doc(widget.trip.id)
      .update({
    "title": title,
    "destination": destination,
    "startDate": start.millisecondsSinceEpoch,
    "endDate": end.millisecondsSinceEpoch,
    "travelers": travelers,
    "transport": transport,
    "accommodation": accommodation,
    "budget": budget,
  });

  // Update UI immediately
  setState(() {
    widget.trip.title = title;
    widget.trip.destination = destination;
    widget.trip.startDate = start;
    widget.trip.endDate = end;
    widget.trip.travelers = travelers;
    widget.trip.transport = transport;
    widget.trip.accommodation = accommodation;
    widget.trip.budget = budget;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Trip updated successfully")),
  );
}


  // ================= SUMMARY =================
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
            const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _dashItem(IconData icon, String v, String l) =>
      Column(children: [
        Icon(icon, color: primaryBlue, size: 24),
        const SizedBox(height: 6),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        Text(l, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]);

  // ================= TABS =================
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
                    color: active ? Colors.white : Colors.grey.shade600,
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
    if (itinerary.isEmpty) return _empty("No itinerary");

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: itinerary.length,
      itemBuilder: (context, index) {
        final item = itinerary[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text(item.time, style: TextStyle(color: primaryBlue)),
                    Text(item.note)
                  ])),
              Row(children: [
                IconButton(
                    icon: Icon(Icons.edit, color: primaryBlue),
                    onPressed: () => _editItinerary(index)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItinerary(index)),
              ])
            ],
          ),
        );
      },
    );
  }

  void _editItinerary(int i) {
    final t = TextEditingController(text: itinerary[i].title);
    final ti = TextEditingController(text: itinerary[i].time);
    final n = TextEditingController(text: itinerary[i].note);

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Edit Itinerary"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: ti, decoration: const InputDecoration(labelText: "Time")),
                TextField(controller: n, decoration: const InputDecoration(labelText: "Note")),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() =>
                          itinerary[i] = ItineraryItem(title: t.text, time: ti.text, note: n.text));
                      await _saveToFirestore();
                      Navigator.pop(context);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _deleteItinerary(int i) async {
    setState(() => itinerary.removeAt(i));
    await _saveToFirestore();
  }

  // ================= BUDGET =================
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
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Total Budget: RM ${widget.trip.budget.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Total Spent: RM ${totalSpent.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Remaining: RM ${remaining.toStringAsFixed(2)}",
                style: TextStyle(
                  color: remaining >= 0
                      ? Colors.lightGreenAccent
                      : Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // ===== AUTO COST SPLIT =====
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Each person pays: RM ${perPerson.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ===== EXPENSE LIST =====
        if (expenses.isEmpty)
          _emptyState(
            "No expenses recorded",
            Icons.account_balance_wallet_outlined,
          )
        else
          ...expenses.map((e) {
            int index = expenses.indexOf(e);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(e.title),
                subtitle: Text("RM ${e.amount.toStringAsFixed(2)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: primaryBlue),
                      onPressed: () => _editExpense(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteExpense(index),
                    ),
                  ],
                ),
              ),
            );
          })
      ],
    ),
  );
}
  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(int index) async {
    setState(() => expenses.removeAt(index));
    await _saveToFirestore();
  }
void _editExpense(int index) {
  final title = TextEditingController(text: expenses[index].title);
  final amount = TextEditingController(text: expenses[index].amount.toString());

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Expense"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Title")),
          TextField(
            controller: amount,
            decoration: const InputDecoration(labelText: "Amount"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              expenses[index] = ExpenseItem(
                title: title.text,
                amount: double.tryParse(amount.text) ?? 0,
              );
            });

            await _saveToFirestore();
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}


  // ================= GROUP =================
  Widget _group() => Column(children: [
        ...members.map((m) => Card(
              child: ListTile(
                  leading: CircleAvatar(child: Text(m[0].toUpperCase())),
                  title: Text(m)),
            )),
        ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => TripChatScreen(trip: widget.trip))),
            icon: const Icon(Icons.chat),
            label: const Text("Enter Group Chat"))
      ]);

  // ================= CHECKLIST =================
  Widget _checklist() {
    if (checklist.isEmpty) return _empty("No checklist");

    return Column(
      children: checklist.asMap().entries.map((entry) {
        int i = entry.key;
        var item = entry.value;

        return CheckboxListTile(
          value: item.isChecked,
          title: Text(
            item.title,
            style: TextStyle(
                decoration: item.isChecked ? TextDecoration.lineThrough : null),
          ),
          onChanged: (v) async {
            setState(() => item.isChecked = v!);
            await _saveToFirestore();
          },
          secondary: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: Icon(Icons.edit, color: primaryBlue), onPressed: () => _editChecklist(i)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteChecklist(i)),
          ]),
        );
      }).toList(),
    );
  }

  void _editChecklist(int i) {
    final t = TextEditingController(text: checklist[i].title);

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Edit Checklist"),
              content: TextField(controller: t),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => checklist[i].title = t.text);
                      await _saveToFirestore();
                      Navigator.pop(context);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _deleteChecklist(int i) async {
    setState(() => checklist.removeAt(i));
    await _saveToFirestore();
  }

  // ================= TASKS =================
  Widget _tasks() {
    if (tasks.isEmpty) return _empty("No tasks");

    return Column(
      children: tasks.asMap().entries.map((entry) {
        int i = entry.key;
        var task = entry.value;

        return CheckboxListTile(
          value: task.completed,
          title: Text(task.title),
          onChanged: (v) async {
            setState(() => task.completed = v!);
            await _saveToFirestore();
          },
          secondary: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: Icon(Icons.edit, color: primaryBlue), onPressed: () => _editTask(i)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTask(i)),
          ]),
        );
      }).toList(),
    );
  }

  void _editTask(int i) {
    final t = TextEditingController(text: tasks[i].title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Task"),
        content: TextField(
          controller: t,
          decoration: const InputDecoration(labelText: "Task name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                tasks[i] = TaskItem(
                  title: t.text.trim(),
                  completed: tasks[i].completed,   // keep current status
                );
              });

              await _saveToFirestore();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteTask(int i) async {
    setState(() => tasks.removeAt(i));
    await _saveToFirestore();
  }

  // ================= COMMON =================
  Widget _empty(String t) => Padding(
        padding: const EdgeInsets.all(30),
        child: Text(t, style: TextStyle(color: Colors.grey.shade500)),
      );

  Widget _fab() => FloatingActionButton.extended(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        onPressed: _showActions,
        icon: const Icon(Icons.add),
        label: const Text("Add Plan"),
      );

  void _showActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (s) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        _action(Icons.map_outlined, "Add Itinerary", () => _addItinerary(s)),
        _action(Icons.receipt, "Log Expense", () => _addExpense(s)),
        _action(Icons.person_add, "Invite Member", () => _inviteMember(s)),
        _action(Icons.checklist, "Add Checklist", () => _addChecklist(s)),
        _action(Icons.task_alt, "Add Task", () => _addTask(s)),
      ]),
    );
  }

  ListTile _action(IconData i, String t, VoidCallback f) =>
      ListTile(leading: Icon(i), title: Text(t), onTap: f);

  // ================= ADD FORMS =================
  void _addItinerary(BuildContext c) {
    final t = TextEditingController();
    final ti = TextEditingController();
    final n = TextEditingController();

    showDialog(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text("Add Itinerary"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: ti, decoration: const InputDecoration(labelText: "Time")),
                TextField(controller: n, decoration: const InputDecoration(labelText: "Note")),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => itinerary.add(ItineraryItem(title: t.text, time: ti.text, note: n.text)));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _addExpense(BuildContext c) {
    final t = TextEditingController();
    final a = TextEditingController();

    showDialog(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text("Log Expense"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: a, decoration: const InputDecoration(labelText: "Amount")),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => expenses.add(
                          ExpenseItem(title: t.text, amount: double.tryParse(a.text) ?? 0)));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _inviteMember(BuildContext c) {
    final e = TextEditingController();

    showDialog(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text("Invite Member"),
              content: TextField(controller: e),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => members.add(e.text));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Add"))
              ],
            ));
  }

  void _addChecklist(BuildContext c) {
    final t = TextEditingController();

    showDialog(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text("Add Checklist"),
              content: TextField(controller: t),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => checklist.add(ChecklistItem(title: t.text)));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _addTask(BuildContext c) {
    final t = TextEditingController();

    showDialog(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text("Add Task"),
              content: TextField(controller: t),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      setState(() => tasks.add(TaskItem(title: t.text)));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Save"))
              ],
            ));
  }
}
