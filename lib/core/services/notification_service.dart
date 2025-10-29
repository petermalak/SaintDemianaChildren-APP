import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'interface/i_notification_service.dart';

/// NotificationService
///
/// Concrete implementation of INotificationService using Firebase Cloud Messaging.
/// Follows Single Responsibility Principle (SRP) - handles FCM operations.
/// Follows Singleton Pattern for global access.
class NotificationService implements INotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  // Lazy initialization for Firebase - only on mobile platforms
  FirebaseMessaging? _firebaseMessaging;

  FirebaseMessaging? get firebaseMessaging {
    if (kIsWeb) {
      return null; // Firebase not available on web
    }
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging;
  }

  // Stream controllers for notifications
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _messageOpenedStreamController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<String> _tokenRefreshStreamController =
      StreamController<String>.broadcast();

  bool _isInitialized = false;

  /// Configure notification presentation options
  Future<void> _createNotificationChannel() async {
    if (firebaseMessaging == null) return;

    try {
      // Configure how notifications are presented when app is in foreground
      await firebaseMessaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('✅ Notification presentation options configured');
    } catch (e) {
      debugPrint('⚠️ Error configuring notifications: $e');
      // Continue even if configuration fails
    }
  }

  /// Initialize Firebase Messaging
  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔔 NotificationService already initialized');
      return;
    }

    // Skip Firebase initialization on web (not configured)
    if (kIsWeb) {
      debugPrint(
          'ℹ️ Web platform - skipping Firebase messaging (not configured)');
      _isInitialized = true;
      return;
    }

    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Create notification channel for Android
      await _createNotificationChannel();

      // Request permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('⚠️ Notification permission denied');
        return;
      }

      // Get initial token
      final token = await getToken();
      if (token != null) {
        debugPrint('✅ FCM Token: $token');
      }

      // Listen to token refresh
      if (firebaseMessaging != null) {
        firebaseMessaging!.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _tokenRefreshStreamController.add(newToken);
        });
      }

      // Handle foreground messages (only on mobile)
      if (!kIsWeb && firebaseMessaging != null) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
              '📬 Foreground message received: ${message.notification?.title}');
          _messageStreamController.add(message);
        });

        // Handle background messages opened by user
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint(
              '📬 Message opened from background: ${message.notification?.title}');
          _messageOpenedStreamController.add(message);
        });
      }

      // Check if app was opened from a terminated state
      if (firebaseMessaging != null) {
        final initialMessage = await firebaseMessaging!.getInitialMessage();
        if (initialMessage != null) {
          debugPrint(
              '📬 App opened from terminated state: ${initialMessage.notification?.title}');
          _messageOpenedStreamController.add(initialMessage);
        }
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Get FCM token
  @override
  Future<String?> getToken() async {
    if (kIsWeb) {
      debugPrint('ℹ️ Web platform - FCM token not available');
      return null;
    }

    try {
      if (firebaseMessaging == null) {
        return null;
      }
      final token = await firebaseMessaging!.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Request notification permissions
  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      debugPrint('ℹ️ Web platform - notification permission not applicable');
      return false;
    }

    try {
      if (firebaseMessaging == null) {
        return false;
      }

      final settings = await firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        debugPrint('✅ Notification permission granted');
      } else {
        debugPrint('⚠️ Notification permission denied');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Listen to token refresh
  @override
  Stream<String> get onTokenRefresh => _tokenRefreshStreamController.stream;

  /// Listen to foreground messages
  @override
  Stream<RemoteMessage> get onMessageReceived =>
      _messageStreamController.stream;

  /// Listen to message opened (when user taps notification)
  @override
  Stream<RemoteMessage> get onMessageOpened =>
      _messageOpenedStreamController.stream;

  /// Subscribe to a topic
  @override
  Future<void> subscribeToTopic(String topic) async {
    if (firebaseMessaging == null) {
      debugPrint('ℹ️ Firebase not available - skipping topic subscription');
      return;
    }

    try {
      await firebaseMessaging!.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (firebaseMessaging == null) {
      debugPrint('ℹ️ Firebase not available - skipping topic unsubscription');
      return;
    }

    try {
      await firebaseMessaging!.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Dispose streams
  void dispose() {
    _messageStreamController.close();
    _messageOpenedStreamController.close();
    _tokenRefreshStreamController.close();
  }
}

/// Background message handler
/// Must be a top-level function (outside the class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.notification?.title}');
  // Handle background message here
  // Note: You can't update UI from here, only perform background tasks
}
