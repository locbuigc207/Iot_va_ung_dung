import 'package:flutter/material.dart';
import 'package:projet2cp/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
    State<StatefulWidget> createState() => InitState();
}

class InitState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return homeWidget();
  }

  Widget homeWidget() {
    Size size = MediaQuery.of(context).size;
      return Container(
        color: Colors.white,
        //height: size.height,
        width: double.infinity,
          child: Column(
            children: <Widget> [

            ],
          ) ,
      );
  }

}