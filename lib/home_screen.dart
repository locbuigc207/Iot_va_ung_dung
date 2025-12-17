import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Color(0xFFF4F3E9),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00C1C4),
      ),
      body: const Center(
        child: Text(
          'Welcome to Pi-Vert',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
