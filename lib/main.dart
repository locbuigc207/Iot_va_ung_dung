import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/WelcomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pi-Vert',
      theme: ThemeData(
        primaryColor: Color(0xFF00C1C4),
        scaffoldBackgroundColor: Color(0xFFF4F3E9),
        useMaterial3: true,
      ),
      home: WelcomePage(),
    );
  }
}
