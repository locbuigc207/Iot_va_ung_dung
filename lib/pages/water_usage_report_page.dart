import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/watering_history_model.dart';
import '../models/zone_model.dart';
import '../services/firebase_service.dart';
import '../services/history_service.dart';

class WaterUsageReportPage extends StatefulWidget {
  const WaterUsageReportPage({Key? key}) : super(key: key);

  @override
  State<WaterUsageReportPage> createState() => _WaterUsageReportPageState();
}

class _WaterUsageReportPageState extends State<WaterUsageReportPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final HistoryService _historyService = HistoryService();

  List<ZoneModel> _zones = [];
  String? _selectedZoneId;
  String _reportPeriod = 'month'; // week, month, year

  WaterUsageReport? _currentReport;
  WaterUsageReport? _previousReport;
  Map<String, dynamic>? _waterSavings;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  void _loadZones() async {
    final zones = await _firebaseService.getZonesStream().first;
    if (mounted) {
      setState(() {
        _zones = zones;
        if (_zones.isNotEmpty) {
          _selectedZoneId = _zones.first.id;
          _loadReport();
        } else {
          _isLoading = false;
        }
      });
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_reportPeriod) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      case 'year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  Future<void> _loadReport() async {
    if (_selectedZoneId == null) return;

    setState(() => _isLoading = true);

    try {
      final zone = _zones.firstWhere((z) => z.id == _selectedZoneId);
      final startDate = _getStartDate();
      final endDate = DateTime.now();

      // Get current and previous reports
      final reports = await _historyService.generateComparisonReport(
        zone.id,
        zone.name,
        startDate,
        endDate,
      );

      // Get water savings
      final savings = await _historyService.calculateWaterSavings(
        zone.id,
        startDate,
        endDate,
      );

      if (mounted) {
        setState(() {
          _currentReport = reports['current'];
          _previousReport = reports['previous'];
          _waterSavings = savings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Báo cáo tiêu thụ nước',
          style: TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _zones.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone & Period Selector
                      _buildSelectors(),

                      if (_currentReport != null) ...[
                        // Summary Card
                        _buildSummaryCard(),

                        // Comparison Card
                        if (_previousReport != null) _buildComparisonCard(),

                        // Source Breakdown
                        _buildSourceBreakdown(),

                        // Water Savings
                        if (_waterSavings != null) _buildWaterSavings(),

                        // Chart
                        _buildUsageChart(),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Selector
          const Text(
            'Chọn khu vực',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedZoneId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _zones.map((zone) {
              return DropdownMenuItem(
                value: zone.id,
                child: Text(
                  zone.name,
                  style: const TextStyle(fontFamily: 'SpaceGrotesk'),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedZoneId = value;
                _loadReport();
              });
            },
          ),

          const SizedBox(height: 16),

          // Period Selector
          const Text(
            'Khoảng thời gian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPeriodChip('7 ngày', 'week'),
              const SizedBox(width: 8),
              _buildPeriodChip('30 ngày', 'month'),
              const SizedBox(width: 8),
              _buildPeriodChip('1 năm', 'year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _reportPeriod == value;

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
            _reportPeriod = value;
            _loadReport();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00C1C4),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                _currentReport!.zoneName,
                style: const TextStyle(
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
                '${_currentReport!.totalLiters.toStringAsFixed(0)}L',
                'Tổng nước',
                Icons.opacity,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                '${_currentReport!.totalSessions}',
                'Số lần tưới',
                Icons.water_drop,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                '${_currentReport!.avgLitersPerSession.toStringAsFixed(1)}L',
                'TB/lần',
                Icons.analytics,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tổng thời gian: ${_currentReport!.totalMinutes} phút',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
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

  Widget _buildComparisonCard() {
    final comparison = _currentReport!.getComparisonPercentage(_previousReport);
    final isIncrease = comparison > 0;
    final isDecrease = comparison < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Colors.grey[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'So sánh với kỳ trước',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonItem(
                    'Kỳ trước',
                    '${_previousReport!.totalLiters.toStringAsFixed(0)}L',
                    Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonItem(
                    'Kỳ này',
                    '${_currentReport!.totalLiters.toStringAsFixed(0)}L',
                    const Color(0xFF00C1C4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIncrease
                    ? Colors.red[50]
                    : isDecrease
                        ? Colors.green[50]
                        : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isIncrease
                      ? Colors.red[200]!
                      : isDecrease
                          ? Colors.green[200]!
                          : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncrease
                        ? Icons.trending_up
                        : isDecrease
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: isIncrease
                        ? Colors.red[700]
                        : isDecrease
                            ? Colors.green[700]
                            : Colors.grey[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isIncrease
                          ? 'Tăng ${comparison.abs().toStringAsFixed(1)}% so với kỳ trước'
                          : isDecrease
                              ? 'Giảm ${comparison.abs().toStringAsFixed(1)}% so với kỳ trước'
                              : 'Không thay đổi so với kỳ trước',
                      style: TextStyle(
                        fontSize: 13,
                        color: isIncrease
                            ? Colors.red[900]
                            : isDecrease
                                ? Colors.green[900]
                                : Colors.grey[900],
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                      ),
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

  Widget _buildComparisonItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBreakdown() {
    final total = _currentReport!.totalSessions;
    final manual = _currentReport!.sourceBreakdown['manual'] ?? 0;
    final schedule = _currentReport!.sourceBreakdown['schedule'] ?? 0;
    final auto = _currentReport!.sourceBreakdown['auto'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.grey[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Phân loại theo nguồn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSourceItem('👤 Thủ công', manual, total, Colors.blue),
            const SizedBox(height: 12),
            _buildSourceItem('📅 Lịch trình', schedule, total, Colors.orange),
            const SizedBox(height: 12),
            _buildSourceItem('🤖 Tự động', auto, total, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            Text(
              '$count lần (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterSavings() {
    final savings = _waterSavings!['estimatedSavings'] as double;
    final savingsPercentage = _waterSavings!['savingsPercentage'] as double;

    if (savings <= 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Tiết kiệm nước nhờ tự động hóa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lượng nước tiết kiệm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${savings.toStringAsFixed(1)} lít',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${savingsPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tự động hóa giúp tối ưu lượng nước sử dụng dựa trên điều kiện thực tế',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    // Simple pie chart showing source distribution
    final manual = (_currentReport!.sourceBreakdown['manual'] ?? 0).toDouble();
    final schedule =
        (_currentReport!.sourceBreakdown['schedule'] ?? 0).toDouble();
    final auto = (_currentReport!.sourceBreakdown['auto'] ?? 0).toDouble();
    final total = manual + schedule + auto;

    if (total == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ phân bổ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (manual > 0)
                      PieChartSectionData(
                        value: manual,
                        title:
                            '${((manual / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.blue,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (schedule > 0)
                      PieChartSectionData(
                        value: schedule,
                        title:
                            '${((schedule / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.orange,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (auto > 0)
                      PieChartSectionData(
                        value: auto,
                        title: '${((auto / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.green,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
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
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có khu vực nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo khu vực để xem báo cáo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
