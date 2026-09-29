import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

const _pushChannel = AndroidNotificationChannel('tnn_default', 'TNN Notifications', importance: Importance.high);
final _localNotifications = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _setUpForegroundPush();
  runApp(const ProviderScope(child: TnnApp()));
}

/// FCM only auto-shows a system notification when the app is backgrounded or
/// closed. While the app is open, messages arrive silently on this stream
/// instead, so we build a visible notification for them ourselves.
Future<void> _setUpForegroundPush() async {
  await _localNotifications.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_pushChannel);

  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(_pushChannel.id, _pushChannel.name, importance: Importance.high, priority: Priority.high),
      ),
    );
  });
}

class TnnApp extends StatelessWidget {
  const TnnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trusted Neighbourhood Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
