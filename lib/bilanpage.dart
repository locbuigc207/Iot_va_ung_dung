import 'dart:async';
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
  final DatabaseReference ref = FirebaseDatabase.instance.ref('Data');
  final int _maxDataPoints = 100;

  String? data;
  Map<String, dynamic>? convertedData;
  List<FireData> chartData = [];
  bool isLoading = true;
  String errorMessage = '';
  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  void _listenToData() {
    _subscription?.cancel();
    _subscription = null;

    _subscription = ref.onValue.listen(
      (event) {
        if (!mounted) return;

        setState(() {
          try {
            if (event.snapshot.value != null) {
              final value = event.snapshot.value;

              if (value is Map) {
                data = jsonEncode(value);
              } else {
                data = jsonEncode({'value': value});
              }

              convertedData = jsonDecode(data!);
              _processChartData();
              errorMessage = '';
            } else {
              errorMessage = 'Aucune donnée disponible';
              chartData = [];
            }
          } catch (e) {
            errorMessage = 'Erreur de traitement: $e';
            debugPrint('Error listening to data: $e');
          }
          isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Erreur de connexion: $error';
          isLoading = false;
        });
      },
    );
  }

  void _processChartData() {
    if (convertedData == null) return;

    chartData.clear();
    int index = 0;

    try {
      convertedData!.forEach((key, value) {
        double? time;
        double? property;

        if (value is Map) {
          if (value.containsKey('time') && value.containsKey('property')) {
            time = _parseDouble(value['time']);
            property = _parseDouble(value['property']);
          } else if (value.containsKey('x') && value.containsKey('y')) {
            time = _parseDouble(value['x']);
            property = _parseDouble(value['y']);
          } else if (value.values.isNotEmpty) {
            time = _parseDouble(key);
            property = _parseDouble(value.values.first);
          }
        } else if (value is num) {
          time = _parseDouble(key);
          property = value.toDouble();
        }

        time ??= index.toDouble();

        if (property != null) {
          chartData.add(FireData(time, property));
          index++;
        }
      });

      chartData.sort((a, b) => a.time.compareTo(b.time));

      if (chartData.length > _maxDataPoints) {
        chartData = chartData.sublist(chartData.length - _maxDataPoints);
      }
    } catch (e) {
      debugPrint('Error processing chart data: $e');
      errorMessage = 'Erreur de traitement des données graphiques';
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _refreshData() {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      chartData = [];
    });
    _listenToData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Données',
            style: TextStyle(
              fontFamily: 'VeronaSerial',
              color: Color(0xFFF4F3E9),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            color: Colors.white,
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: _refreshData,
            )
          ],
          backgroundColor: const Color(0xFF00C1C4),
        ),
        backgroundColor: const Color(0xFFF4F3E9),
        body: isLoading
            ? const Center(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C1C4),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
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
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: const Color(0xFF00C1C4)
                                            .withOpacity(0.2),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 300,
                                  child: chartData.isEmpty
                                      ? const Center(
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
                                              textStyle: const TextStyle(
                                                fontFamily: 'SpaceGrotesk',
                                                fontSize: 12,
                                              ),
                                            ),
                                            labelStyle: const TextStyle(
                                              fontFamily: 'SpaceGrotesk',
                                              fontSize: 10,
                                            ),
                                          ),
                                          primaryYAxis: NumericAxis(
                                            title: AxisTitle(
                                              text: 'Valeur',
                                              textStyle: const TextStyle(
                                                fontFamily: 'SpaceGrotesk',
                                                fontSize: 12,
                                              ),
                                            ),
                                            labelStyle: const TextStyle(
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
                                              color: const Color(0xFF00C1C4),
                                              width: 2,
                                              markerSettings:
                                                  const MarkerSettings(
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
                                            textStyle: const TextStyle(
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
                        const SizedBox(height: 20),
                        if (convertedData != null && convertedData!.isNotEmpty)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Données brutes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SpaceGrotesk',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        data ?? 'Aucune donnée',
                                        style: const TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          fontSize: 12,
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
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

class FireData {
  FireData(this.time, this.property);
  final double time;
  final double property;
}
