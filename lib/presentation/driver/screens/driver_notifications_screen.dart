import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() => _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  IconData _getNotificationIcon(dynamic notification) {
    if (notification.isBookingRequest) return Icons.person_add_rounded;
    if (notification.isBookingConfirmed) return Icons.check_circle_rounded;
    if (notification.isBookingRejected) return Icons.cancel_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(dynamic notification) {
    if (notification.isBookingRequest) return const Color(0xFFFFB74D);
    if (notification.isBookingConfirmed) return const Color(0xFF00D4AA);
    if (notification.isBookingRejected) return const Color(0xFFFF5252);
    return const Color(0xFF5A7A9A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1624),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFFE8F0FE),
          ),
        ),
        backgroundColor: const Color(0xFF0F1624),
        foregroundColor: const Color(0xFFE8F0FE),
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            );
          }

          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 44,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Notifications Yet",
                    style: TextStyle(
                      color: Color(0xFFE8F0FE),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Booking requests and updates will appear here",
                    style: TextStyle(
                      color: Color(0xFF5A7A9A),
                      fontSize: 13,
                    ),
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
                  color: notification.isRead
                      ? const Color(0xFF16213A)
                      : const Color(0xFF1A2740),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification.isRead
                        ? const Color(0xFF2C3E52)
                        : iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: notification.isRead
                          ? const Color(0xFF8A9BB5)
                          : const Color(0xFFE8F0FE),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: notification.isRead
                            ? const Color(0xFF4A5A72)
                            : const Color(0xFF5A7A9A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: notification.isRead
                          ? const Color(0xFF4A5A72)
                          : const Color(0xFF5A7A9A),
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

