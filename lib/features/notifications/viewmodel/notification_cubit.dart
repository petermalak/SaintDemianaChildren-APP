import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saint_demiana_children/core/services/interface/i_notification_service.dart';
import '../model/notification_model.dart';
import '../repository/i_notification_repository.dart';

part 'notification_state.dart';

/// NotificationCubit
///
/// Manages notification state and business logic.
/// Follows Single Responsibility Principle (SRP) - handles notification state management.
/// Follows Dependency Inversion Principle (DIP) - depends on interfaces.
class NotificationCubit extends Cubit<NotificationState> {
  final INotificationService _notificationService;
  final INotificationRepository _notificationRepository;

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  NotificationCubit(
    this._notificationService,
    this._notificationRepository,
  ) : super(NotificationInitial());

  /// Initialize notification handling
  Future<void> initialize() async {
    try {
      emit(NotificationLoading());

      // Initialize notification service
      await _notificationService.initialize();

      // Get FCM token and update on server
      final token = await _notificationService.getToken();
      if (token != null) {
        await _updateFcmTokenOnServer(token);
      }

      // Listen to token refresh
      _tokenRefreshSubscription = _notificationService.onTokenRefresh.listen(
        (newToken) {
          _updateFcmTokenOnServer(newToken);
        },
      );

      // Listen to foreground messages
      _messageSubscription = _notificationService.onMessageReceived.listen(
        (message) {
          _handleForegroundMessage(message);
        },
      );

      // Listen to messages opened by user
      _messageOpenedSubscription = _notificationService.onMessageOpened.listen(
        (message) {
          _handleMessageOpened(message);
        },
      );

      // Load notifications from local storage
      await loadNotifications();

      emit(NotificationInitialized());
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      emit(NotificationError(
          'Failed to initialize notifications: ${e.toString()}'));
    }
  }

  /// Update FCM token on server
  Future<void> _updateFcmTokenOnServer(String token) async {
    final result = await _notificationRepository.updateFcmToken(token);
    result.fold(
      (error) => debugPrint('❌ Failed to update FCM token on server: $error'),
      (_) => debugPrint('✅ FCM token updated on server'),
    );
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '📬 Handling foreground message: ${message.notification?.title}');

    final notification = _createNotificationFromMessage(message);
    _saveNotification(notification);

    // Emit new notification received event
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      emit(NotificationLoaded(
        notifications: [notification, ...currentState.notifications],
        unreadCount: currentState.unreadCount + 1,
      ));
    }
  }

  /// Handle message opened by user
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('📬 Handling message opened: ${message.notification?.title}');

    final notification = _createNotificationFromMessage(message);
    _saveNotification(notification);

    // You can navigate to specific screen based on notification data
    // For example: if (notification.type == NotificationType.attendance) { ... }
  }

  /// Create NotificationModel from RemoteMessage
  NotificationModel _createNotificationFromMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
      receivedAt: DateTime.now(),
      isRead: false,
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      type: NotificationType.fromString(message.data['type'] ?? 'general'),
    );
  }

  /// Save notification to local storage
  Future<void> _saveNotification(NotificationModel notification) async {
    await _notificationRepository.saveNotification(notification);
  }

  /// Load notifications from local storage
  Future<void> loadNotifications() async {
    try {
      emit(NotificationLoading());

      final notificationsResult =
          await _notificationRepository.getNotifications();
      final unreadCountResult = await _notificationRepository.getUnreadCount();

      notificationsResult.fold(
        (error) {
          debugPrint('❌ Failed to load notifications: $error');
          emit(NotificationError('Failed to load notifications: $error'));
        },
        (notifications) {
          unreadCountResult.fold(
            (error) {
              debugPrint('❌ Failed to load unread count: $error');
              emit(NotificationLoaded(
                notifications: notifications,
                unreadCount: 0,
              ));
            },
            (unreadCount) {
              emit(NotificationLoaded(
                notifications: notifications,
                unreadCount: unreadCount,
              ));
            },
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      emit(NotificationError('Failed to load notifications: ${e.toString()}'));
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final result = await _notificationRepository.markAsRead(notificationId);

      result.fold(
        (error) {
          debugPrint('❌ Failed to mark notification as read: $error');
        },
        (_) {
          // Reload notifications to update UI
          loadNotifications();
        },
      );
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final result = await _notificationRepository.markAllAsRead();

      result.fold(
        (error) {
          debugPrint('❌ Failed to mark all notifications as read: $error');
          emit(NotificationError(
              'Failed to mark all notifications as read: $error'));
        },
        (_) {
          // Reload notifications to update UI
          loadNotifications();
        },
      );
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      emit(NotificationError(
          'Failed to mark all notifications as read: ${e.toString()}'));
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final result =
          await _notificationRepository.deleteNotification(notificationId);

      result.fold(
        (error) {
          debugPrint('❌ Failed to delete notification: $error');
          emit(NotificationError('Failed to delete notification: $error'));
        },
        (_) {
          // Reload notifications to update UI
          loadNotifications();
        },
      );
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      emit(NotificationError('Failed to delete notification: ${e.toString()}'));
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final result = await _notificationRepository.deleteAllNotifications();

      result.fold(
        (error) {
          debugPrint('❌ Failed to delete all notifications: $error');
          emit(NotificationError('Failed to delete all notifications: $error'));
        },
        (_) {
          emit(const NotificationLoaded(
            notifications: [],
            unreadCount: 0,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
      emit(NotificationError(
          'Failed to delete all notifications: ${e.toString()}'));
    }
  }

  /// Cleanup when logging out
  Future<void> cleanup() async {
    try {
      // Remove FCM token from server
      await _notificationRepository.removeFcmToken();

      // Cancel subscriptions
      await _messageSubscription?.cancel();
      await _messageOpenedSubscription?.cancel();
      await _tokenRefreshSubscription?.cancel();

      // Clear local notifications
      await _notificationRepository.deleteAllNotifications();

      emit(NotificationInitial());
    } catch (e) {
      debugPrint('❌ Error cleaning up notifications: $e');
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}
