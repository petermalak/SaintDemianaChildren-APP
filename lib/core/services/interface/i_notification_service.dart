import 'package:firebase_messaging/firebase_messaging.dart';

/// INotificationService Interface
///
/// Defines the contract for notification service implementations.
/// Follows Interface Segregation Principle (ISP).
abstract class INotificationService {
  /// Initialize Firebase Messaging
  Future<void> initialize();

  /// Get FCM token
  Future<String?> getToken();

  /// Request notification permissions
  Future<bool> requestPermission();

  /// Listen to token refresh
  Stream<String> get onTokenRefresh;

  /// Listen to foreground messages
  Stream<RemoteMessage> get onMessageReceived;

  /// Listen to message opened (when user taps notification)
  Stream<RemoteMessage> get onMessageOpened;

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);
}
