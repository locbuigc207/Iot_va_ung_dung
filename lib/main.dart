import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivert_iot/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD8J3kRF5-NHm0DUuliFtUpVduPMg2DTWs',
        appId: '1:852160365626:android:2a3b58fd8a31f12ad16103',
        messagingSenderId: '852160365626',
        projectId: 'system-d-arrosage',
        databaseURL: 'https://system-d-arrosage-default-rtdb.firebaseio.com',
        storageBucket: 'system-d-arrosage.appspot.com',
      ),
    );
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Don't throw exception to allow app to run
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
      home: const WelcomePage(),
    );
  }
}
