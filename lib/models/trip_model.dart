import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  String id;
  String ownerUid;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final String transport;
  final String accommodation;
  final double budget;

  final List<String> activities;

  final List<ItineraryItem> itinerary;
  final List<ExpenseItem> expenses;
  final List<TaskItem> tasks;
  final List<ChecklistItem> checklist;

  final String groupName;
  final List<String> members;
  final bool isGroup;

  final List<ChatMessage> messages;

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
  })  : checklist = checklist ?? [],
        messages = messages ?? [];

  int get days => endDate.difference(startDate).inDays + 1;

  // ---------------- FIRESTORE SAVE ----------------
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

    'itinerary': itinerary.map((e) => {
      'title': e.title,
      'time': e.time,
      'note': e.note,
    }).toList(),

    'expenses': expenses.map((e) => {
      'title': e.title,
      'amount': e.amount,
    }).toList(),

    'tasks': tasks.map((e) => {
      'title': e.title,
      'completed': e.completed,
    }).toList(),

    'checklist': checklist.map((e) => {
      'title': e.title,
      'isChecked': e.isChecked,
    }).toList(),

    'messages': messages.map((e) => {
      'sender': e.sender,
      'message': e.message,
      'time': e.time.millisecondsSinceEpoch,
    }).toList(),

    'groupName': groupName,
    'members': members,
    'isGroup': isGroup,
  };
}

  // ---------------- FIRESTORE LOAD ----------------
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

    itinerary: const [],
    expenses: const [],
    tasks: const [],
    checklist: const [],
    messages: const [],

    isGroup: json['isGroup'] ?? false,
    groupName: json['groupName'] ?? '',
    members: List<String>.from(json['members'] ?? []),
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
        time: (map['time'] as Timestamp).toDate(),
      );
}

// ================= CHECKLIST =================
class ChecklistItem {
  String title;
  bool isChecked;

  ChecklistItem({
    required this.title,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'isChecked': isChecked,
      };

  static ChecklistItem fromMap(Map<String, dynamic> map) => ChecklistItem(
        title: map['title'],
        isChecked: map['isChecked'],
      );
}

// ================= ITINERARY =================
class ItineraryItem {
  final String title;
  final String time;
  final String note;

  ItineraryItem({
    required this.title,
    required this.time,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'time': time,
        'note': note,
      };

  static ItineraryItem fromMap(Map<String, dynamic> map) => ItineraryItem(
        title: map['title'],
        time: map['time'],
        note: map['note'],
      );
}

// ================= EXPENSE =================
class ExpenseItem {
  final String title;
  final double amount;

  ExpenseItem({
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
      };

  static ExpenseItem fromMap(Map<String, dynamic> map) => ExpenseItem(
        title: map['title'],
        amount: (map['amount'] as num).toDouble(),
      );
}

// ================= TASK =================
class TaskItem {
  final String title;
  bool completed;

  TaskItem({
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'completed': completed,
      };

  static TaskItem fromMap(Map<String, dynamic> map) => TaskItem(
        title: map['title'],
        completed: map['completed'],
      );
}
