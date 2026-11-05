import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// LocalNotificationService
///
/// Handles local notification display with better UI and control.
/// Works with flutter_local_notifications for enhanced notification experience.
/// Follows Singleton pattern and integrates with state management.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📱 LocalNotificationService already initialized');
      return;
    }

    try {
      debugPrint('📱 Initializing LocalNotificationService...');

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
        '@drawable/ic_notification', // White notification icon
      );

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('📱 Local notification tapped: ${details.payload}');
          // This can trigger navigation through state management
        },
      );

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('✅ LocalNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing LocalNotificationService: $e');
    }
  }

  /// Create notification channels for different types
  Future<void> _createNotificationChannels() async {
    // General notifications channel
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      'saint_demiana_general',
      'General Notifications',
      description: 'General notifications from Saint Demiana Church',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Attendance notifications channel
    const AndroidNotificationChannel attendanceChannel =
        AndroidNotificationChannel(
      'saint_demiana_attendance',
      'Attendance Notifications',
      description: 'Attendance related notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Eftekad notifications channel
    const AndroidNotificationChannel eftekadChannel =
        AndroidNotificationChannel(
      'saint_demiana_eftekad',
      'Eftekad Notifications',
      description: 'Eftekad related notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Announcements channel
    const AndroidNotificationChannel announcementChannel =
        AndroidNotificationChannel(
      'saint_demiana_announcements',
      'Announcements',
      description: 'Important announcements',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Create all channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(attendanceChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eftekadChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(announcementChannel);

    debugPrint('✅ Notification channels created');
  }

  /// Show notification from RemoteMessage
  Future<void> showNotification(RemoteMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }

    final notification = message.notification;
    final data = message.data;

    if (notification == null) {
      debugPrint('⚠️ No notification payload in message');
      return;
    }

    // Determine notification type and channel
    final notificationType = data['type'] ?? 'general';
    final channelId = _getChannelId(notificationType);

    // Create notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(notificationType),
      channelDescription: _getChannelDescription(notificationType),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF8B1538), // Your app's primary color
      largeIcon: const DrawableResourceAndroidBitmap(
          '@mipmap/launcher_icon'), // App icon as large icon
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
        summaryText: 'Saint Demiana Church',
        htmlFormatSummaryText: true,
      ),
      ticker: notification.title,
      autoCancel: true,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate unique notification ID
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Show the notification
    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );

    debugPrint('✅ Local notification shown: ${notification.title}');
  }

  /// Get channel ID based on notification type
  String _getChannelId(String type) {
    switch (type) {
      case 'attendance':
        return 'saint_demiana_attendance';
      case 'eftekad':
        return 'saint_demiana_eftekad';
      case 'announcement':
        return 'saint_demiana_announcements';
      default:
        return 'saint_demiana_general';
    }
  }

  /// Get channel name based on notification type
  String _getChannelName(String type) {
    switch (type) {
      case 'attendance':
        return 'Attendance Notifications';
      case 'eftekad':
        return 'Eftekad Notifications';
      case 'announcement':
        return 'Announcements';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description based on notification type
  String _getChannelDescription(String type) {
    switch (type) {
      case 'attendance':
        return 'Notifications about attendance and check-ins';
      case 'eftekad':
        return 'Notifications about eftekad activities';
      case 'announcement':
        return 'Important announcements from the church';
      default:
        return 'General notifications from Saint Demiana Church';
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }
}
