import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String tripId;
  final String receiverId;
  final String receiverName;
  final String? driverPhone;

  const ChatScreen({
    super.key,
    required this.tripId,
    required this.receiverId,
    required this.receiverName,
    this.driverPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // --- PHONE CALL LOGIC ---
  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty || phoneNumber == "No number") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver's phone number is not available"), backgroundColor: Colors.orange),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.trim());
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open dialer: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- SEND MESSAGE LOGIC ---
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      // 'content' column use ho raha hai aapki database table ke mutabiq
      await _supabase.from('messages').insert({
        'trip_id': widget.tripId,
        'sender_id': currentUser.id,
        'receiver_id': widget.receiverId,
        'content': text,
        'is_read': false,
      });

      _messageController.clear();
    } catch (e) {
      debugPrint("Send error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            // DRIVER NUMBER DISPLAY: Ab passenger ko screen par number hamesha dikhega
            Text(
                widget.driverPhone != null && widget.driverPhone!.isNotEmpty
                    ? "📞 ${widget.driverPhone}"
                    : "📱 No Number Provided",
                style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        actions: [
          // CALL BUTTON: Is par click karte hi call lag jayegi
          IconButton(
            onPressed: () => _makePhoneCall(widget.driverPhone),
            icon: const Icon(Icons.phone_forwarded_rounded, color: Colors.greenAccent, size: 22),
            tooltip: "Call Driver",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. Realtime Messages Section
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Filter logic to get current chat flow
                final allMessages = snapshot.data!.where((m) {
                  bool isThisTrip = m['trip_id'].toString() == widget.tripId.toString();
                  bool involvesMe = (m['sender_id'] == myId && m['receiver_id'] == widget.receiverId) ||
                      (m['sender_id'] == widget.receiverId && m['receiver_id'] == myId);
                  return isThisTrip && involvesMe;
                }).toList();

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Text(
                        "Driver se baat karne ke liye 'Hi' bhejiye! 👋",
                        style: TextStyle(color: Colors.white54, fontSize: 15)
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(15),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final bool isMe = msg['sender_id'] == myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[700] : const Color(0xFF1C2331),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          msg['content'] ?? "", // Using database structure target mapping 'content'
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Message Input Textfield Box Layout
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1C2331),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.cyanAccent,
                  radius: 22,
                  child: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1117)),
                  )
                      : IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Color(0xFF0D1117), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}