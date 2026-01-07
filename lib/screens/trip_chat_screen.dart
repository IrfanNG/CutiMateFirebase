import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

class TripChatScreen extends StatefulWidget {
  final Trip trip;

  const TripChatScreen({super.key, required this.trip});

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color primaryBlue = const Color(0xFF1BA0E2);
  final Color darkNavy = const Color(0xFF1B4E6B);

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // SEND MESSAGE
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final message = _controller.text.trim();
    _controller.clear();

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('messages')
        .add({
      "text": message,
      "senderUid": user.uid,
      "senderName": user.email,
      "timestamp": FieldValue.serverTimestamp(),
      "seenBy": [user.uid], // sender sees it already
    });

    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  // MARK MESSAGES AS SEEN
  Future<void> _markMessagesSeen(List<QueryDocumentSnapshot> docs) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;

      if (data["seenBy"] == null || !(data["seenBy"] as List).contains(uid)) {
        batch.update(d.reference, {
          "seenBy": FieldValue.arrayUnion([uid])
        });
      }
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Color(0xFF1B4E6B)),
        title: Column(
          children: [
            Text('Trip Group Chat',
                style: TextStyle(
                    color: darkNavy, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${widget.trip.destination} • ${widget.trip.travelers} pax',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(child: _messageStream()),
          _inputBar(),
        ],
      ),
    );
  }

  // ================= STREAM =================
  Widget _messageStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("trips")
          .doc(widget.trip.id)
          .collection("messages")
          .orderBy("timestamp", descending: false)
          .snapshots(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // 🔥 Mark seen
        _markMessagesSeen(docs);

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Start the conversation!',
                    style: TextStyle(color: Colors.black38)),
              ],
            ),
          );
        }

        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data["senderUid"] ==
                FirebaseAuth.instance.currentUser!.uid;

            return _chatBubble(
              sender: data["senderName"] ?? "Unknown",
              text: data["text"] ?? "",
              time: (data["timestamp"] as Timestamp?)?.toDate(),
              isMe: isMe,
              seenBy: data["seenBy"] ?? [],
              isLastMine: isMe && index == docs.length - 1,
            );
          },
        );
      },
    );
  }

  // ================= CHAT BUBBLE =================
  Widget _chatBubble({
    required String sender,
    required String text,
    DateTime? time,
    required bool isMe,
    List<dynamic>? seenBy,
    required bool isLastMine,
  }) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isMe && time != null) _time(time),
              const SizedBox(width: 6),
              _bubble(text, isMe),
              const SizedBox(width: 6),
              if (!isMe && time != null) _time(time),
            ],
          ),
        ),

        /// --- SEEN INDICATOR ---
        if (isMe && isLastMine)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _seenText(seenBy),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          )
      ],
    );
  }

  String _seenText(List<dynamic>? seenBy) {
    if (seenBy == null) return "";

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final others = seenBy.where((id) => id != uid).toList();

    if (others.isEmpty) return "Delivered";
    if (others.length == 1) return "Seen";
    return "Seen by ${others.length}";
  }

  Widget _bubble(String text, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : darkNavy,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _time(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour >= 12 ? "PM" : "AM";
    return Text("$hour:$minute $suffix",
        style: const TextStyle(fontSize: 10, color: Colors.grey));
  }

  // ================= INPUT BAR =================
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
