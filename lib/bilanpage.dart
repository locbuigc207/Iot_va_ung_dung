import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Bilanpage extends StatefulWidget {
  const Bilanpage({Key? key}) : super(key: key);

  @override
  State<Bilanpage> createState() => _BilanpageState();
}

class _BilanpageState extends State<Bilanpage> {
  final DatabaseReference ref = FirebaseDatabase.instance
      .refFromURL('https://system-d-arrosage-default-rtdb.firebaseio.com/Data');

  String? data;
  Map<String, dynamic>? convertedData;
  List<FireData> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  void _listenToData() {
    ref.onValue.listen((event) {
      if (!mounted) return;

      setState(() {
        if (event.snapshot.value != null) {
          data = jsonEncode(event.snapshot.value);
          convertedData = jsonDecode(data!);
          _processChartData();
        }
        isLoading = false;
      });
    });
  }

  void _processChartData() {
    if (convertedData == null) return;

    chartData.clear();

    // Example processing - adjust based on your actual data structure
    convertedData!.forEach((key, value) {
      if (value is Map) {
        try {
          double time = double.tryParse(key.toString()) ?? 0.0;
          double property = double.tryParse(value.toString()) ?? 0.0;
          chartData.add(FireData(time, property));
        } catch (e) {
          print('Error processing data: $e');
        }
      }
    });
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
              color: Color(0xFFF4F3E9),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_outlined),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined),
              color: Colors.white,
              onPressed: () {
                // Navigate to settings
              },
            )
          ],
          backgroundColor: Color(0xFF00C1C4),
        ),
        backgroundColor: Color(0xFFF4F3E9),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Graphique des données',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              height: 300,
                              child: chartData.isEmpty
                                  ? Center(
                                      child: Text('Aucune donnée disponible'),
                                    )
                                  : SfCartesianChart(
                                      primaryXAxis: NumericAxis(
                                        title: AxisTitle(
                                          text: 'Temps',
                                          textStyle: TextStyle(
                                            fontFamily: 'SpaceGrotesk',
                                          ),
                                        ),
                                      ),
                                      primaryYAxis: NumericAxis(
                                        title: AxisTitle(
                                          text: 'Valeur',
                                          textStyle: TextStyle(
                                            fontFamily: 'SpaceGrotesk',
                                          ),
                                        ),
                                      ),
                                      series: <ChartSeries>[
                                        LineSeries<FireData, double>(
                                          dataSource: chartData,
                                          xValueMapper: (FireData data, _) =>
                                              data.time,
                                          yValueMapper: (FireData data, _) =>
                                              data.property,
                                          color: Color(0xFF00C1C4),
                                          width: 2,
                                        )
                                      ],
                                      tooltipBehavior: TooltipBehavior(
                                        enable: true,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (convertedData != null)
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Données brutes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SpaceGrotesk',
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data ?? 'Aucune donnée',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class FireData {
  FireData(this.time, this.property);
  final double time;
  final double property;
}
