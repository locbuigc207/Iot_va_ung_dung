import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_model.dart';
import '../models/zone_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'weather_service.dart';

class SoilMoistureAutoService {
  static final SoilMoistureAutoService _instance =
      SoilMoistureAutoService._internal();
  factory SoilMoistureAutoService() => _instance;
  SoilMoistureAutoService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final WeatherService _weatherService = WeatherService();

  final Map<String, StreamSubscription> _sensorSubscriptions = {};
  final Map<String, DateTime> _lastWateringTime = {};
  bool _isMonitoring = false;

  // Minimum time between auto waterings (hours)
  static const int _minHoursBetweenWatering = 6;

  // Start monitoring all zones
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('💧 Starting soil moisture auto watering monitoring...');

    // Listen to all zones
    _firebaseService.getZonesStream().listen((zones) {
      for (var zone in zones) {
        _startZoneMonitoring(zone);
      }
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;

    for (var subscription in _sensorSubscriptions.values) {
      subscription.cancel();
    }
    _sensorSubscriptions.clear();
    _lastWateringTime.clear();

    debugPrint('🛑 Soil moisture monitoring stopped');
  }

  // Start monitoring specific zone
  void _startZoneMonitoring(ZoneModel zone) {
    // Cancel existing subscription
    _sensorSubscriptions[zone.id]?.cancel();

    debugPrint('👀 Monitoring soil moisture for: ${zone.name}');

    // Listen to zone's sensors
    _sensorSubscriptions[zone.id] = _firebaseService
        .getSensorsStream(zone.id)
        .listen((sensors) => _checkSensors(zone, sensors));
  }

  // Check sensors and trigger auto watering if needed
  Future<void> _checkSensors(ZoneModel zone, List<SensorModel> sensors) async {
    try {
      // Find soil moisture sensor
      final moistureSensor = sensors.firstWhere(
        (s) => s.type == SensorType.soilMoisture && s.isActive,
        orElse: () => sensors.first,
      );

      if (moistureSensor.type != SensorType.soilMoisture) return;

      // Check if moisture is below threshold
      if (moistureSensor.currentValue >= moistureSensor.minThreshold) return;

      // Check if enough time has passed since last watering
      if (!_canWaterNow(zone.id)) {
        debugPrint('⏳ Too soon to water ${zone.name} - waiting for cooldown');
        return;
      }

      // Check weather - don't water if rain is coming
      final willRain = await _weatherService.willRainIn24Hours();
      if (willRain) {
        debugPrint('🌧️ Skipping auto watering for ${zone.name} - rain coming');
        await _notificationService.notifyAutoWateringSkipped(
          zoneName: zone.name,
          reason: 'Dự báo mưa trong 24h tới',
        );
        return;
      }

      // Trigger auto watering
      await _triggerAutoWatering(zone, moistureSensor);
    } catch (e) {
      debugPrint('❌ Error checking sensors for ${zone.name}: $e');
    }
  }

  // Check if enough time has passed to water again
  bool _canWaterNow(String zoneId) {
    final lastWatering = _lastWateringTime[zoneId];
    if (lastWatering == null) return true;

    final hoursSinceLastWatering =
        DateTime.now().difference(lastWatering).inHours;
    return hoursSinceLastWatering >= _minHoursBetweenWatering;
  }

  // Trigger auto watering
  Future<void> _triggerAutoWatering(
    ZoneModel zone,
    SensorModel sensor,
  ) async {
    try {
      debugPrint(
          '💦 Triggering auto watering for ${zone.name} (moisture: ${sensor.currentValue.toStringAsFixed(1)}%)');

      // Calculate duration based on soil type and moisture deficit
      final duration = _calculateDuration(
        currentMoisture: sensor.currentValue,
        targetMoisture: sensor.minThreshold + 10, // Slightly above threshold
        soilType: zone.soilType,
      );

      // Apply weather and seasonal adjustments
      final adjustedDuration = await _weatherService.calculateAdjustedDuration(
        baseDuration: duration,
      );

      // Get device for this zone
      final device = await _firebaseService.getDeviceStream(zone.id).first;

      if (device == null) {
        debugPrint('❌ No device found for zone: ${zone.name}');
        return;
      }

      // Turn on watering
      final success = await _firebaseService.controlDevice(
        device.id,
        true,
        duration: adjustedDuration,
      );

      if (success) {
        // Record last watering time
        _lastWateringTime[zone.id] = DateTime.now();

        // Send notification
        await _notificationService.notifyAutoWateringStarted(
          zoneName: zone.name,
          duration: adjustedDuration,
          reason: 'Độ ẩm đất thấp (${sensor.currentValue.toStringAsFixed(1)}%)',
        );

        debugPrint(
            '✅ Auto watering started for ${zone.name}: $adjustedDuration minutes');
      } else {
        debugPrint('❌ Failed to start auto watering for ${zone.name}');
      }
    } catch (e) {
      debugPrint('❌ Error triggering auto watering: $e');
    }
  }

  // Calculate watering duration based on soil conditions
  int _calculateDuration({
    required double currentMoisture,
    required double targetMoisture,
    required String soilType,
  }) {
    // Calculate moisture deficit
    final deficit = targetMoisture - currentMoisture;

    // Base duration per 1% moisture increase (minutes)
    double baseDuration = 0.5;

    // Adjust for soil type
    switch (soilType) {
      case 'clay':
        // Clay holds water well but absorbs slowly
        baseDuration = 0.6;
        break;
      case 'sand':
        // Sand drains quickly, needs more water
        baseDuration = 0.7;
        break;
      case 'loam':
        // Ideal soil
        baseDuration = 0.5;
        break;
    }

    // Calculate total duration
    int duration = (deficit * baseDuration).round();

    // Ensure reasonable limits
    if (duration < 5) duration = 5; // Minimum 5 minutes
    if (duration > 30) duration = 30; // Maximum 30 minutes

    return duration;
  }

  // Enable auto watering for a zone
  Future<void> enableAutoWatering(String zoneId) async {
    try {
      await _firebaseService.updateZoneAutoWatering(zoneId, true);
      debugPrint('✅ Auto watering enabled for zone: $zoneId');
    } catch (e) {
      debugPrint('❌ Error enabling auto watering: $e');
    }
  }

  // Disable auto watering for a zone
  Future<void> disableAutoWatering(String zoneId) async {
    try {
      await _firebaseService.updateZoneAutoWatering(zoneId, false);
      _sensorSubscriptions[zoneId]?.cancel();
      _sensorSubscriptions.remove(zoneId);
      _lastWateringTime.remove(zoneId);
      debugPrint('✅ Auto watering disabled for zone: $zoneId');
    } catch (e) {
      debugPrint('❌ Error disabling auto watering: $e');
    }
  }

  // Get auto watering status
  Future<bool> isAutoWateringEnabled(String zoneId) async {
    try {
      return await _firebaseService.isZoneAutoWateringEnabled(zoneId);
    } catch (e) {
      return false;
    }
  }

  // Manually trigger moisture check
  Future<void> checkZoneNow(String zoneId) async {
    try {
      final zone = await _firebaseService.getZonesStream().first.then(
            (zones) => zones.firstWhere((z) => z.id == zoneId),
          );

      final sensors = await _firebaseService.getSensorsStream(zoneId).first;

      await _checkSensors(zone, sensors);
    } catch (e) {
      debugPrint('Error checking zone: $e');
    }
  }

  // Dispose
  void dispose() {
    stopMonitoring();
  }
}
