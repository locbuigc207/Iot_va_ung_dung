import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hust_iot/welcome_page.dart';

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
        apiKey: 'AIzaSyA3Y0n-Jdjxym66sjvNJ3pptxRrMMJGUps',
        appId: '1:526952035891:android:eaccde267d89704b5f9546',
        messagingSenderId: '526952035891',
        projectId: 'flutter-chat-app-3e625',
        databaseURL:
            'https://flutter-chat-app-3e625-default-rtdb.firebaseio.com',
        storageBucket: 'flutter-chat-app-3e625.firebasestorage.app',
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
