import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class ChatRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<MessageModel>> streamMessages({
    required String tripId,
    required String userId,
    required String receiverId,
  }) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      final filtered = data.where((m) {
        final isThisTrip = m['trip_id'].toString() == tripId;
        final involvesMe = (m['sender_id'] == userId && m['receiver_id'] == receiverId) ||
            (m['sender_id'] == receiverId && m['receiver_id'] == userId);
        return isThisTrip && involvesMe;
      }).toList();
      return filtered.map((json) => MessageModel.fromJson(json)).toList();
    });
  }

  Future<void> sendMessage({
    required String tripId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'trip_id': tripId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
    });
  }

  Future<void> markMessagesAsRead({
    required String tripId,
    required String currentUserId,
    required String senderId,
  }) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('trip_id', tripId)
        .eq('sender_id', senderId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
  }

  Stream<int> streamGlobalUnreadCount(String currentUserId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .order('created_at', ascending: false)
        .map((data) {
      final unread = data.where((m) => m['is_read'] == false);
      return unread.length;
    });
  }

  Future<Map<String, dynamic>?> getLastMessage({
    required String tripId,
    required String userId,
    required String otherUserId,
  }) async {
    final data = await _client
        .from('messages')
        .select('content, created_at, sender_id')
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .limit(10);

    final filtered = data.where((m) {
      return (m['sender_id'] == userId && m['receiver_id'] == otherUserId) ||
          (m['sender_id'] == otherUserId && m['receiver_id'] == userId);
    }).toList();

    return filtered.isNotEmpty ? filtered.first : null;
  }

  Future<int> getGlobalUnreadCount(String currentUserId) async {
    final data = await _client
        .from('messages')
        .select('id')
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
    return data.length;
  }

  Future<int> getUnreadCountForConversation({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final data = await _client
        .from('messages')
        .select('id')
        .eq('trip_id', tripId)
        .eq('sender_id', otherUserId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
    return data.length;
  }
}
