import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import 'firebase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService = FirebaseService();

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  // Initialize notification services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup FCM
      await _setupFCM();

      _initialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService initialization error: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('Local notifications initialized');
  }

  // Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: Send to backend if needed
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Pi-Vert',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Save to Firebase
    await _saveNotificationToFirebase(message);
  }

  // Handle message when app opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.messageId}');
    // TODO: Navigate to specific screen based on message data
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pivert_channel',
      'Pi-Vert Notifications',
      channelDescription: 'Notifications for watering and sensor alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Save notification to Firebase
  Future<void> _saveNotificationToFirebase(RemoteMessage message) async {
    final data = message.data;

    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: _parseNotificationType(data['type']),
      title: message.notification?.title ?? 'Thông báo',
      message: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      priority: _parseNotificationPriority(data['priority']),
      zoneId: data['zoneId'],
      zoneName: data['zoneName'],
      sensorId: data['sensorId'],
      sensorName: data['sensorName'],
      data: Map<String, dynamic>.from(data),
    );

    await _firebaseService.addNotification(notification);
  }

  // Parse notification type from string
  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.info;

    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NotificationType.info,
      );
    } catch (e) {
      return NotificationType.info;
    }
  }

  // Parse notification priority from string
  NotificationPriority _parseNotificationPriority(String? priority) {
    if (priority == null) return NotificationPriority.medium;

    try {
      return NotificationPriority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => NotificationPriority.medium,
      );
    } catch (e) {
      return NotificationPriority.medium;
    }
  }

  // Send local notification for watering start
  Future<void> notifyWateringStart({
    required String zoneName,
    required int duration,
  }) async {
    await _showLocalNotification(
      title: '💧 Bắt đầu tưới',
      body: 'Đang tưới $zoneName trong $duration phút',
    );

    // Save to Firebase
    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: NotificationType.wateringStart,
      title: 'Bắt đầu tưới',
      message: 'Đang tưới $zoneName trong $duration phút',
      timestamp: DateTime.now(),
      priority: NotificationPriority.medium,
      zoneName: zoneName,
    );

    await _firebaseService.addNotification(notification);
  }

  // Send local notification for watering end
  Future<void> notifyWateringEnd({
    required String zoneName,
    required int actualDuration,
  }) async {
    await _showLocalNotification(
      title: '✅ Hoàn thành tưới',
      body: 'Đã tưới $zoneName xong ($actualDuration phút)',
    );

    // Save to Firebase
    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: NotificationType.wateringEnd,
      title: 'Hoàn thành tưới',
      message: 'Đã tưới $zoneName xong ($actualDuration phút)',
      timestamp: DateTime.now(),
      priority: NotificationPriority.low,
      zoneName: zoneName,
    );

    await _firebaseService.addNotification(notification);
  }

  // Send sensor alert notification
  Future<void> notifySensorAlert({
    required String sensorName,
    required String zoneName,
    required String message,
    required NotificationPriority priority,
  }) async {
    await _showLocalNotification(
      title: '⚠️ Cảnh báo cảm biến',
      body: '$sensorName - $zoneName: $message',
    );

    // Save to Firebase
    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: NotificationType.sensorAlert,
      title: 'Cảnh báo cảm biến',
      message: '$sensorName - $zoneName: $message',
      timestamp: DateTime.now(),
      priority: priority,
      zoneName: zoneName,
      sensorName: sensorName,
    );

    await _firebaseService.addNotification(notification);
  }

  // Send leak detection notification
  Future<void> notifyLeakDetected({
    required String zoneName,
    required String message,
  }) async {
    await _showLocalNotification(
      title: '🚨 Phát hiện rò rỉ!',
      body: '$zoneName: $message',
    );

    // Save to Firebase
    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: NotificationType.leakDetected,
      title: 'Phát hiện rò rỉ',
      message: '$zoneName: $message',
      timestamp: DateTime.now(),
      priority: NotificationPriority.critical,
      zoneName: zoneName,
    );

    await _firebaseService.addNotification(notification);
  }

  // Send schedule start notification
  Future<void> notifyScheduleStart({
    required String zoneName,
    required String time,
  }) async {
    await _showLocalNotification(
      title: '⏰ Lịch trình tưới',
      body: 'Bắt đầu tưới $zoneName lúc $time',
    );

    // Save to Firebase
    final notification = NotificationModel(
      id: '',
      userId: _firebaseService.currentUserId ?? '',
      type: NotificationType.scheduleStart,
      title: 'Lịch trình tưới',
      message: 'Bắt đầu tưới $zoneName lúc $time',
      timestamp: DateTime.now(),
      priority: NotificationPriority.medium,
      zoneName: zoneName,
    );

    await _firebaseService.addNotification(notification);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  // Dispose
  void dispose() {
    _messageSubscription?.cancel();
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message: ${message.messageId}');
  // Handle background message
}
