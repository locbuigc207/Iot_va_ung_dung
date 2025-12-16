import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:draw_graph/draw_graph.dart';
import 'package:draw_graph/models/feature.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:json_annotation/json_annotation.dart';
import'package:d_chart/d_chart.dart';

import 'bilanpage.dart';

class Bilanpage extends StatefulWidget {
  @override
   State<StatefulWidget> createState() => InitState();
}

class InitState extends State<Bilanpage> {


  /*void initState() {
    super.initState();
  } */

  DatabaseReference ref=FirebaseDatabase.instance.refFromURL('https://system-d-arrosage-default-rtdb.firebaseio.com/Data');
  String? data;
  Map<String,dynamic>? convertedData;
  @override
  void initstate() {
    ref.onValue.listen((event) {
      setState(() {
        print(event.snapshot.value);
        data=jsonEncode(event.snapshot.value);
        convertedData=jsonDecode(data!);

      });
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Données',
              style: TextStyle(
                  fontFamily: 'VeronaSerial',
                  color: Color(0xFFF4F3E9)
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_outlined),
              color: Colors.black,
              onPressed: () {
              },
            ),
            actions: [
              IconButton(
                icon : Icon(Icons.settings_outlined),
                color: Colors.black,
                onPressed: () {
                },
              )
            ],
            backgroundColor: Color(0xFF00C1C4),
          ),
          backgroundColor: Color(0xFFF4F3E9),
          body: Container(
            child: Container(
              child: SfCartesianChart(
              ),
            ),
          ),
        ),
    );

  }

}

class FireData {
  FireData(this.time, this.Property);
  final double time;
  final double Property;
}
