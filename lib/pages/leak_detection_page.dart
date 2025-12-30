import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/leak_detection_model.dart';
import '../services/firebase_service.dart';
import '../services/leak_detection_service.dart';

class LeakDetectionPage extends StatefulWidget {
  const LeakDetectionPage({Key? key}) : super(key: key);

  @override
  State<LeakDetectionPage> createState() => _LeakDetectionPageState();
}

class _LeakDetectionPageState extends State<LeakDetectionPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final LeakDetectionService _leakService = LeakDetectionService();

  List<LeakDetectionModel> _detections = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadDetections();
    _leakService.startMonitoring();
  }

  void _loadDetections() {
    _subscription?.cancel();
    _subscription =
        _firebaseService.getAllLeakDetectionsStream().listen((detections) {
      if (!mounted) return;
      setState(() => _detections = detections);
    });
  }

  Future<void> _toggleMonitoring(LeakDetectionModel detection) async {
    if (detection.isMonitoring) {
      await _leakService.disableLeakDetection(detection.zoneId);
    } else {
      await _leakService.enableLeakDetection(
        zoneId: detection.zoneId,
        zoneName: detection.zoneName,
        expectedFlowRate: detection.expectedFlowRate,
        leakThreshold: detection.leakThreshold,
      );
    }
  }

  Future<void> _showSettings(LeakDetectionModel detection) async {
    double expectedFlow = detection.expectedFlowRate;
    double threshold = detection.leakThreshold;

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cài đặt phát hiện rò rỉ',
            style: TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detection.zoneName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 24),

              // Expected Flow Rate
              Text(
                'Lưu lượng dự kiến: ${expectedFlow.toStringAsFixed(1)} L/min',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              Slider(
                value: expectedFlow,
                min: 1,
                max: 20,
                divisions: 190,
                activeColor: const Color(0xFF00C1C4),
                onChanged: (value) {
                  setState(() => expectedFlow = value);
                },
              ),

              const SizedBox(height: 16),

              // Leak Threshold
              Text(
                'Ngưỡng cảnh báo: ${threshold.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              Slider(
                value: threshold,
                min: 5,
                max: 50,
                divisions: 45,
                activeColor: const Color(0xFF00C1C4),
                onChanged: (value) {
                  setState(() => threshold = value);
                },
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hệ thống sẽ cảnh báo khi chênh lệch lưu lượng vượt quá ${threshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'expectedFlow': expectedFlow,
                  'threshold': threshold,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1C4),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedDetection = LeakDetectionModel(
        id: detection.id,
        zoneId: detection.zoneId,
        zoneName: detection.zoneName,
        isMonitoring: detection.isMonitoring,
        expectedFlowRate: result['expectedFlow']!,
        actualFlowRate: detection.actualFlowRate,
        leakThreshold: result['threshold']!,
        lastCheck: DateTime.now(),
        status: detection.status,
      );

      await _firebaseService.updateLeakDetection(updatedDetection);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật cài đặt'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMonitoring = _detections.where((d) => d.isMonitoring).length;
    final leaksDetected = _detections.where((d) => d.hasLeak()).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phát hiện rò rỉ',
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
                const Row(
                  children: [
                    Icon(Icons.water_damage, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Hệ thống phát hiện rò rỉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard(
                      '${_detections.length}',
                      'Tổng số',
                      Icons.dashboard,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '$activeMonitoring',
                      'Đang theo dõi',
                      Icons.visibility,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '$leaksDetected',
                      'Rò rỉ',
                      Icons.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Card
          if (leaksDetected > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Phát hiện $leaksDetected vùng có rò rỉ. Vui lòng kiểm tra ngay!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Detections List
          Expanded(
            child: _detections.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _detections.length,
                    itemBuilder: (context, index) {
                      final detection = _detections[index];
                      return _buildDetectionCard(detection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionCard(LeakDetectionModel detection) {
    final statusColor = Color(
      int.parse(detection.getStatusColor().substring(1), radix: 16) +
          0xFF000000,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: detection.hasLeak() ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: detection.hasLeak() ? statusColor : Colors.grey[300]!,
          width: detection.hasLeak() ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    detection.hasLeak() ? Icons.water_damage : Icons.water_drop,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.zoneName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          detection.getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: detection.isMonitoring,
                    activeColor: const Color(0xFF00C1C4),
                    onChanged: (value) => _toggleMonitoring(detection),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: () => _showSettings(detection),
                  color: Colors.grey[600],
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Dự kiến',
                    '${detection.expectedFlowRate.toStringAsFixed(1)} L/min',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetric(
                    'Thực tế',
                    '${detection.actualFlowRate.toStringAsFixed(1)} L/min',
                    Icons.water,
                    statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deviation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chênh lệch',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  Text(
                    '${detection.getDeviationPercentage().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Last Check
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Kiểm tra lần cuối: ${DateFormat('dd/MM HH:mm').format(detection.lastCheck)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),

            // Recommendation
            if (detection.hasLeak()) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detection.getRecommendation(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[900],
                          fontWeight: FontWeight.w600,
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

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
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
              Icons.water_drop_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có hệ thống phát hiện rò rỉ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm cảm biến lưu lượng để bật tính năng này',
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
