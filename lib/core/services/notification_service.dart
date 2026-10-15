import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/driver/data/driver_service.dart';
import '../../features/driver/presentation/widgets/incoming_offer_dialog.dart';
import '../navigation/nav_key.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'rides';
  static const _channelName = 'Ride Updates';
  static const _channelDesc = 'Notifications about ride offers and status';

  bool _offerDialogOpen = false;

  Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _local.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onLocalTap,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 900), () {
          _handleOpenedApp(initial);
        });
      }
    } catch (e) {
      debugPrint('[FCM] initialize failed: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    // Broadcast → show full-screen offer dialog
    if (message.data['type'] == 'ride_broadcast') {
      await _showBroadcastDialog();
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _showBroadcastDialog() async {
    if (_offerDialogOpen) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    try {
      final result = await DriverService().getMyAssignments();
      final offered = (result.assignments ?? [])
          .where((a) => a.isOffered)
          .toList();
      if (offered.isEmpty) return;

      _offerDialogOpen = true;

      if (!ctx.mounted) {
        _offerDialogOpen = false;
        return;
      }

      await showDialog(
        context: ctx,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (_) => IncomingOfferDialog(
          assignment: offered.first,
          onDismissed: () {
            _offerDialogOpen = false;
          },
        ),
      );
    } catch (e) {
      _offerDialogOpen = false;
      debugPrint('[FCM] Broadcast dialog failed: $e');
    }
  }

  void _onLocalTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      if (data['type'] == 'ride_broadcast') {
        _showBroadcastDialog();
      } else {
        _navigateFromData(data);
      }
    } catch (e) {
      debugPrint('[FCM] Payload parse failed: $e');
    }
  }

  void _handleOpenedApp(RemoteMessage message) {
    if (message.data['type'] == 'ride_broadcast') {
      _showBroadcastDialog();
      return;
    }
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    try {
      if (screen != null) {
        GoRouter.of(ctx).go(screen);
      } else {
        GoRouter.of(ctx).go('/home');
      }
    } catch (e) {
      debugPrint('[FCM] Navigation failed: $e');
    }
  }
}