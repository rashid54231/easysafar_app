import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easysafar/presentation/common_widgets/chat/chat_screen.dart';

class DriverChatListScreen extends StatelessWidget {
  const DriverChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1624),
      appBar: AppBar(
        title: const Text(
          "Passenger Chats",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFFE8F0FE)),
        ),
        backgroundColor: const Color(0xFF0F1624),
        foregroundColor: const Color(0xFFE8F0FE),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('trips')
            .select('id')
            .eq('driver_id', driverId),
        builder: (context, tripSnapshot) {
          if (!tripSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final driverTripIds = tripSnapshot.data!.map((t) => t['id'].toString()).toList();

          if (driverTripIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Color(0xFF00D4AA)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Trips Yet",
                    style: TextStyle(color: Color(0xFFE8F0FE), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Create a trip to start receiving bookings",
                    style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('bookings')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allBookings = snapshot.data!;
              final myPassengerBookings = allBookings.where((b) {
                return driverTripIds.contains(b['trip_id'].toString());
              }).toList();

              if (myPassengerBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF00D4AA)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No Bookings Yet",
                        style: TextStyle(color: Color(0xFFE8F0FE), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Passenger bookings will appear here",
                        style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              final uniquePassengers = <String, Map<String, dynamic>>{};
              for (final booking in myPassengerBookings) {
                final key = '${booking['passenger_id']}_${booking['trip_id']}';
                if (!uniquePassengers.containsKey(key)) {
                  uniquePassengers[key] = booking;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: uniquePassengers.length,
                itemBuilder: (context, index) {
                  final booking = uniquePassengers.values.elementAt(index);
                  final passengerId = booking['passenger_id'];
                  final tripId = booking['trip_id'].toString();
                  String passengerPhone = booking['passenger_phone']?.toString() ?? "No number";

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: Supabase.instance.client
                        .from('profiles')
                        .select('full_name, phone_number, avatar_url')
                        .eq('id', passengerId)
                        .maybeSingle(),
                    builder: (context, profileSnapshot) {
                      String displayName = "Passenger";
                      String? avatarUrl;

                      if (profileSnapshot.hasData && profileSnapshot.data != null) {
                        displayName = profileSnapshot.data!['full_name'] ?? "Passenger";
                        avatarUrl = profileSnapshot.data!['avatar_url'];
                        if (passengerPhone == "No number" && profileSnapshot.data!['phone_number'] != null) {
                          passengerPhone = profileSnapshot.data!['phone_number'].toString();
                        }
                      }

                      return _DriverChatListItem(
                        tripId: tripId,
                        driverId: driverId,
                        passengerId: passengerId,
                        displayName: displayName,
                        phone: passengerPhone,
                        avatarUrl: avatarUrl,
                        pickupLocation: booking['pickup_location'],
                      );
                    },
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

class _DriverChatListItem extends StatefulWidget {
  final String tripId;
  final String driverId;
  final String passengerId;
  final String displayName;
  final String phone;
  final String? avatarUrl;
  final String? pickupLocation;

  const _DriverChatListItem({
    required this.tripId,
    required this.driverId,
    required this.passengerId,
    required this.displayName,
    required this.phone,
    this.avatarUrl,
    this.pickupLocation,
  });

  @override
  State<_DriverChatListItem> createState() => _DriverChatListItemState();
}

class _DriverChatListItemState extends State<_DriverChatListItem> {
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
        .eq('receiver_id', widget.driverId)
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
        return (m['sender_id'] == widget.driverId && m['receiver_id'] == widget.passengerId) ||
            (m['sender_id'] == widget.passengerId && m['receiver_id'] == widget.driverId);
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
          .eq('sender_id', widget.passengerId)
          .eq('receiver_id', widget.driverId)
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3E52), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1E2A3A),
          backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
          child: widget.avatarUrl == null
              ? const Icon(Icons.person, color: Color(0xFF5A7A9A))
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.displayName,
                style: const TextStyle(
                  color: Color(0xFFE8F0FE),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_lastMessageTime != null)
              Text(
                _lastMessageTime!,
                style: TextStyle(
                  color: _unreadCount > 0 ? const Color(0xFF00D4AA) : const Color(0xFF5A7A9A),
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
              if (widget.pickupLocation != null) ...[
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF5A7A9A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.pickupLocation!,
                    style: const TextStyle(color: Color(0xFF5A7A9A), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    _lastMessage ?? "No messages yet",
                    style: TextStyle(
                      color: _unreadCount > 0 ? const Color(0xFFE8F0FE) : const Color(0xFF5A7A9A),
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
                    color: Color(0xFF00D4AA),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Color(0xFF0F1624),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF5A7A9A)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                tripId: widget.tripId,
                receiverId: widget.passengerId,
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
