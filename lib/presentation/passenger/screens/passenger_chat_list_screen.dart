import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easysafar/presentation/common_widgets/chat/chat_screen.dart';

class PassengerChatListScreen extends StatelessWidget {
  const PassengerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('passenger_id', myId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final myBookings = snapshot.data!;
          if (myBookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    "No bookings yet",
                    style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Book a ride to chat with your driver",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final uniqueTripIds = myBookings.map((b) => b['trip_id'].toString()).toSet().toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 15),
            itemCount: uniqueTripIds.length,
            itemBuilder: (context, index) {
              final currentTripId = uniqueTripIds[index];

              return FutureBuilder<Map<String, dynamic>?>(
                future: Supabase.instance.client
                    .from('trips')
                    .select('id, driver_id, driver_name, driver_phone, profiles:driver_id(full_name, phone_number, avatar_url)')
                    .eq('id', currentTripId)
                    .maybeSingle(),
                builder: (context, tripSnapshot) {
                  if (!tripSnapshot.hasData || tripSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final tripData = tripSnapshot.data!;
                  final driverProfile = tripData['profiles'] as Map<String, dynamic>?;

                  String driverName = tripData['driver_name'] ?? driverProfile?['full_name'] ?? "Driver";

                  String driverPhone = "No number";
                  if (tripData['driver_phone'] != null && tripData['driver_phone'].toString().trim().isNotEmpty) {
                    driverPhone = tripData['driver_phone'].toString();
                  } else if (driverProfile != null && driverProfile['phone_number'] != null) {
                    driverPhone = driverProfile['phone_number'].toString();
                  }

                  String? avatarUrl = driverProfile?['avatar_url'];
                  String driverUid = tripData['driver_id'].toString();

                  return _ChatListItem(
                    tripId: currentTripId,
                    userId: myId,
                    otherUserId: driverUid,
                    displayName: driverName,
                    phone: driverPhone,
                    avatarUrl: avatarUrl,
                    isDriver: false,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatefulWidget {
  final String tripId;
  final String userId;
  final String otherUserId;
  final String displayName;
  final String phone;
  final String? avatarUrl;
  final bool isDriver;

  const _ChatListItem({
    required this.tripId,
    required this.userId,
    required this.otherUserId,
    required this.displayName,
    required this.phone,
    this.avatarUrl,
    required this.isDriver,
  });

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem> {
  String? _lastMessage;
  String? _lastMessageTime;
  int _unreadCount = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadLastMessage();
    _loadUnreadCount();
    _listenToMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToMessages() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', widget.userId)
        .order('created_at', ascending: false)
        .listen((_) {
      _loadUnreadCount();
      _loadLastMessage();
    });
  }

  Future<void> _loadLastMessage() async {
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select('content, created_at, sender_id')
          .eq('trip_id', widget.tripId)
          .order('created_at', ascending: false)
          .limit(10);

      final filtered = data.where((m) {
        return (m['sender_id'] == widget.userId && m['receiver_id'] == widget.otherUserId) ||
            (m['sender_id'] == widget.otherUserId && m['receiver_id'] == widget.userId);
      }).toList();

      if (filtered.isNotEmpty && mounted) {
        final msg = filtered.first;
        final createdAt = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
        final diff = DateTime.now().difference(createdAt);
        String timeStr;
        if (diff.inMinutes < 60) {
          timeStr = '${diff.inMinutes}m';
        } else if (diff.inHours < 24) {
          timeStr = '${diff.inHours}h';
        } else {
          timeStr = '${diff.inDays}d';
        }
        setState(() {
          _lastMessage = msg['content'];
          _lastMessageTime = timeStr;
        });
      }
    } catch (e) {
      debugPrint("Last message error: $e");
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('trip_id', widget.tripId)
          .eq('sender_id', widget.otherUserId)
          .eq('receiver_id', widget.userId)
          .eq('is_read', false);
      if (mounted) {
        setState(() => _unreadCount = data.length);
      }
    } catch (e) {
      debugPrint("Unread count error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C2331),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[900],
          backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
          child: widget.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.displayName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_lastMessageTime != null)
              Text(
                _lastMessageTime!,
                style: TextStyle(
                  color: _unreadCount > 0 ? Colors.cyanAccent : Colors.white38,
                  fontSize: 11,
                  fontWeight: _unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _lastMessage ?? "No messages yet",
                  style: TextStyle(
                    color: _unreadCount > 0 ? Colors.white70 : Colors.white38,
                    fontSize: 13,
                    fontWeight: _unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Color(0xFF0D1117),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                tripId: widget.tripId,
                receiverId: widget.otherUserId,
                receiverName: widget.displayName,
                driverPhone: widget.phone == "No number" ? null : widget.phone,
              ),
            ),
          ).then((_) {
            _loadUnreadCount();
            _loadLastMessage();
          });
        },
      ),
    );
  }
}
