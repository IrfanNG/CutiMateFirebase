import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart'; // Re-added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_trip_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'destination_vote_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/curved_bottom_clipper.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int selectedTab = 0;
  final List<String> tabs = [
    'Itinerary',
    'Expenses', // Renamed from Accommodation
    'Group', // Renamed from Activities
    'Checklist',
    'Tasks',
  ];

  final Color bgGray = const Color(0xFFFFFBF6);

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
          "itinerary": itinerary.map((e) => e.toMap()).toList(),
          "expenses": expenses.map((e) => e.toMap()).toList(),
          "members": members,
          "tasks": tasks.map((e) => e.toMap()).toList(),
          "checklist": checklist.map((e) => e.toMap()).toList(),
          "categoryAssignments": widget.trip.categoryAssignments,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Header
          _buildHeroAppBar(),

          // 2. Title & Info & Tabs
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(),
                const SizedBox(height: 24),
                _tabNavigation(),
                const SizedBox(height: 24),
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

  void _addTask(BuildContext context) {
    final t = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Task"),
        content: TextField(
          controller: t,
          decoration: const InputDecoration(labelText: "Description"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (t.text.trim().isNotEmpty) {
                setState(() => tasks.add(TaskItem(title: t.text.trim())));
                await _saveToFirestore();
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Floating Action Button dependent on tab
  Widget? _fab() {
    switch (selectedTab) {
      case 0: // Itinerary
        return FloatingActionButton(
          onPressed: _addItinerary,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_location_alt_outlined),
        );
      case 1: // Expenses
        return FloatingActionButton(
          onPressed: _addExpense,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.receipt_long),
        );
      case 3: // Checklist
        return FloatingActionButton(
          onPressed: () => _addChecklist(context),
          backgroundColor: const Color(0xFFFF7F50),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_task),
        );
      case 4: // Tasks
        return FloatingActionButton(
          onPressed: () => _addTask(context),
          backgroundColor: const Color(0xFFFF7F50),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_task),
        );
      default:
        return null; // No FAB for Group or Map by default, or maybe Map needs one?
      // User said "remove button at middle and just remain using action button".
      // For Group, actions are usually internal (Invite etc).
      // For Map, maybe current location?
    }
  }

  void _confirmDeleteTrip() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Trip?"),
        content: const Text(
          "This action cannot be undone. Do you really want to delete this trip?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _deleteSubCollection(
    DocumentReference parentRef,
    String collectionName,
  ) async {
    final snapshots = await parentRef.collection(collectionName).get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  // ================= HERO HEADER =================
  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const BackButton(color: Colors.white),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {
              // Share logic
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteTrip();
              } else if (value == 'edit') {
                // Trigger edit
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTripScreen(trip: widget.trip),
                  ),
                ).then((updatedTrip) {
                  if (updatedTrip != null) {
                    setState(() {
                      // Update logic
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
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text("Edit Trip"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text("Delete Trip", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Image.network(
                (widget.trip.imageUrl != null &&
                        widget.trip.imageUrl!.isNotEmpty)
                    ? widget.trip.imageUrl!
                    : _getImageForDestination(widget.trip.destination),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Gradient
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageForDestination(String destination) {
    String lower = destination.toLowerCase();
    if (lower.contains('bali')) {
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1000';
    }
    if (lower.contains('kyoto')) {
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=1000';
    }
    if (lower.contains('paris')) {
      return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000';
    }
    return 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070&auto=format&fit=crop';
  }

  // ================= TITLE SECTION =================
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.trip.title.isNotEmpty
                ? widget.trip.title
                : widget.trip.destination,
            style: const TextStyle(
              fontFamily: 'Serif', // Try to get that elegant look
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7F50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFFFF7F50),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(widget.trip.startDate)} - ${_formatDate(widget.trip.endDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7F50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${widget.trip.endDate.difference(widget.trip.startDate).inDays} Days • ${widget.trip.travelers} Travelers",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
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
    return "${months[(date.month % 12 + 9) % 12]} ${date.day}"; // Correct mapping logic roughly or just use simpler
  }

  // ================= TABS =================
  Widget _tabNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFF7F50) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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

  // ================= ITINERARY =================
  Widget _itinerary() {
    // If no items at all, show empty state (optional, but maybe better to show the days even if empty?)
    // Let's stick to: if no items, show empty, OR show days structure.
    // User wants to see "Day 1", "Day 2".
    // If list is empty, we can show "Day 1" with no items?
    // Let's keep the _empty check if truly empty for now, or just remove it to always show days.
    // Actually, if completely empty, the "Day 01" hardcode was previously shown? No, it showed empty state.
    if (itinerary.isEmpty) {
      return Column(
        children: [_empty("No itinerary items yet. Use the + button to add.")],
      );
    }

    // Sort itinerary by day
    itinerary.sort((a, b) {
      if (a.day != b.day) return a.day.compareTo(b.day);
      // specific time parsing is hard, so we just rely on day sort for now.
      return 0;
    });

    // Group by Day
    // We can loop through the total days of the trip to ensure order
    int totalDays = widget.trip.days;
    // Just in case totalDays is calculated weirdly or 0
    if (totalDays < 1) totalDays = 1;

    // Use a Set of days that have items to avoid showing 30 empty days?
    // Or simpler: Iterate through the items and group them.
    // But user might want to see "Day 2" to add to it? The add button is global.
    // Let's iterate through unique days present in the itinerary for now, plus maybe Day 1 if effectively empty.
    // Actually, distinct days from the list is safer.

    // Get unique days from itinerary
    final uniqueDays = itinerary.map((e) => e.day).toSet().toList()..sort();

    // If we want to show consecutive days even if empty, we could.
    // But let's stick to showing days that have items.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...uniqueDays.map((day) {
            final itemsForDay = itinerary.where((e) => e.day == day).toList();
            // Determine date for this day
            DateTime date = widget.trip.startDate.add(Duration(days: day - 1));
            String dateStr = _formatDate(date); // e.g. OCT 5

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dayHeader(day.toString().padLeft(2, '0'), dateStr),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemsForDay.length,
                  itemBuilder: (context, index) {
                    // Find original index in main list to support edit/delete
                    // Actually, edit/delete uses index of `itinerary`.
                    // We need to pass the correct index or modify edit/delete to take the item or ID.
                    // Since we don't have IDs, we need to find the index in the main list.
                    final item = itemsForDay[index];
                    final mainIndex = itinerary.indexOf(item);

                    return _itineraryCard(item, mainIndex);
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 24),
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
      child: Column(
        children: [
          _sectionHeader("Group Members"),
          const SizedBox(height: 12),

          if (members.isEmpty)
            const Text("No members yet")
          else
            ...members.map((m) {
              final bool memberIsOwner = m == widget.trip.ownerUid;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(
                      0xFFFF7F50,
                    ).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFFF7F50),
                    child: Text(
                      m.isNotEmpty ? m[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    m,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: memberIsOwner
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF7F50,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFFF7F50,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            "Owner",
                            style: TextStyle(
                              color: Color(0xFFFF7F50),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : isOwner
                      ? IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmRemoveMember(m),
                        )
                      : null,
                ),
              );
            }),

          const SizedBox(height: 24),
          _sectionHeader("Actions"),
          const SizedBox(height: 12),

          // Group Chat
          _groupActionButton(
            "Group Chat",
            Icons.chat_bubble_outline_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripChatScreen(trip: widget.trip),
              ),
            ),
            color: const Color(0xFFFF7F50),
          ),
          const SizedBox(height: 12),

          // Destination Vote
          _groupActionButton(
            "Destination Vote",
            Icons.poll_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DestinationVoteScreen(tripId: widget.trip.id),
              ),
            ),
            color: const Color(0xFFFF7F50),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),

          // Invite
          if (isOwner)
            _groupActionButton(
              "Invite New Member",
              Icons.person_add_alt_1_outlined,
              () => _inviteMember(context),
              color: const Color(0xFFFF7F50),
            ),

          // Leave
          if (!isOwner) ...[
            const SizedBox(height: 12),
            _groupActionButton(
              "Leave Group",
              Icons.logout_rounded,
              _leaveGroup,
              isDanger: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _groupActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isDanger = false,
    Color color = Colors.black87,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isDanger ? Colors.red.shade50 : Colors.white,
          foregroundColor: isDanger ? Colors.red : color,
          elevation: 0,
          side: BorderSide(
            color: isDanger ? Colors.red.shade100 : Colors.grey.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      members.remove(email);
    });

    await FirebaseFirestore.instance
        .collection("trips")
        .doc(widget.trip.id)
        .update({"members": members});

    if (mounted) Navigator.pop(context);
  }

  void _confirmRemoveMember(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Remove $email from this trip?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() {
                members.remove(email);
              });

              await FirebaseFirestore.instance
                  .collection("trips")
                  .doc(widget.trip.id)
                  .update({"members": members});

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  Widget _dayHeader(String dayNum, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1), // Soft teal
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Color(0xFF00695C)),
          ),
          const SizedBox(width: 12),
          Text(
            "Day $dayNum: $title",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _itineraryCard(ItineraryItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              // Randomize or pick based on item title keyword
              _getItineraryImage(item.title),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Serif',
                        ),
                      ),
                    ),
                    // Checkbox or Status
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${item.time} • Private Transfer", // Mock extra detail
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.note,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],

                if (item.lat != null && item.lng != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final lat = item.lat;
                        final lng = item.lng;

                        // 1. Try native map intent (geo:...)
                        // This usually prompts selection (Maps, Waze, etc.)
                        final Uri geoUrl = Uri.parse(
                          "geo:$lat,$lng?q=$lat,$lng",
                        );

                        // 2. Fallback web URL
                        final Uri webUrl = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                        );

                        try {
                          if (await canLaunchUrl(geoUrl)) {
                            await launchUrl(geoUrl);
                          } else {
                            // If native fails, try web link
                            if (await canLaunchUrl(webUrl)) {
                              await launchUrl(
                                webUrl,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              throw 'Could not launch maps';
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not launch maps"),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text("Navigate (Map/Waze)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Action Buttons (Edit/Delete) - Mini styling
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.black45,
                      ),
                      onPressed: () => _editItinerary(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.black45,
                      ),
                      onPressed: () => _deleteItinerary(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getItineraryImage(String title) {
    String lower = title.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('lunch') ||
        lower.contains('dinner')) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000';
    }
    if (lower.contains('hotel') || lower.contains('check-in')) {
      return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1000';
    }
    if (lower.contains('beach')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000';
    }
    if (lower.contains('temple')) {
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1000';
    }

    return 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?q=80&w=1000'; // Default resorty
  }

  // Reusable Location Picker for Edit
  void _editItinerary(int i) {
    final t = TextEditingController(text: itinerary[i].title);
    final ti = TextEditingController(text: itinerary[i].time);
    final n = TextEditingController(text: itinerary[i].note);
    double? selectedLat = itinerary[i].lat;
    double? selectedLng = itinerary[i].lng;
    int selectedDay = itinerary[i].day;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Itinerary"),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day Dropdown
                DropdownButtonFormField<int>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(labelText: "Day"),
                  items: List.generate(widget.trip.days, (index) {
                    int day = index + 1;
                    return DropdownMenuItem(
                      value: day,
                      child: Text("Day $day"),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) setStateSB(() => selectedDay = val);
                  },
                ),
                TextField(
                  controller: t,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: ti,
                  decoration: const InputDecoration(labelText: "Time"),
                ),
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: "Note"),
                ),
                const SizedBox(height: 16),

                // Location Selector
                InkWell(
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initialLocation: selectedLat != null
                              ? LatLng(selectedLat!, selectedLng!)
                              : null,
                        ),
                      ),
                    );

                    if (result != null) {
                      setStateSB(() {
                        selectedLat = result.latitude;
                        selectedLng = result.longitude;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedLat != null
                              ? Icons.location_on
                              : Icons.add_location_alt,
                          color: selectedLat != null ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedLat != null
                                ? "Change Location"
                                : "Pick Location on Map",
                            style: TextStyle(
                              color: selectedLat != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selectedLat != null) ...[
                          Text(
                            "Set",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setStateSB(() {
                                selectedLat = null;
                                selectedLng = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(
                () => itinerary[i] = ItineraryItem(
                  title: t.text,
                  time: ti.text,
                  note: n.text,
                  lat: selectedLat,
                  lng: selectedLng,
                  day: selectedDay,
                ),
              );
              await _saveToFirestore();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteItinerary(int i) async {
    setState(() => itinerary.removeAt(i));
    await _saveToFirestore();
  }

  void _addExpense() {
    final t = TextEditingController();
    final a = TextEditingController();
    String category = 'Other';
    final categories = [
      'Food',
      'Transport',
      'Accommodation',
      'Entertainment',
      'Shopping',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Expense"),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: t,
                  decoration: const InputDecoration(
                    labelText: "Title (e.g. Lunch)",
                  ),
                ),
                TextField(
                  controller: a,
                  decoration: const InputDecoration(labelText: "Amount (RM)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setStateSB(() => category = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(() {
                expenses.add(
                  ExpenseItem(
                    title: t.text,
                    amount: double.tryParse(a.text) ?? 0,
                    category: category,
                  ),
                );
              });
              await _saveToFirestore();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addItinerary() {
    final t = TextEditingController();
    final ti = TextEditingController();
    final n = TextEditingController();
    double? selectedLat;
    double? selectedLng;
    int selectedDay = 1;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Itinerary Item"),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day Dropdown
                DropdownButtonFormField<int>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(labelText: "Day"),
                  items: List.generate(widget.trip.days, (index) {
                    int day = index + 1;
                    return DropdownMenuItem(
                      value: day,
                      child: Text("Day $day"),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) setStateSB(() => selectedDay = val);
                  },
                ),
                TextField(
                  controller: t,
                  decoration: const InputDecoration(
                    labelText: "Title (e.g. Dinner)",
                  ),
                ),
                TextField(
                  controller: ti,
                  decoration: const InputDecoration(
                    labelText: "Time (e.g. 7:00 PM)",
                  ),
                ),
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: "Note"),
                ),
                const SizedBox(height: 16),

                // Location Selector
                InkWell(
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen(),
                      ),
                    );

                    if (result != null) {
                      setStateSB(() {
                        selectedLat = result.latitude;
                        selectedLng = result.longitude;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedLat != null
                              ? Icons.location_on
                              : Icons.add_location_alt,
                          color: selectedLat != null ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedLat != null
                                ? "Location Selected"
                                : "Pick Location on Map",
                            style: TextStyle(
                              color: selectedLat != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selectedLat != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setStateSB(() {
                                selectedLat = null;
                                selectedLng = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(
                () => itinerary.add(
                  ItineraryItem(
                    title: t.text,
                    time: ti.text,
                    note: n.text,
                    lat: selectedLat,
                    lng: selectedLng,
                    day: selectedDay,
                  ),
                ),
              );
              await _saveToFirestore();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ================= BUDGET =================
  Widget _budget() {
    final user = FirebaseAuth.instance.currentUser!;
    final bool isOwner = widget.trip.ownerUid == user.uid;

    // Calculate Total Spent
    final totalSpent = expenses.fold(0.0, (prev, e) => prev + e.amount);
    final remaining = widget.trip.budget - totalSpent;

    // Calculate My Allocations
    double myCost = 0.0;
    final int memberCount = members.isEmpty ? 1 : members.length;

    // Attempt to identify "Me" in the members list.
    // If we can't find exact match, we might fallback or show just split.
    // Based on `_inviteMember`, members list contains Emails.
    final String myId = user.email ?? "";

    for (var e in expenses) {
      String assignedTo =
          widget.trip.categoryAssignments[e.category] ?? 'Split Equally';

      if (assignedTo == 'Split Equally') {
        myCost += e.amount / memberCount;
      } else if (assignedTo == myId) {
        myCost += e.amount;
      }
      // If assigned to someone else, do not add to myCost.
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ===== SUMMARY CARD =====
          // ===== SUMMARY CARD =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Trip Budget Summary",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Total Budget: RM ${widget.trip.budget.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Total Spent: RM ${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Remaining: RM ${remaining.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: remaining >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // ===== MY ESTIMATED COST =====
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "My Cost: RM ${myCost.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isOwner)
                        GestureDetector(
                          onTap: () => _showBudgetSettings(context),
                          child: const Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== EXPENSE LIST =====
          if (expenses.isEmpty)
            Column(
              children: [
                _emptyState(
                  "No expenses recorded. Tap + to add.",
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            )
          else
            ...expenses.map((e) {
              int index = expenses.indexOf(e);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("RM ${e.amount.toStringAsFixed(2)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.black54,
                        ),
                        onPressed: () => _editExpense(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.black26,
                        ),
                        onPressed: () => _deleteExpense(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
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
    final amount = TextEditingController(
      text: expenses[index].amount.toString(),
    );
    String category = expenses[index].category;
    final categories = [
      'Food',
      'Transport',
      'Accommodation',
      'Entertainment',
      'Shopping',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Expense"),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: amount,
                  decoration: const InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setStateSB(() => category = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(() {
                expenses[index] = ExpenseItem(
                  title: title.text,
                  amount: double.tryParse(amount.text) ?? 0,
                  category: category,
                );
              });

              await _saveToFirestore();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ... (keeping implementation details) ...

  // ================= CHECKLIST =================
  Widget _checklist() {
    if (checklist.isEmpty) {
      return Column(children: [_empty("No checklist items. Tap + to add.")]);
    }

    // ... (rest of checklist) ...
    return Column(
      children: checklist.asMap().entries.map((entry) {
        int i = entry.key;
        var item = entry.value;

        return CheckboxListTile(
          value: item.isChecked,
          title: Text(
            item.title,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          onChanged: (v) async {
            setState(() => item.isChecked = v!);
            await _saveToFirestore();
          },
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                onPressed: () => _editChecklist(i),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.black26,
                ),
                onPressed: () => _deleteChecklist(i),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _editChecklist(int i) {
    var t = TextEditingController(text: checklist[i].title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Checklist"),
        content: TextField(controller: t),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(() => checklist[i].title = t.text);
              await _saveToFirestore();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteChecklist(int i) async {
    setState(() => checklist.removeAt(i));
    await _saveToFirestore();
  }

  // ...

  // ================= TASKS =================
  Widget _tasks() {
    if (tasks.isEmpty) {
      return Column(children: [_empty("No tasks. Tap + to add.")]);
    }

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
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                onPressed: () => _editTask(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteTask(i),
              ),
            ],
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              setState(() {
                tasks[i] = TaskItem(
                  title: t.text.trim(),
                  completed: tasks[i].completed, // keep current status
                );
              });

              await _saveToFirestore();
              if (mounted) {
                Navigator.pop(context);
              }
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

  // ================= ADD FORMS =================

  void _inviteMember(BuildContext ctx) {
    // ❗ Check if group is already full
    if (members.length >= widget.trip.travelers) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Group is Full"),
          content: Text(
            "You already have ${members.length} members.\n"
            "Trip pax limit is ${widget.trip.travelers}.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final emailController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Invite Member"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Member Email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              // 🔒 Double safety check (in case of race conditions)
              if (members.length >= widget.trip.travelers) {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Group is Full"),
                    content: Text(
                      "Cannot invite more members.\n"
                      "Pax limit: ${widget.trip.travelers}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              setState(() => members.add(email));

              await FirebaseFirestore.instance
                  .collection("trips")
                  .doc(widget.trip.id)
                  .update({"members": members});

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
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
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (t.text.trim().isNotEmpty) {
                setState(() => checklist.add(ChecklistItem(title: t.text)));
                await _saveToFirestore();
              }
              if (c.mounted) {
                Navigator.pop(c);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= TASKS =================

  // ================= BUDGET SETTINGS =================
  void _showBudgetSettings(BuildContext context) {
    final categories = [
      'Food',
      'Transport',
      'Accommodation',
      'Entertainment',
      'Shopping',
      'Other',
    ];
    final List<String> assignableMembers = ['Split Equally', ...members];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cost Allocation",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Assign responsibility for expense categories. Unassigned categories are split equally.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ...categories.map((cat) {
                    String currentAssignment =
                        widget.trip.categoryAssignments[cat] ?? 'Split Equally';
                    if (!assignableMembers.contains(currentAssignment)) {
                      currentAssignment = 'Split Equally';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: currentAssignment,
                            items: assignableMembers.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m == 'Split Equally'
                                      ? m
                                      : (m.length > 10
                                            ? "${m.substring(0, 8)}..."
                                            : m),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              if (val == null) return;
                              setStateSB(() {
                                widget.trip.categoryAssignments[cat] = val;
                              });
                              setState(() {}); // Ensure parent updates
                              await _saveToFirestore();
                            },
                            underline: Container(),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
