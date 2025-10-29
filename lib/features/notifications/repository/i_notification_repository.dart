import 'package:dartz/dartz.dart';
import '../model/notification_model.dart';

/// INotificationRepository Interface
///
/// Defines the contract for notification repository implementations.
/// Follows Interface Segregation Principle (ISP) and Dependency Inversion Principle (DIP).
abstract class INotificationRepository {
  /// Update FCM token on the server
  Future<Either<String, void>> updateFcmToken(String fcmToken);

  /// Remove FCM token from the server (on logout)
  Future<Either<String, void>> removeFcmToken();

  /// Get all notifications (from local storage)
  Future<Either<String, List<NotificationModel>>> getNotifications();

  /// Save notification to local storage
  Future<Either<String, void>> saveNotification(NotificationModel notification);

  /// Mark notification as read
  Future<Either<String, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<String, void>> markAllAsRead();

  /// Delete notification
  Future<Either<String, void>> deleteNotification(String notificationId);

  /// Delete all notifications
  Future<Either<String, void>> deleteAllNotifications();

  /// Get unread notification count
  Future<Either<String, int>> getUnreadCount();
}
