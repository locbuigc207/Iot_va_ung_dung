import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';
import 'add_sensor_page.dart';

class SensorDashboardPage extends StatefulWidget {
  final ZoneModel zone;

  const SensorDashboardPage({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  State<SensorDashboardPage> createState() => _SensorDashboardPageState();
}

class _SensorDashboardPageState extends State<SensorDashboardPage> {
  final FirebaseService _firebaseService = FirebaseService();

  List<SensorModel> _sensors = [];
  Map<String, List<SensorReadingModel>> _readings = {};
  SensorModel? _selectedSensor;
  String _timeRange = '24h'; // 24h, 7d, 30d
  StreamSubscription? _sensorsSubscription;
  StreamSubscription? _readingsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  void _loadSensors() {
    _sensorsSubscription?.cancel();
    _sensorsSubscription =
        _firebaseService.getSensorsStream(widget.zone.id).listen((sensors) {
      if (!mounted) return;
      setState(() {
        _sensors = sensors;
        if (_selectedSensor == null && sensors.isNotEmpty) {
          _selectedSensor = sensors.first;
          _loadReadings();
        }
      });
    });
  }

  void _loadReadings() {
    if (_selectedSensor == null) return;

    final endDate = DateTime.now();
    final startDate = _getStartDate();

    _readingsSubscription?.cancel();
    _readingsSubscription = _firebaseService
        .getSensorReadingsStream(_selectedSensor!.id, startDate, endDate)
        .listen((readings) {
      if (!mounted) return;
      setState(() {
        _readings[_selectedSensor!.id] = readings;
      });
    });
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timeRange) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.zone.name} - Sensors',
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00C1C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSensorPage(zone: widget.zone),
                ),
              );
            },
          ),
        ],
      ),
      body: _sensors.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Sensor Selector
                _buildSensorSelector(),

                // Time Range Selector
                _buildTimeRangeSelector(),

                // Current Value Card
                if (_selectedSensor != null) _buildCurrentValueCard(),

                // Chart
                Expanded(
                  child: _buildChart(),
                ),

                // Stats Cards
                if (_selectedSensor != null) _buildStatsCards(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có cảm biến nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm cảm biến để theo dõi dữ liệu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSensorPage(zone: widget.zone),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm cảm biến'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1C4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sensors.length,
        itemBuilder: (context, index) {
          final sensor = _sensors[index];
          final isSelected = _selectedSensor?.id == sensor.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSensor = sensor;
                _loadReadings();
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00C1C4) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF00C1C4) : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sensor.getIcon(),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sensor.type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontFamily: 'SpaceGrotesk',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTimeRangeChip('24h', '24 giờ'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('7d', '7 ngày'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('30d', '30 ngày'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _timeRange == value;

    return Expanded(
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _timeRange = value;
            _loadReadings();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00C1C4),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildCurrentValueCard() {
    final sensor = _selectedSensor!;
    final status = sensor.getStatus();
    final color = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sensor.getIcon(),
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sensor.getFormattedValue(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensor.getStatusText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_selectedSensor == null) {
      return const Center(child: Text('Chọn cảm biến để xem biểu đồ'));
    }

    final readings = _readings[_selectedSensor!.id] ?? [];

    if (readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  final index = value.toInt();
                  if (index >= 0 && index < readings.length) {
                    final date = readings[index].timestamp;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatChartDate(date),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minX: 0,
          maxX: (readings.length - 1).toDouble(),
          minY: _selectedSensor!.minThreshold - 10,
          maxY: _selectedSensor!.maxThreshold + 10,
          lineBarsData: [
            LineChartBarData(
              spots: readings
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: const Color(0xFF00C1C4),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: readings.length < 50,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF00C1C4),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00C1C4).withOpacity(0.1),
              ),
            ),
            // Min threshold line
            LineChartBarData(
              spots: [
                FlSpot(0, _selectedSensor!.minThreshold),
                FlSpot((readings.length - 1).toDouble(),
                    _selectedSensor!.minThreshold),
              ],
              isCurved: false,
              color: Colors.orange,
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
            // Max threshold line
            LineChartBarData(
              spots: [
                FlSpot(0, _selectedSensor!.maxThreshold),
                FlSpot((readings.length - 1).toDouble(),
                    _selectedSensor!.maxThreshold),
              ],
              isCurved: false,
              color: Colors.red,
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final readings = _readings[_selectedSensor!.id] ?? [];
    if (readings.isEmpty) return const SizedBox.shrink();

    final values = readings.map((r) => r.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Thấp nhất', min, Icons.arrow_downward, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('Trung bình', avg, Icons.analytics, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('Cao nhất', max, Icons.arrow_upward, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                '${value.toStringAsFixed(1)} ${_selectedSensor!.unit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.normal:
        return Colors.green;
      case SensorStatus.low:
        return Colors.orange;
      case SensorStatus.high:
        return Colors.red;
      case SensorStatus.inactive:
        return Colors.grey;
    }
  }

  String _formatChartDate(DateTime date) {
    switch (_timeRange) {
      case '24h':
        return DateFormat('HH:mm').format(date);
      case '7d':
        return DateFormat('dd/MM').format(date);
      case '30d':
        return DateFormat('dd/MM').format(date);
      default:
        return DateFormat('HH:mm').format(date);
    }
  }

  @override
  void dispose() {
    _sensorsSubscription?.cancel();
    _readingsSubscription?.cancel();
    super.dispose();
  }
}
