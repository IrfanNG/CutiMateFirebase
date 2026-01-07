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
    });

    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
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
                    color: darkNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
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

  // ================= REALTIME MESSAGE STREAM =================
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
            );
          },
        );
      },
    );
  }

  // ================= CHAT BUBBLE =================
  Widget _chatBubble(
      {required String sender,
      required String text,
      DateTime? time,
      required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(sender,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: darkNavy.withOpacity(0.7))),
            ),

          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isMe && time != null) _time(time),
              const SizedBox(width: 6),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: isMe ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft:
                        Radius.circular(isMe ? 20 : 4),
                    bottomRight:
                        Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                      color: isMe ? Colors.white : darkNavy,
                      fontSize: 15),
                ),
              ),

              const SizedBox(width: 6),
              if (!isMe && time != null) _time(time),
            ],
          )
        ],
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

  // ================= INPUT =================
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
