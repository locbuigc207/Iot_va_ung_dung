import 'dart:async';

import 'package:flutter/material.dart';

import '../models/leak_detection_model.dart';
import '../models/sensor_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class LeakDetectionService {
  static final LeakDetectionService _instance =
      LeakDetectionService._internal();
  factory LeakDetectionService() => _instance;
  LeakDetectionService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  final Map<String, StreamSubscription> _monitoringSubscriptions = {};
  final Map<String, Timer> _checkTimers = {};
  bool _isMonitoring = false;

  // Start monitoring all zones
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('🔍 Starting leak detection monitoring...');

    // Listen to all leak detections
    _firebaseService.getAllLeakDetectionsStream().listen((detections) {
      for (var detection in detections) {
        if (detection.isMonitoring) {
          _startZoneMonitoring(detection);
        } else {
          _stopZoneMonitoring(detection.zoneId);
        }
      }
    });
  }

  // Stop all monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    debugPrint('🛑 Stopping leak detection monitoring...');

    for (var subscription in _monitoringSubscriptions.values) {
      subscription.cancel();
    }
    _monitoringSubscriptions.clear();

    for (var timer in _checkTimers.values) {
      timer.cancel();
    }
    _checkTimers.clear();
  }

  // Start monitoring specific zone
  void _startZoneMonitoring(LeakDetectionModel detection) {
    final zoneId = detection.zoneId;

    // Cancel existing monitoring if any
    _stopZoneMonitoring(zoneId);

    debugPrint('🔍 Starting monitoring for zone: ${detection.zoneName}');

    // Monitor flow sensor readings every 30 seconds
    _checkTimers[zoneId] = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _checkForLeaks(detection),
    );

    // Listen to sensor updates
    _monitoringSubscriptions[zoneId] = _firebaseService
        .getSensorsStream(zoneId)
        .listen((sensors) => _processSensorData(detection, sensors));
  }

  // Stop monitoring specific zone
  void _stopZoneMonitoring(String zoneId) {
    _monitoringSubscriptions[zoneId]?.cancel();
    _monitoringSubscriptions.remove(zoneId);

    _checkTimers[zoneId]?.cancel();
    _checkTimers.remove(zoneId);

    debugPrint('🛑 Stopped monitoring for zone: $zoneId');
  }

  // Check for leaks
  Future<void> _checkForLeaks(LeakDetectionModel detection) async {
    try {
      final deviation = detection.getDeviationPercentage();
      LeakStatus newStatus = LeakStatus.normal;

      // Determine leak status based on deviation
      if (deviation > detection.leakThreshold * 2) {
        // Critical: deviation > 40% (if threshold is 20%)
        newStatus = LeakStatus.criticalLeak;
      } else if (deviation > detection.leakThreshold * 1.5) {
        // Leak detected: deviation > 30%
        newStatus = LeakStatus.leakDetected;
      } else if (deviation > detection.leakThreshold) {
        // Warning: deviation > 20%
        newStatus = LeakStatus.warning;
      } else {
        newStatus = LeakStatus.normal;
      }

      // Update status if changed
      if (newStatus != detection.status) {
        final updatedDetection = detection.copyWith(
          status: newStatus,
          lastCheck: DateTime.now(),
        );

        await _firebaseService.updateLeakDetection(updatedDetection);

        // Send notification if leak detected
        if (newStatus == LeakStatus.leakDetected ||
            newStatus == LeakStatus.criticalLeak) {
          await _notificationService.notifyLeakDetected(
            zoneName: detection.zoneName,
            message: _getLeakMessage(newStatus, deviation),
          );

          // Log alert
          final alert = LeakAlertModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            expectedFlow: detection.expectedFlowRate,
            actualFlow: detection.actualFlowRate,
            severity: _getSeverity(newStatus),
          );

          await _firebaseService.addLeakAlert(detection.zoneId, alert);
        }

        debugPrint(
            '⚠️ Leak status changed for ${detection.zoneName}: ${newStatus.name}');
      }
    } catch (e) {
      debugPrint('❌ Error checking for leaks: $e');
    }
  }

  // Process sensor data to detect anomalies
  void _processSensorData(
      LeakDetectionModel detection, List<SensorModel> sensors) {
    try {
      // Find flow sensor
      final flowSensor = sensors.firstWhere(
        (s) => s.type == SensorType.flow && s.isActive,
        orElse: () => sensors.first,
      );

      if (flowSensor.type != SensorType.flow) return;

      // Update actual flow rate
      final updatedDetection = detection.copyWith(
        actualFlowRate: flowSensor.currentValue,
        lastCheck: DateTime.now(),
      );

      _firebaseService.updateLeakDetection(updatedDetection);
    } catch (e) {
      debugPrint('❌ Error processing sensor data: $e');
    }
  }

  // Get leak message based on status
  String _getLeakMessage(LeakStatus status, double deviation) {
    switch (status) {
      case LeakStatus.criticalLeak:
        return 'RÒ RỈ NGHIÊM TRỌNG! Chênh lệch ${deviation.toStringAsFixed(1)}%. Tắt hệ thống ngay!';
      case LeakStatus.leakDetected:
        return 'Phát hiện rò rỉ! Chênh lệch ${deviation.toStringAsFixed(1)}%. Kiểm tra đường ống.';
      case LeakStatus.warning:
        return 'Cảnh báo: Chênh lệch ${deviation.toStringAsFixed(1)}% so với dự kiến.';
      default:
        return 'Hệ thống hoạt động bình thường';
    }
  }

  // Get severity from status
  LeakSeverity _getSeverity(LeakStatus status) {
    switch (status) {
      case LeakStatus.criticalLeak:
        return LeakSeverity.critical;
      case LeakStatus.leakDetected:
        return LeakSeverity.high;
      case LeakStatus.warning:
        return LeakSeverity.medium;
      default:
        return LeakSeverity.low;
    }
  }

  // Enable leak detection for a zone
  Future<void> enableLeakDetection({
    required String zoneId,
    required String zoneName,
    required double expectedFlowRate,
    double leakThreshold = 20.0,
  }) async {
    try {
      final detection = LeakDetectionModel(
        id: zoneId,
        zoneId: zoneId,
        zoneName: zoneName,
        isMonitoring: true,
        expectedFlowRate: expectedFlowRate,
        actualFlowRate: expectedFlowRate,
        leakThreshold: leakThreshold,
        lastCheck: DateTime.now(),
        status: LeakStatus.normal,
      );

      await _firebaseService.updateLeakDetection(detection);
      debugPrint('✅ Leak detection enabled for: $zoneName');
    } catch (e) {
      debugPrint('❌ Error enabling leak detection: $e');
    }
  }

  // Disable leak detection for a zone
  Future<void> disableLeakDetection(String zoneId) async {
    try {
      _stopZoneMonitoring(zoneId);

      final detection =
          await _firebaseService.getLeakDetectionStream(zoneId).first;

      if (detection != null) {
        final updatedDetection = detection.copyWith(
          isMonitoring: false,
          status: LeakStatus.inactive,
        );

        await _firebaseService.updateLeakDetection(updatedDetection);
        debugPrint('✅ Leak detection disabled for zone: $zoneId');
      }
    } catch (e) {
      debugPrint('❌ Error disabling leak detection: $e');
    }
  }

  // Get monitoring status for a zone
  Future<bool> isMonitoringZone(String zoneId) async {
    try {
      final detection =
          await _firebaseService.getLeakDetectionStream(zoneId).first;
      return detection?.isMonitoring ?? false;
    } catch (e) {
      return false;
    }
  }

  // Dispose
  void dispose() {
    stopMonitoring();
  }
}
