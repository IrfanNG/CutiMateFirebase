import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  String id;
  String ownerUid;
  String title;
  String destination;
  DateTime startDate;
  DateTime endDate;
  int travelers;
  String transport;
  String accommodation;
  double budget;

  final List<String> activities;

  final List<ItineraryItem> itinerary;
  final List<ExpenseItem> expenses;
  final List<TaskItem> tasks;
  final List<ChecklistItem> checklist;

  final String groupName;
  final List<String> members;
  final bool isGroup;

  final List<ChatMessage> messages;

  // Cost Allocation
  final Map<String, String>
  categoryAssignments; // Key: Category, Value: MemberName or "SPLIT"

  Trip({
    this.id = '',
    required this.ownerUid,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.transport,
    required this.accommodation,
    required this.budget,
    required this.activities,
    required this.groupName,
    required this.members,
    required this.isGroup,
    required this.itinerary,
    required this.expenses,
    required this.tasks,
    List<ChecklistItem>? checklist,
    List<ChatMessage>? messages,
    Map<String, String>? categoryAssignments,
  }) : checklist = checklist ?? [],
       messages = messages ?? [],
       categoryAssignments = categoryAssignments ?? {};

  int get days => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    String? id,
    String? ownerUid,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    String? transport,
    String? accommodation,
    double? budget,
    List<String>? activities,
    List<ItineraryItem>? itinerary,
    List<ExpenseItem>? expenses,
    List<TaskItem>? tasks,
    List<ChecklistItem>? checklist,
    String? groupName,
    List<String>? members,
    bool? isGroup,
    List<ChatMessage>? messages,
    Map<String, String>? categoryAssignments,
  }) {
    return Trip(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelers: travelers ?? this.travelers,
      transport: transport ?? this.transport,
      accommodation: accommodation ?? this.accommodation,
      budget: budget ?? this.budget,
      activities: activities ?? this.activities,
      itinerary: itinerary ?? this.itinerary,
      expenses: expenses ?? this.expenses,
      tasks: tasks ?? this.tasks,
      checklist: checklist ?? this.checklist,
      groupName: groupName ?? this.groupName,
      members: members ?? this.members,
      isGroup: isGroup ?? this.isGroup,
      messages: messages ?? this.messages,
      categoryAssignments: categoryAssignments ?? this.categoryAssignments,
    );
  }

  // ---------------- SAVE TO FIRESTORE ----------------
  Map<String, dynamic> toJson() {
    return {
      'ownerUid': ownerUid,
      'title': title,
      'destination': destination,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'travelers': travelers,
      'transport': transport,
      'accommodation': accommodation,
      'budget': budget,
      'activities': activities,

      'itinerary': itinerary.map((e) => e.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'checklist': checklist.map((e) => e.toMap()).toList(),
      'messages': messages.map((e) => e.toMap()).toList(),

      'groupName': groupName,
      'members': members,
      'isGroup': isGroup,
      'categoryAssignments': categoryAssignments,
    };
  }

  // ---------------- LOAD FROM FIRESTORE ----------------
  factory Trip.fromJson(String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return Trip(
      id: id,
      ownerUid: json['ownerUid'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      travelers: json['travelers'] ?? 1,
      transport: json['transport'] ?? '',
      accommodation: json['accommodation'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      activities: List<String>.from(json['activities'] ?? []),

      itinerary: (json['itinerary'] as List<dynamic>? ?? [])
          .map((e) => ItineraryItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((e) => TaskItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      checklist: (json['checklist'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      categoryAssignments: Map<String, String>.from(
        json['categoryAssignments'] ?? {},
      ),
    );
  }
}

// ================= CHAT =================
class ChatMessage {
  final String sender;
  final String message;
  final DateTime time;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
    'sender': sender,
    'message': message,
    'time': Timestamp.fromDate(time),
  };

  static ChatMessage fromMap(Map<String, dynamic> map) => ChatMessage(
    sender: map['sender'],
    message: map['message'],
    time: (map['time'] is Timestamp)
        ? (map['time'] as Timestamp).toDate()
        : DateTime.fromMillisecondsSinceEpoch(map['time']),
  );
}

// ================= CHECKLIST =================
class ChecklistItem {
  String title;
  bool isChecked;

  ChecklistItem({required this.title, this.isChecked = false});

  Map<String, dynamic> toMap() => {'title': title, 'isChecked': isChecked};

  static ChecklistItem fromMap(Map<String, dynamic> map) =>
      ChecklistItem(title: map['title'], isChecked: map['isChecked'] ?? false);
}

// ================= ITINERARY =================
class ItineraryItem {
  final String title;
  final String time;
  final String note;
  final double? lat;
  final double? lng;
  final int day; // Added day field

  ItineraryItem({
    required this.title,
    required this.time,
    required this.note,
    this.lat,
    this.lng,
    this.day = 1, // Default to Day 1
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'time': time,
    'note': note,
    'lat': lat,
    'lng': lng,
    'day': day,
  };

  static ItineraryItem fromMap(Map<String, dynamic> map) => ItineraryItem(
    title: map['title'],
    time: map['time'],
    note: map['note'],
    lat: map['lat'],
    lng: map['lng'],
    day: map['day'] ?? 1,
  );
}

// ================= EXPENSE =================
// ================= EXPENSE =================
class ExpenseItem {
  final String title;
  final double amount;
  final String category; // New field

  ExpenseItem({
    required this.title,
    required this.amount,
    this.category = 'Other',
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'category': category,
  };

  static ExpenseItem fromMap(Map<String, dynamic> map) => ExpenseItem(
    title: map['title'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'] ?? 'Other',
  );
}

// ================= TASK =================
class TaskItem {
  final String title;
  bool completed;

  TaskItem({required this.title, this.completed = false});

  Map<String, dynamic> toMap() => {'title': title, 'completed': completed};

  static TaskItem fromMap(Map<String, dynamic> map) =>
      TaskItem(title: map['title'], completed: map['completed'] ?? false);
}
