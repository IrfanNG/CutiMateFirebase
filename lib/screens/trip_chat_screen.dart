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

  final Color primaryYellow = const Color(0xFFFFC107); // Amber/Yellow
  final Color bgLight = const Color(0xFFF6F7F9);
  final Color darkNavy = const Color(0xFF111827);

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
          "seenBy": [user.uid],
        });

    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  // MARK SEEN
  Future<void> _markMessagesSeen(List<QueryDocumentSnapshot> docs) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data["seenBy"] == null || !(data["seenBy"] as List).contains(uid)) {
        batch.update(d.reference, {
          "seenBy": FieldValue.arrayUnion([uid]),
        });
      }
    }
    await batch.commit();
  }

  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(child: _messageStream()),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ================= CUSTOM HEADER =================
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),

          // Title Info
          Column(
            children: [
              Text(
                'Group Chat',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.trip.destination} • ${widget.trip.travelers} Members',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Right spacing
          const SizedBox(width: 44),
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
        _markMessagesSeen(docs);

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Start the conversation!",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe =
                data["senderUid"] == FirebaseAuth.instance.currentUser!.uid;

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
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    sender.isNotEmpty ? sender[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? primaryYellow : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      sender,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: darkNavy, // Dark text for contrast
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: isMe
              ? const EdgeInsets.only(right: 0)
              : const EdgeInsets.only(left: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (time != null)
                Text(
                  _formatTime(time),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              if (isMe && isLastMine) ...[
                const SizedBox(width: 4),
                Text(
                  " • ${_seenText(seenBy)}",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $suffix";
  }

  String _seenText(List<dynamic>? seenBy) {
    if (seenBy == null) return "";
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final others = seenBy.where((id) => id != uid).toList();
    if (others.isEmpty) return "Sent";
    if (others.length == 1) return "Seen";
    return "Seen by ${others.length}";
  }

  // ================= INPUT AREA =================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                cursorColor: Colors.black54,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFFFF8E1), // Pale Yellow
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107), // Yellow Button
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66FFC107),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
