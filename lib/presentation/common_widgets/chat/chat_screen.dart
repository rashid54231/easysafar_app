import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easysafar/data/repositories/chat_repository.dart';
import 'package:easysafar/data/models/message_model.dart';
import 'package:easysafar/presentation/providers/chat_provider.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';

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
  final _scrollController = ScrollController();
  final _chatRepo = ChatRepository();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    context.read<ChatProvider>().markMessagesAsRead(
      tripId: widget.tripId,
      currentUserId: currentUser.id,
      senderId: widget.receiverId,
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty || phoneNumber == "No number") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number is not available"), backgroundColor: Colors.orange),
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      await _chatRepo.sendMessage(
        tripId: widget.tripId,
        senderId: currentUser.id,
        receiverId: widget.receiverId,
        content: text,
      );
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
    final myId = Supabase.instance.client.auth.currentUser?.id ?? "";

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
            Text(
              widget.driverPhone != null && widget.driverPhone!.isNotEmpty
                  ? widget.driverPhone!
                  : "No Number Provided",
              style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _makePhoneCall(widget.driverPhone),
            icon: const Icon(Icons.phone_forwarded_rounded, color: Colors.greenAccent, size: 22),
            tooltip: "Call",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatRepo.streamMessages(
                tripId: widget.tripId,
                userId: myId,
                receiverId: widget.receiverId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Send a message to start chatting!",
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ChatBubble(
                      content: msg.content,
                      isMe: msg.isSentBy(myId),
                      timeAgo: msg.shortTime,
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
