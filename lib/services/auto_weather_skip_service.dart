import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';

class AutoWeatherSkipService {
  static final AutoWeatherSkipService _instance =
      AutoWeatherSkipService._internal();
  factory AutoWeatherSkipService() => _instance;
  AutoWeatherSkipService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();

  Timer? _checkTimer;
  bool _isMonitoring = false;

  // Start monitoring schedules for weather-based skipping
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('🌦️ Starting auto weather skip monitoring...');

    // Start weather auto-update
    _weatherService.startAutoUpdate();

    // Check every hour
    _checkTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _checkAllSchedules(),
    );

    // Do initial check
    await _checkAllSchedules();
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _checkTimer?.cancel();
    _checkTimer = null;
    debugPrint('🛑 Auto weather skip monitoring stopped');
  }

  // Check all schedules with weather skip enabled
  Future<void> _checkAllSchedules() async {
    try {
      debugPrint('🔍 Checking schedules for weather skip...');

      // Get all schedules
      final schedules = await _firebaseService.getAllSchedulesStream().first;

      // Filter schedules with weather skip enabled
      final weatherSkipSchedules =
          schedules.where((s) => s.weatherSkip && s.enabled).toList();

      debugPrint(
          '📋 Found ${weatherSkipSchedules.length} schedules with weather skip');

      for (var schedule in weatherSkipSchedules) {
        await _checkSchedule(schedule);
      }
    } catch (e) {
      debugPrint('❌ Error checking schedules: $e');
    }
  }

  // Check individual schedule
  Future<void> _checkSchedule(ScheduleModel schedule) async {
    try {
      final nextRun = schedule.getNextRunTime();
      if (nextRun == null) return;

      final now = DateTime.now();
      final hoursUntilRun = nextRun.difference(now).inHours;

      // Only check if schedule is within next 24 hours
      if (hoursUntilRun < 0 || hoursUntilRun > 24) return;

      // Check if it will rain
      final willRain = await _weatherService.willRainIn24Hours();
      final rainProbability = await _weatherService.getRainProbability24Hours();

      if (willRain || rainProbability > 60) {
        debugPrint(
            '🌧️ Rain detected for ${schedule.zoneName} (probability: ${rainProbability.toStringAsFixed(0)}%)');

        // Disable schedule temporarily (will re-enable after rain passes)
        await _temporarilyDisableSchedule(schedule, rainProbability);

        // Notify user
        await _notificationService.notifyScheduleSkipped(
          zoneName: schedule.zoneName,
          scheduledTime: schedule.time,
          reason: 'Dự báo mưa ${rainProbability.toStringAsFixed(0)}%',
        );
      } else {
        // Re-enable if it was temporarily disabled
        await _reEnableScheduleIfNeeded(schedule);
      }
    } catch (e) {
      debugPrint('❌ Error checking schedule ${schedule.id}: $e');
    }
  }

  // Temporarily disable schedule due to rain
  Future<void> _temporarilyDisableSchedule(
    ScheduleModel schedule,
    double rainProbability,
  ) async {
    try {
      // Store original state in Firebase for later restoration
      await _firebaseService.updateSchedule(
        schedule.copyWith(enabled: false),
      );

      // Store skip info
      await _storeSkipInfo(
        schedule.id,
        rainProbability,
        DateTime.now(),
      );

      debugPrint('✅ Temporarily disabled schedule: ${schedule.zoneName}');
    } catch (e) {
      debugPrint('❌ Error disabling schedule: $e');
    }
  }

  // Re-enable schedule if weather cleared
  Future<void> _reEnableScheduleIfNeeded(ScheduleModel schedule) async {
    try {
      // Check if schedule was auto-disabled
      final skipInfo = await _getSkipInfo(schedule.id);
      if (skipInfo == null) return;

      final wasAutoDisabled = skipInfo['autoDisabled'] == true;
      if (!wasAutoDisabled) return;

      // Check if enough time has passed (at least 6 hours)
      final disabledAt = DateTime.fromMillisecondsSinceEpoch(
        skipInfo['timestamp'] ?? 0,
      );
      final hoursSinceDisabled = DateTime.now().difference(disabledAt).inHours;

      if (hoursSinceDisabled < 6) return;

      // Re-enable schedule
      await _firebaseService.updateSchedule(
        schedule.copyWith(enabled: true),
      );

      // Clear skip info
      await _clearSkipInfo(schedule.id);

      // Notify user
      await _notificationService.notifyScheduleReEnabled(
        zoneName: schedule.zoneName,
        scheduledTime: schedule.time,
      );

      debugPrint('✅ Re-enabled schedule: ${schedule.zoneName}');
    } catch (e) {
      debugPrint('❌ Error re-enabling schedule: $e');
    }
  }

  // Store skip info in Firebase
  Future<void> _storeSkipInfo(
    String scheduleId,
    double rainProbability,
    DateTime timestamp,
  ) async {
    try {
      final db = _firebaseService;
      await db.updateScheduleSkipInfo(
        scheduleId,
        {
          'autoDisabled': true,
          'rainProbability': rainProbability,
          'timestamp': timestamp.millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Error storing skip info: $e');
    }
  }

  // Get skip info from Firebase
  Future<Map<String, dynamic>?> _getSkipInfo(String scheduleId) async {
    try {
      final db = _firebaseService;
      return await db.getScheduleSkipInfo(scheduleId);
    } catch (e) {
      debugPrint('Error getting skip info: $e');
      return null;
    }
  }

  // Clear skip info
  Future<void> _clearSkipInfo(String scheduleId) async {
    try {
      final db = _firebaseService;
      await db.clearScheduleSkipInfo(scheduleId);
    } catch (e) {
      debugPrint('Error clearing skip info: $e');
    }
  }

  // Manual check for a specific schedule
  Future<bool> shouldSkipSchedule(ScheduleModel schedule) async {
    if (!schedule.weatherSkip) return false;

    try {
      final willRain = await _weatherService.willRainIn24Hours();
      final rainProbability = await _weatherService.getRainProbability24Hours();

      return willRain || rainProbability > 60;
    } catch (e) {
      debugPrint('Error checking weather for schedule: $e');
      return false;
    }
  }

  // Dispose
  void dispose() {
    stopMonitoring();
  }
}
