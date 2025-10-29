import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:saint_demiana_children/core/services/interface/i_api_service.dart';
import '../model/notification_model.dart';
import 'i_notification_repository.dart';

/// NotificationRepository
///
/// Concrete implementation of INotificationRepository.
/// Follows Single Responsibility Principle (SRP) - handles notification data operations.
/// Follows Dependency Inversion Principle (DIP) - depends on abstractions (interfaces).
class NotificationRepository implements INotificationRepository {
  final IApiService _apiService;

  static const String _notificationsBoxKey = 'notifications';
  static const String _notificationsListKey = 'notifications_list';

  NotificationRepository(this._apiService);

  /// Update FCM token on the server
  @override
  Future<Either<String, void>> updateFcmToken(String fcmToken) async {
    try {
      final response = await _apiService.put(
        path: '/notifications/token',
        body: {'fcmToken': fcmToken},
      );

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        return Left(
          response.data['message'] ?? 'Failed to update FCM token',
        );
      }
    } catch (e) {
      return Left('Error updating FCM token: ${e.toString()}');
    }
  }

  /// Remove FCM token from the server (on logout)
  @override
  Future<Either<String, void>> removeFcmToken() async {
    try {
      final response = await _apiService.delete(
        path: '/notifications/token',
      );

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        return Left(
          response.data['message'] ?? 'Failed to remove FCM token',
        );
      }
    } catch (e) {
      return Left('Error removing FCM token: ${e.toString()}');
    }
  }

  /// Get all notifications (from local storage)
  @override
  Future<Either<String, List<NotificationModel>>> getNotifications() async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []);

      final notifications = (notificationsJson as List)
          .map((json) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Sort by received date (newest first)
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      return Right(notifications);
    } catch (e) {
      return Left('Error loading notifications: ${e.toString()}');
    }
  }

  /// Save notification to local storage
  @override
  Future<Either<String, void>> saveNotification(
    NotificationModel notification,
  ) async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []) as List;

      // Check if notification already exists
      final existingIndex = notificationsJson.indexWhere(
        (json) => json['id'] == notification.id,
      );

      if (existingIndex != -1) {
        // Update existing notification
        notificationsJson[existingIndex] = notification.toJson();
      } else {
        // Add new notification
        notificationsJson.insert(0, notification.toJson());
      }

      // Keep only last 100 notifications
      if (notificationsJson.length > 100) {
        notificationsJson.removeRange(100, notificationsJson.length);
      }

      await box.put(_notificationsListKey, notificationsJson);
      return const Right(null);
    } catch (e) {
      return Left('Error saving notification: ${e.toString()}');
    }
  }

  /// Mark notification as read
  @override
  Future<Either<String, void>> markAsRead(String notificationId) async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []) as List;

      final index = notificationsJson.indexWhere(
        (json) => json['id'] == notificationId,
      );

      if (index != -1) {
        final notification = NotificationModel.fromJson(
          Map<String, dynamic>.from(notificationsJson[index]),
        );
        notificationsJson[index] = notification.copyWith(isRead: true).toJson();
        await box.put(_notificationsListKey, notificationsJson);
      }

      return const Right(null);
    } catch (e) {
      return Left('Error marking notification as read: ${e.toString()}');
    }
  }

  /// Mark all notifications as read
  @override
  Future<Either<String, void>> markAllAsRead() async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []) as List;

      final updatedNotifications = notificationsJson.map((json) {
        final notification = NotificationModel.fromJson(
          Map<String, dynamic>.from(json),
        );
        return notification.copyWith(isRead: true).toJson();
      }).toList();

      await box.put(_notificationsListKey, updatedNotifications);
      return const Right(null);
    } catch (e) {
      return Left('Error marking all notifications as read: ${e.toString()}');
    }
  }

  /// Delete notification
  @override
  Future<Either<String, void>> deleteNotification(String notificationId) async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []) as List;

      notificationsJson.removeWhere((json) => json['id'] == notificationId);
      await box.put(_notificationsListKey, notificationsJson);

      return const Right(null);
    } catch (e) {
      return Left('Error deleting notification: ${e.toString()}');
    }
  }

  /// Delete all notifications
  @override
  Future<Either<String, void>> deleteAllNotifications() async {
    try {
      final box = await _getNotificationsBox();
      await box.put(_notificationsListKey, []);
      return const Right(null);
    } catch (e) {
      return Left('Error deleting all notifications: ${e.toString()}');
    }
  }

  /// Get unread notification count
  @override
  Future<Either<String, int>> getUnreadCount() async {
    try {
      final box = await _getNotificationsBox();
      final notificationsJson =
          box.get(_notificationsListKey, defaultValue: []) as List;

      final unreadCount = notificationsJson.where((json) {
        return json['isRead'] == false || json['isRead'] == null;
      }).length;

      return Right(unreadCount);
    } catch (e) {
      return Left('Error getting unread count: ${e.toString()}');
    }
  }

  /// Get notifications box from Hive
  Future<Box> _getNotificationsBox() async {
    if (!Hive.isBoxOpen(_notificationsBoxKey)) {
      return await Hive.openBox(_notificationsBoxKey);
    }
    return Hive.box(_notificationsBoxKey);
  }
}
