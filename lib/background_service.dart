// background_service.dart
// This file is the entry point for the background isolate.
// It must be a top-level function.
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  final FlutterTts tts = FlutterTts();
  await tts.setLanguage("en-US");
  await tts.setPitch(1.1);
  await tts.setSpeechRate(0.5);

  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('assistant_name') ?? 'JARVIS';

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await notificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
    onDidReceiveNotificationResponse: (details) async {
      if (details.actionId == 'stop_service') {
        service.stopSelf();
      }
    },
  );

  // Show persistent notification
  Future<void> updateNotification(String status) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'jarvis_channel',
      'JARVIS Service',
      channelDescription: 'JARVIS AI Assistant running in background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction('stop_service', 'Stop JARVIS'),
      ],
    );

    await notificationsPlugin.show(
      888,
      '$name is Active 🤖',
      status,
      const NotificationDetails(android: androidDetails),
    );
  }

  await updateNotification('Tap to open • Say "Hey $name" to activate');

  // Listen to events from main isolate
  service.on('setAsForeground').listen((event) async {
    await updateNotification('Listening...');
  });

  service.on('setAsBackground').listen((event) async {
    await updateNotification('Tap to open • Running in background');
  });

  service.on('speak').listen((event) async {
    final text = event?['text'] ?? '';
    await tts.speak(text);
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Keep alive
  service.on('ping').listen((event) {
    service.invoke('pong');
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}
