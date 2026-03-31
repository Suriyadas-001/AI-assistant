// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Full immersive UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize notification channel
  await _initNotificationChannel();

  // Initialize background service
  await _initBackgroundService();

  runApp(const JarvisApp());
}

Future<void> _initNotificationChannel() async {
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await plugin.initialize(
    const InitializationSettings(android: initSettings),
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'jarvis_channel',
    'JARVIS Service',
    description: 'JARVIS AI Assistant background service',
    importance: Importance.low,
    playSound: false,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // User must manually start it
      isForegroundMode: true,
      notificationChannelId: 'jarvis_channel',
      initialNotificationTitle: 'J.A.R.V.I.S',
      initialNotificationContent: 'Tap to open your AI Assistant',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.microphone],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00B0FF),
          secondary: const Color(0xFF00E5FF),
          surface: const Color(0xFF03060E),
        ),
        scaffoldBackgroundColor: const Color(0xFF03060E),
        fontFamily: 'sans-serif-light',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
