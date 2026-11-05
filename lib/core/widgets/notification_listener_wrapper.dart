import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../di/service_locator.dart';
import '../services/interface/i_notification_service.dart';
import '../services/local_notification_service.dart';
import '../../features/notifications/model/notification_model.dart';
import '../../features/notifications/repository/i_notification_repository.dart';

/// NotificationListenerWrapper
///
/// Wraps the app to listen for notifications and save them to state.
/// Uses ONLY system notifications - clean and native Android experience.
/// Integrates with state management (BLoC) for notification history.
class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;

  const NotificationListenerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends State<NotificationListenerWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  Future<void> _setupNotificationListener() async {
    if (_isInitialized) return;

    try {
      // Initialize local notification service for system notifications
      await LocalNotificationService.instance.initialize();

      // Get notification service
      final notificationService = sl<INotificationService>();

      // Listen to foreground messages - show system notification
      notificationService.onMessageReceived.listen((message) {
        debugPrint('📬 Notification received, showing system notification...');
        if (mounted) {
          _handleNotification(message);
        }
      });

      // Listen to notification opened (background/terminated)
      notificationService.onMessageOpened.listen((message) {
        debugPrint('📬 Notification opened from background/terminated');
        if (mounted) {
          _handleNotificationOpened(message);
        }
      });

      _isInitialized = true;
      debugPrint('✅ Global notification listener initialized');
    } catch (e) {
      debugPrint('❌ Error setting up notification listener: $e');
    }
  }

  /// Handle notification - show system notification and save to state
  void _handleNotification(RemoteMessage message) {
    if (message.notification == null) return;

    // Save notification to repository (state management)
    _saveNotificationToState(message);

    // Show system notification (works in all states)
    LocalNotificationService.instance.showNotification(message);
    debugPrint('✅ System notification displayed');
  }

  /// Handle notification opened from background/terminated
  void _handleNotificationOpened(RemoteMessage message) {
    // Save notification to repository
    _saveNotificationToState(message);

    // Navigate to appropriate screen based on type
    _navigateToNotification(message);
  }

  /// Save notification to state (repository pattern with state management)
  void _saveNotificationToState(RemoteMessage message) {
    try {
      final notificationRepository = sl<INotificationRepository>();

      final notification = NotificationModel(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        data: message.data,
        receivedAt: DateTime.now(),
        isRead: false,
        imageUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
        type: NotificationType.fromString(message.data['type'] ?? 'general'),
      );

      // Save to repository - accessible via NotificationCubit
      notificationRepository.saveNotification(notification);
      debugPrint('✅ Notification saved to state');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  /// Navigate based on notification type (optional - implement as needed)
  void _navigateToNotification(RemoteMessage message) {
    final type = message.data['type'];

    // You can implement navigation logic here based on your needs
    switch (type) {
      case 'feed':
        debugPrint('📍 Feed notification - User can view in Feeds tab');
        // Feed notifications don't require navigation
        // User will see the new feed when they open the Feeds tab
        break;
      case 'attendance':
        debugPrint('📍 Can navigate to attendance screen');
        // Uncomment when you want navigation:
        // context.go('/attendance');
        break;
      case 'eftekad':
        debugPrint('📍 Can navigate to eftekad screen');
        // context.go('/eftekad');
        break;
      case 'class_update':
        debugPrint('📍 Can navigate to class screen');
        // context.go('/classes');
        break;
      default:
        debugPrint('📍 Can navigate to notifications list');
      // context.go('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
