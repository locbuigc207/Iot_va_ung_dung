import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'login_screen.dart';
import 'pages/home_page.dart';
import 'services/auto_weather_skip_service.dart';
import 'services/leak_detection_service.dart';
import 'services/notification_service.dart';
import 'services/plant_library_service.dart';
import 'services/soil_moisture_auto_service.dart';
import 'services/weather_service.dart';
import 'welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA3Y0n-Jdjxym66sjvNJ3pptxRrMMJGUps',
        appId: '1:526952035891:android:eaccde267d89704b5f9546',
        messagingSenderId: '526952035891',
        projectId: 'flutter-chat-app-3e625',
        databaseURL:
            'https://flutter-chat-app-3e625-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'flutter-chat-app-3e625.firebasestorage.app',
      ),
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');

    // ✅ CRITICAL FIX: Initialize Plant Library with timeout
    try {
      await PlantLibraryService().initializeDefaultLibrary().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Plant library init timeout - continuing anyway');
        },
      );
      debugPrint('✅ Plant library initialized');
    } catch (e) {
      debugPrint('⚠️ Plant library initialization error: $e');
      // App vẫn chạy được dù không có plant library
    }

    // Initialize Notification Service
    try {
      await NotificationService().initialize();
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ NotificationService initialization error: $e');
    }

    // ==================== PHASE 3: NEW SERVICES ====================

    // Start Weather Service auto-update
    try {
      WeatherService().startAutoUpdate();
      debugPrint('✅ WeatherService started');
    } catch (e) {
      debugPrint('⚠️ WeatherService start error: $e');
    }

    // Start Auto Weather Skip Service
    try {
      await AutoWeatherSkipService().startMonitoring();
      debugPrint('✅ AutoWeatherSkipService started');
    } catch (e) {
      debugPrint('⚠️ AutoWeatherSkipService start error: $e');
    }

    // Start Soil Moisture Auto Service
    try {
      await SoilMoistureAutoService().startMonitoring();
      debugPrint('✅ SoilMoistureAutoService started');
    } catch (e) {
      debugPrint('⚠️ SoilMoistureAutoService start error: $e');
    }

    // Start Leak Detection Service
    try {
      LeakDetectionService().startMonitoring();
      debugPrint('✅ LeakDetectionService started');
    } catch (e) {
      debugPrint('⚠️ LeakDetectionService start error: $e');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pi-Vert',
      theme: ThemeData(
        primaryColor: const Color(0xFF00C1C4),
        scaffoldBackgroundColor: const Color(0xFFF4F3E9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C1C4),
          primary: const Color(0xFF00C1C4),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
