import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projet2cp/login_screen.dart';

import 'Body.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InitState();
}

class InitState extends State<WelcomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() {
    _timer = Timer(Duration(seconds: 3), loginRoute);
  }

  loginRoute() {
    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Login_screen(),
          ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(),
    );
  }
}
