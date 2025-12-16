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
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  void _listenToData() {
    ref.onValue.listen((event) {
      if (!mounted) return;

      setState(() {
        try {
          if (event.snapshot.value != null) {
            data = jsonEncode(event.snapshot.value);
            convertedData = jsonDecode(data!);
            _processChartData();
            errorMessage = '';
          } else {
            errorMessage = 'Aucune donnée disponible';
          }
        } catch (e) {
          errorMessage = 'Erreur de traitement: $e';
          print('Error listening to data: $e');
        }
        isLoading = false;
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Erreur de connexion: $error';
        isLoading = false;
      });
    });
  }

  void _processChartData() {
    if (convertedData == null) return;

    chartData.clear();

    try {
      convertedData!.forEach((key, value) {
        if (value is Map) {
          // Essayer différentes structures de données
          double? time;
          double? property;

          // Structure 1: {time: x, property: y}
          if (value.containsKey('time') && value.containsKey('property')) {
            time = double.tryParse(value['time'].toString());
            property = double.tryParse(value['property'].toString());
          }
          // Structure 2: {x: time, y: value}
          else if (value.containsKey('x') && value.containsKey('y')) {
            time = double.tryParse(value['x'].toString());
            property = double.tryParse(value['y'].toString());
          }
          // Structure 3: Utiliser la clé comme temps
          else if (value.values.isNotEmpty) {
            time = double.tryParse(key);
            property = double.tryParse(value.values.first.toString());
          }

          if (time != null && property != null) {
            chartData.add(FireData(time, property));
          }
        } else if (value is num) {
          // Structure simple: key -> valeur
          double? time = double.tryParse(key);
          if (time != null) {
            chartData.add(FireData(time, value.toDouble()));
          }
        }
      });

      // Trier par temps
      chartData.sort((a, b) => a.time.compareTo(b.time));
    } catch (e) {
      print('Error processing chart data: $e');
      errorMessage = 'Erreur de traitement des données graphiques';
    }
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
              icon: Icon(Icons.refresh),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _listenToData();
              },
            )
          ],
          backgroundColor: Color(0xFF00C1C4),
        ),
        backgroundColor: Color(0xFFF4F3E9),
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF00C1C4),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des données...',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                                errorMessage = '';
                              });
                              _listenToData();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00C1C4),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Graphique des données',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                    if (chartData.isNotEmpty)
                                      Chip(
                                        label: Text(
                                          '${chartData.length} points',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor:
                                            Color(0xFF00C1C4).withOpacity(0.2),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  height: 300,
                                  child: chartData.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.show_chart,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Aucune donnée graphique disponible',
                                                style: TextStyle(
                                                  fontFamily: 'SpaceGrotesk',
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SfCartesianChart(
                                          primaryXAxis: NumericAxis(
                                            title: AxisTitle(
                                              text: 'Temps',
                                              textStyle: TextStyle(
                                                fontFamily: 'SpaceGrotesk',
                                                fontSize: 12,
                                              ),
                                            ),
                                            labelStyle: TextStyle(
                                              fontFamily: 'SpaceGrotesk',
                                              fontSize: 10,
                                            ),
                                          ),
                                          primaryYAxis: NumericAxis(
                                            title: AxisTitle(
                                              text: 'Valeur',
                                              textStyle: TextStyle(
                                                fontFamily: 'SpaceGrotesk',
                                                fontSize: 12,
                                              ),
                                            ),
                                            labelStyle: TextStyle(
                                              fontFamily: 'SpaceGrotesk',
                                              fontSize: 10,
                                            ),
                                          ),
                                          series: <CartesianSeries<FireData,
                                              double>>[
                                            LineSeries<FireData, double>(
                                              dataSource: chartData,
                                              xValueMapper:
                                                  (FireData data, _) =>
                                                      data.time,
                                              yValueMapper:
                                                  (FireData data, _) =>
                                                      data.property,
                                              color: Color(0xFF00C1C4),
                                              width: 2,
                                              markerSettings: MarkerSettings(
                                                isVisible: true,
                                                height: 4,
                                                width: 4,
                                                color: Color(0xFF00C1C4),
                                              ),
                                            )
                                          ],
                                          tooltipBehavior: TooltipBehavior(
                                            enable: true,
                                            format:
                                                'Temps: point.x\nValeur: point.y',
                                            textStyle: TextStyle(
                                              fontFamily: 'SpaceGrotesk',
                                            ),
                                          ),
                                          zoomPanBehavior: ZoomPanBehavior(
                                            enablePinching: true,
                                            enablePanning: true,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (convertedData != null && convertedData!.isNotEmpty)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                    constraints: BoxConstraints(maxHeight: 200),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        data ?? 'Aucune donnée',
                                        style: TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          fontSize: 12,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
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

  @override
  void dispose() {
    // Cleanup listeners if needed
    super.dispose();
  }
}

class FireData {
  FireData(this.time, this.property);
  final double time;
  final double property;
}
