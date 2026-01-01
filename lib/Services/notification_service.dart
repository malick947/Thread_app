import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ===============================
  // MAIN INIT FUNCTION (CALL ONLY THIS)
  // ===============================
  Future<void> init() async {
    await _initializeAwesomeNotifications();
    await _requestPermission();
    await _setupFirebaseListeners();
    _listenTokenRefresh();
    await getToken();
  }

  // ===============================
  // AWESOME NOTIFICATION SETUP
  // ===============================
  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'App Notifications',
          channelDescription: 'Notification channel',
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationAction,
    );
  }

  // ===============================
  // NOTIFICATION TAP HANDLER
  // ===============================
  static Future<void> _onNotificationAction(
      ReceivedAction action) async {
    final data = action.payload;

    if (data?['type'] == 'msg') {
      print("Notification clicked → Message");

      // Example:
      // Get.to(() => ChatScreen());
    }
  }

  // ===============================
  // PERMISSION
  // ===============================
  Future<void> _requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // ===============================
  // GET FCM TOKEN
  // ===============================
  Future<void> getToken() async {
    try {
      final token = await _messaging.getToken();
      print("FCM Token: $token");
    } catch (e) {
      print("Token error: $e");
    }
  }

  // ===============================
  // FIREBASE FOREGROUND LISTENER
  // ===============================
  Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground notification received");

      await _showNotification(message);
    });
  }

  // ===============================
  // TOKEN REFRESH LISTENER
  // ===============================
  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      print("New FCM Token: $token");
    });
  }

  // ===============================
  // SHOW NOTIFICATION
  // ===============================
  Future<void> _showNotification(RemoteMessage message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
        payload: {
          'type': message.data['type'] ?? '',
        },
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
