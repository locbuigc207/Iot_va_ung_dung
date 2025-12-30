import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/watering_history_model.dart';
import '../services/history_service.dart';

class WateringHistoryPage extends StatefulWidget {
  final String? zoneId;
  final String? zoneName;

  const WateringHistoryPage({
    Key? key,
    this.zoneId,
    this.zoneName,
  }) : super(key: key);

  @override
  State<WateringHistoryPage> createState() => _WateringHistoryPageState();
}

class _WateringHistoryPageState extends State<WateringHistoryPage> {
  final HistoryService _historyService = HistoryService();

  String _timeRange = 'week'; // day, week, month, year
  List<WateringHistoryModel> _history = [];
  Map<DateTime, double> _dailySummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timeRange) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      case 'year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final startDate = _getStartDate();
      final endDate = DateTime.now();

      final history = widget.zoneId != null
          ? await _historyService
              .getZoneHistory(widget.zoneId!,
                  startDate: startDate, endDate: endDate)
              .first
          : await _historyService
              .getAllHistory(startDate: startDate, endDate: endDate)
              .first;

      final summary = widget.zoneId != null
          ? await _historyService.getDailySummary(
              widget.zoneId!, startDate, endDate)
          : <DateTime, double>{};

      if (mounted) {
        setState(() {
          _history = history;
          _dailySummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWater = _history.fold<double>(0, (sum, h) => sum + h.waterUsed);
    final totalSessions = _history.length;
    final avgPerSession = totalSessions > 0 ? totalWater / totalSessions : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.zoneName != null
              ? 'Lịch sử - ${widget.zoneName}'
              : 'Lịch sử tưới',
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
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C1C4), Color(0xFF00A0A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C1C4).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Thống kê',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatItem(
                        '$totalSessions', 'Lần tưới', Icons.water_drop),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      '${totalWater.toStringAsFixed(1)}L',
                      'Tổng nước',
                      Icons.opacity,
                    ),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      '${avgPerSession.toStringAsFixed(1)}L',
                      'TB/lần',
                      Icons.analytics,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time Range Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTimeRangeChip('Hôm nay', 'day'),
                const SizedBox(width: 8),
                _buildTimeRangeChip('7 ngày', 'week'),
                const SizedBox(width: 8),
                _buildTimeRangeChip('30 ngày', 'month'),
                const SizedBox(width: 8),
                _buildTimeRangeChip('1 năm', 'year'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart
          if (_dailySummary.isNotEmpty && widget.zoneId != null) _buildChart(),

          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(_history[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, String value) {
    final isSelected = _timeRange == value;

    return Expanded(
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _timeRange = value;
            _loadHistory();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00C1C4),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildChart() {
    final sortedDates = _dailySummary.keys.toList()..sort();

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lượng nước theo ngày',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}L',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedDates.length) {
                          final date = sortedDates[value.toInt()];
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: const TextStyle(fontSize: 9),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedDates.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        _dailySummary[entry.value] ?? 0,
                      );
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF00C1C4),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00C1C4).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(WateringHistoryModel history) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C1C4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    history.getSourceIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.zoneName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(history.startTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    history.getSourceDisplay(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.timer_outlined,
                    '${history.duration} phút',
                    'Thời gian',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.water_drop_outlined,
                    '${history.waterUsed.toStringAsFixed(1)}L',
                    'Nước dùng',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.check_circle_outline,
                    history.completed ? 'Hoàn thành' : 'Chưa xong',
                    'Trạng thái',
                  ),
                ),
              ],
            ),
            if (history.notes != null && history.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        history.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử tưới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dữ liệu sẽ xuất hiện sau khi bạn tưới cây',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
