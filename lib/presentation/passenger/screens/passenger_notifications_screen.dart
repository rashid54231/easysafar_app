import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class PassengerNotificationsScreen extends StatefulWidget {
  const PassengerNotificationsScreen({super.key});

  @override
  State<PassengerNotificationsScreen> createState() => _PassengerNotificationsScreenState();
}

class _PassengerNotificationsScreenState extends State<PassengerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  IconData _getNotificationIcon(dynamic notification) {
    if (notification.isBookingConfirmed) return Icons.check_circle_rounded;
    if (notification.isBookingRejected) return Icons.cancel_rounded;
    if (notification.isBookingRequest) return Icons.person_add_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(dynamic notification) {
    if (notification.isBookingConfirmed) return const Color(0xFF00D4AA);
    if (notification.isBookingRejected) return const Color(0xFFFF5252);
    if (notification.isBookingRequest) return const Color(0xFFFFB74D);
    return const Color(0xFF5A7A9A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Booking updates will appear here",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final iconColor = _getNotificationColor(notification);
              final icon = _getNotificationIcon(notification);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      notification.isRead
                          ? const Color(0xFF1C2331)
                          : const Color(0xFF1E2A3A),
                      const Color(0xFF0D1117),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: notification.isRead
                        ? Colors.white.withOpacity(0.05)
                        : iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: notification.isRead
                          ? Colors.white60
                          : Colors.white,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.isRead ? Colors.white38 : Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: notification.isRead ? Colors.white30 : Colors.white54,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
