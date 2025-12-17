import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('Data');
  final int _maxDataPoints = 100;

  String? _data;
  Map<String, dynamic>? _convertedData;
  List<FireData> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  void _listenToData() {
    _subscription?.cancel();
    _subscription = null;

    _subscription = _ref.onValue.listen(
      (event) {
        if (!mounted) return;

        setState(() {
          try {
            if (event.snapshot.value != null) {
              final value = event.snapshot.value;

              if (value is Map) {
                _data = jsonEncode(value);
              } else {
                _data = jsonEncode({'value': value});
              }

              _convertedData = jsonDecode(_data!);
              _processChartData();
              _errorMessage = '';
            } else {
              _errorMessage = 'No data available';
              _chartData = [];
            }
          } catch (e) {
            _errorMessage = 'Processing error: $e';
            debugPrint('Error listening to data: $e');
          }
          _isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Connection error: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _processChartData() {
    if (_convertedData == null) return;

    _chartData.clear();
    int index = 0;

    try {
      _convertedData!.forEach((key, value) {
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
          _chartData.add(FireData(time, property));
          index++;
        }
      });

      _chartData.sort((a, b) => a.time.compareTo(b.time));

      if (_chartData.length > _maxDataPoints) {
        _chartData = _chartData.sublist(_chartData.length - _maxDataPoints);
      }
    } catch (e) {
      debugPrint('Error processing chart data: $e');
      _errorMessage = 'Error processing chart data';
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
      _isLoading = true;
      _errorMessage = '';
      _chartData = [];
    });
    _listenToData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Data',
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
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF00C1C4),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading data...',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
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
                            _errorMessage,
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
                            label: const Text('Retry'),
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
                                      'Data Chart',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                    if (_chartData.isNotEmpty)
                                      Chip(
                                        label: Text(
                                          '${_chartData.length} points',
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
                                  child: _chartData.isEmpty
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
                                                'No chart data available',
                                                style: TextStyle(
                                                  fontFamily: 'SpaceGrotesk',
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SfCartesianChart(
                                          primaryXAxis: const NumericAxis(
                                            title: AxisTitle(
                                              text: 'Time',
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
                                          primaryYAxis: const NumericAxis(
                                            title: AxisTitle(
                                              text: 'Value',
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
                                              dataSource: _chartData,
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
                                                'Time: point.x\nValue: point.y',
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
                        if (_convertedData != null &&
                            _convertedData!.isNotEmpty)
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
                                    'Raw Data',
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
                                        _data ?? 'No data',
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
