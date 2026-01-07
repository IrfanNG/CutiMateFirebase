import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_trip_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'destination_vote_screen.dart';

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
    await FirebaseFirestore.instance.collection("trips").doc(widget.trip.id).update({
      "itinerary": itinerary.map((e) => {"title": e.title, "time": e.time, "note": e.note}).toList(),
      "expenses": expenses.map((e) => {"title": e.title, "amount": e.amount}).toList(),
      "members": members,
      "tasks": tasks.map((e) => {"title": e.title, "completed": e.completed}).toList(),
      "checklist": checklist.map((e) => {"title": e.title, "checked": e.isChecked}).toList()
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: CustomScrollView(
        slivers: [
          _appBar(),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _summaryCard(),
                const SizedBox(height: 24),
                _tabs(),
                const SizedBox(height: 18),
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

  // =================== APP BAR ===================
  Widget _appBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryBlue,
      leading: const BackButton(color: Colors.white),

      actions: [
        IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _confirmDeleteTrip),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () async {
            final updatedTrip = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditTripScreen(trip: widget.trip)),
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
    );
  }

  // =================== SUMMARY CARD ===================
  Widget _summaryCard() {
    final trip = widget.trip;
    final isPast = trip.endDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryBlue, darkNavy]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_month, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                "${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPast ? "COMPLETED" : "ACTIVE",
                  style: TextStyle(color: isPast ? Colors.redAccent : Colors.lightGreenAccent, fontSize: 10),
                ),
              )
            ]),

            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _summaryIcon(Icons.people_alt, "${trip.travelers} Pax"),
              _summaryIcon(Icons.wallet, "RM ${trip.budget.toStringAsFixed(0)}"),
              _summaryIcon(Icons.directions_car, trip.transport)
            ]),
          ],
        ),
      ),
    );
  }

  Widget _summaryIcon(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
      ],
    );
  }

  // =================== TABS ===================
  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = selectedTab == i;

          return GestureDetector(
            onTap: () => setState(() => selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? darkNavy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active
                    ? [BoxShadow(color: darkNavy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold),
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

  // =====================================================
  // YOUR ORIGINAL LOGIC BELOW (UI Polished Slightly Only)
  // =====================================================

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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(item.time, style: TextStyle(color: primaryBlue)),
                        Text(item.note)
                      ])),
              Row(children: [
                IconButton(icon: Icon(Icons.edit, color: primaryBlue), onPressed: () => _editItinerary(index)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItinerary(index)),
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
                      setState(() => itinerary[i] = ItineraryItem(title: t.text, time: ti.text, note: n.text));
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
    final perPerson = widget.trip.travelers == 0 ? 0 : totalSpent / widget.trip.travelers;

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Trip Budget Summary",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Text("Total Budget: RM ${widget.trip.budget.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),

              Text("Total Spent: RM ${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),

              Text("Remaining: RM ${remaining.toStringAsFixed(2)}",
                  style: TextStyle(
                      color: remaining >= 0 ? Colors.lightGreenAccent : Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text("Each person pays: RM ${perPerson.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          if (expenses.isEmpty)
            _emptyState("No expenses recorded", Icons.account_balance_wallet_outlined)
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
                      IconButton(icon: Icon(Icons.edit, color: primaryBlue), onPressed: () => _editExpense(index)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExpense(index)),
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
      child: Column(children: [
        Icon(icon, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey.shade500)),
      ]),
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: amount, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                expenses[index] = ExpenseItem(title: title.text, amount: double.tryParse(amount.text) ?? 0);
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
  Widget _group() {
    final user = FirebaseAuth.instance.currentUser!;
    final bool isOwner = widget.trip.ownerUid == user.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ...members.map((m) {
          final bool memberIsOwner = m == widget.trip.ownerUid;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(m[0].toUpperCase())),
              title: Text(m),
              trailing: memberIsOwner
                  ? const Text("Owner", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                  : isOwner
                      ? IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _confirmRemoveMember(m))
                      : null,
            ),
          );
        }).toList(),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DestinationVoteScreen(tripId: widget.trip.id))),
          icon: const Icon(Icons.how_to_vote),
          label: const Text("Vote Destination"),
        ),

        if (isOwner)
          ElevatedButton.icon(
            onPressed: () => _inviteMember(context),
            icon: const Icon(Icons.person_add),
            label: const Text("Invite Member"),
          ),

        if (!isOwner) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _leaveGroup,
            icon: const Icon(Icons.logout),
            label: const Text("Leave Group"),
          ),
        ],

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripChatScreen(trip: widget.trip))),
          icon: const Icon(Icons.chat),
          label: const Text("Enter Group Chat"),
        ),
      ]),
    );
  }

  // ================= CHECKLIST =================
  Widget _checklist() {
    if (checklist.isEmpty) return _empty("No checklist");

    return Column(
      children: checklist.asMap().entries.map((entry) {
        int i = entry.key;
        var item = entry.value;

        return CheckboxListTile(
          value: item.isChecked,
          title: Text(item.title, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
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
        content: TextField(controller: t, decoration: const InputDecoration(labelText: "Task name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              setState(() => tasks[i] = TaskItem(title: t.text.trim(), completed: tasks[i].completed));
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

  // ================= EMPTY =================
  Widget _empty(String t) => Padding(
        padding: const EdgeInsets.all(30),
        child: Text(t, style: TextStyle(color: Colors.grey.shade500)),
      );

  // ================= FAB =================
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                      setState(() => expenses.add(ExpenseItem(title: t.text, amount: double.tryParse(a.text) ?? 0)));
                      await _saveToFirestore();
                      Navigator.pop(c);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  void _inviteMember(BuildContext ctx) {
    if (members.length >= widget.trip.travelers) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Group is Full"),
          content: Text("You already have ${members.length} members.\nTrip pax limit is ${widget.trip.travelers}."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    final emailController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Invite Member"),
        content: TextField(controller: emailController, decoration: const InputDecoration(labelText: "Member Email")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              if (members.length >= widget.trip.travelers) {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Group is Full"),
                    content: Text("Cannot invite more members.\nPax limit: ${widget.trip.travelers}"),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                  ),
                );
                return;
              }

              setState(() => members.add(email));

              await FirebaseFirestore.instance.collection("trips").doc(widget.trip.id).update({"members": members});

              Navigator.pop(ctx);
            },
            child: const Text("Invite"),
          ),
        ],
      ),
    );
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

  // ================= DELETE TRIP =================
  void _confirmDeleteTrip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Trip?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteTrip();
              },
              child: const Text("Delete"))
        ],
      ),
    );
  }

  Future<void> _deleteTrip() async {
    try {
      final tripRef = FirebaseFirestore.instance.collection("trips").doc(widget.trip.id);
      await _deleteSubCollection(tripRef, "messages");
      await tripRef.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip deleted")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _deleteSubCollection(DocumentReference parentRef, String collectionName) async {
    final snapshots = await parentRef.collection(collectionName).get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _leaveGroup() async {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave Group?"),
        content: const Text("You will lose access to this trip."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Leave")),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => members.remove(email));

    await FirebaseFirestore.instance.collection("trips").doc(widget.trip.id).update({"members": members});

    if (mounted) Navigator.pop(context);
  }

  void _confirmRemoveMember(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Remove $email from this trip?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                setState(() => members.remove(email));
                await FirebaseFirestore.instance.collection("trips").doc(widget.trip.id).update({"members": members});
                Navigator.pop(context);
              },
              child: const Text("Remove"))
        ],
      ),
    );
  }
}
