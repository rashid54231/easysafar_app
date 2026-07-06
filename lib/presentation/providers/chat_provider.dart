import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  int _globalUnreadCount = 0;
  StreamSubscription<int>? _subscription;

  int get globalUnreadCount => _globalUnreadCount;

  void init() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _subscribeToUnreadCount(user.id);
  }

  void _subscribeToUnreadCount(String userId) {
    _subscription?.cancel();
    _subscription = _repository.streamGlobalUnreadCount(userId).listen((count) {
      _globalUnreadCount = count;
      notifyListeners();
    });
  }

  Future<void> refreshGlobalUnreadCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _globalUnreadCount = await _repository.getGlobalUnreadCount(user.id);
    notifyListeners();
  }

  Future<void> markMessagesAsRead({
    required String tripId,
    required String currentUserId,
    required String senderId,
  }) async {
    await _repository.markMessagesAsRead(
      tripId: tripId,
      currentUserId: currentUserId,
      senderId: senderId,
    );
    await Future.delayed(const Duration(milliseconds: 300));
    await refreshGlobalUnreadCount();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
