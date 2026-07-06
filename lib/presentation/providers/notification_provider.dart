import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  final bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void init() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _subscribeToNotifications(user.id);
  }

  void _subscribeToNotifications(String userId) {
    _subscription?.cancel();
    _subscription = _repository.streamNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.isRead).length;
      notifyListeners();
    });
  }

  Future<void> refreshUnreadCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _unreadCount = await _repository.getUnreadCount(user.id);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _repository.markAllAsRead(user.id);
    _unreadCount = 0;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          userId: _notifications[i].userId,
          title: _notifications[i].title,
          message: _notifications[i].message,
          isRead: true,
          createdAt: _notifications[i].createdAt,
        );
      }
    }
    notifyListeners();
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _repository.sendNotification(userId: userId, title: title, message: message);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
