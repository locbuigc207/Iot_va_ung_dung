import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../models/leak_detection_model.dart';
import '../models/notification_model.dart';
import '../models/schedule_model.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/watering_history_model.dart';
import '../models/zone_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== ZONES ====================

  Stream<List<ZoneModel>> getZonesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _db
        .child('zones')
        .orderByChild('userId')
        .equalTo(currentUserId)
        .onValue
        .map((event) {
      final zones = <ZoneModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          zones.add(ZoneModel.fromMap(value, key));
        });
      }
      return zones;
    });
  }

  Future<String?> addZone(ZoneModel zone) async {
    if (currentUserId == null) return null;

    try {
      final ref = _db.child('zones').push();
      final zoneWithId = zone.copyWith();
      await ref.set(zoneWithId.toMap());
      debugPrint(
          '✅ Zone added: ${ref.key} (waiting for ESP32 to register device)');
      return ref.key;
    } catch (e) {
      debugPrint('❌ Error adding zone: $e');
      return null;
    }
  }

  Future<bool> updateZone(ZoneModel zone) async {
    try {
      await _db.child('zones/${zone.id}').update(zone.toMap());
      debugPrint('✅ Zone updated: ${zone.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating zone: $e');
      return false;
    }
  }

  Future<bool> deleteZone(String zoneId) async {
    try {
      await _db.child('zones/$zoneId').remove();

      final schedulesSnapshot = await _db
          .child('schedules')
          .orderByChild('zoneId')
          .equalTo(zoneId)
          .get();

      if (schedulesSnapshot.value != null) {
        final schedules =
            Map<dynamic, dynamic>.from(schedulesSnapshot.value as Map);
        for (var key in schedules.keys) {
          await _db.child('schedules/$key').remove();
        }
      }

      final devicesSnapshot = await _db
          .child('devices')
          .orderByChild('zoneId')
          .equalTo(zoneId)
          .get();

      if (devicesSnapshot.value != null) {
        final devices =
            Map<dynamic, dynamic>.from(devicesSnapshot.value as Map);
        for (var key in devices.keys) {
          await _db.child('devices/$key').remove();
        }
      }

      final sensorsSnapshot = await _db
          .child('sensors')
          .orderByChild('zoneId')
          .equalTo(zoneId)
          .get();

      if (sensorsSnapshot.value != null) {
        final sensors =
            Map<dynamic, dynamic>.from(sensorsSnapshot.value as Map);
        for (var key in sensors.keys) {
          await _db.child('sensors/$key').remove();
        }
      }

      debugPrint('✅ Zone deleted: $zoneId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting zone: $e');
      return false;
    }
  }

  Stream<DeviceModel?> getDeviceStream(String zoneId) {
    return _db
        .child('devices')
        .orderByChild('zoneId')
        .equalTo(zoneId)
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final entry = data.entries.first;
        return DeviceModel.fromMap(entry.value, entry.key);
      }
      return null;
    });
  }

  Future<void> linkDeviceToZone(String zoneId, String deviceId) async {
    try {
      await _db.child('zones/$zoneId').update({
        'deviceId': deviceId,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Device $deviceId linked to zone $zoneId');
    } catch (e) {
      debugPrint('❌ Error linking device to zone: $e');
      rethrow;
    }
  }

  Future<void> toggleAutoWatering(String zoneId, bool enabled) async {
    try {
      await _db.child('zones/$zoneId').update({
        'autoWateringEnabled': enabled,
        'autoWateringUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint(
          '✅ Auto watering ${enabled ? "enabled" : "disabled"} for zone $zoneId');
    } catch (e) {
      debugPrint('❌ Error toggling auto watering: $e');
      rethrow;
    }
  }

  Stream<List<DeviceModel>> getDevicesByUniqueIdPattern(String pattern) {
    return _db
        .child('devices')
        .orderByChild('uniqueId')
        .startAt(pattern)
        .endAt('$pattern\uf8ff')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <DeviceModel>[];

      final devicesMap =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return devicesMap.entries
          .map((entry) => DeviceModel.fromMap(
                Map<dynamic, dynamic>.from(entry.value),
                entry.key,
              ))
          .toList();
    });
  }

  Future<DeviceModel?> getDeviceByMAC(String mac) async {
    try {
      final snapshot = await _db
          .child('devices')
          .orderByChild('deviceMAC')
          .equalTo(mac)
          .once();

      if (snapshot.snapshot.value == null) return null;

      final devicesMap =
          Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      if (devicesMap.isEmpty) return null;

      final entry = devicesMap.entries.first;
      return DeviceModel.fromMap(
        Map<dynamic, dynamic>.from(entry.value),
        entry.key,
      );
    } catch (e) {
      debugPrint('❌ Error getting device by MAC: $e');
      return null;
    }
  }

  // ==================== DEVICE CONTROL ====================

  Future<bool> controlDevice(String deviceId, bool turnOn,
      {int? duration}) async {
    try {
      final updates = <String, dynamic>{
        'status': turnOn,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      if (turnOn) {
        updates['startTime'] = DateTime.now().millisecondsSinceEpoch;
        if (duration != null) {
          updates['currentDuration'] = duration * 60;
        }
      } else {
        updates['currentDuration'] = 0;
        updates['startTime'] = null;
      }

      await _db.child('devices/$deviceId').update(updates);
      debugPrint('✅ Device ${turnOn ? "turned ON" : "turned OFF"}: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Error controlling device: $e');
      return false;
    }
  }

  Future<void> updateDeviceDuration(String deviceId, int duration) async {
    try {
      await _db.child('devices/$deviceId').update({
        'currentDuration': duration,
      });
    } catch (e) {
      debugPrint('❌ Error updating duration: $e');
    }
  }

  // ==================== MODE CONTROL ====================

  /// Set device mode (manual/auto)
  Future<bool> setDeviceMode(String deviceId, String mode) async {
    try {
      await _db.child('devices/$deviceId').update({
        'mode': mode, // "manual" or "auto"
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Device mode set: $deviceId → $mode');
      return true;
    } catch (e) {
      debugPrint('❌ Error setting mode: $e');
      return false;
    }
  }

  /// Get current device mode
  Future<String> getDeviceMode(String deviceId) async {
    try {
      final snapshot = await _db.child('devices/$deviceId/mode').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }
      return 'auto'; // Default to auto
    } catch (e) {
      debugPrint('❌ Error getting mode: $e');
      return 'auto';
    }
  }

  /// Check if device is in forced auto mode
  Future<bool> isDeviceForcedAuto(String deviceId) async {
    try {
      final snapshot = await _db.child('devices/$deviceId/forcedAuto').get();
      if (snapshot.exists) {
        return snapshot.value as bool;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking forced auto: $e');
      return false;
    }
  }

  /// Clear forced auto status (when user manually intervenes)
  Future<void> clearForcedAuto(String deviceId) async {
    try {
      await _db.child('devices/$deviceId').update({
        'forcedAuto': false,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Forced auto cleared: $deviceId');
    } catch (e) {
      debugPrint('❌ Error clearing forced auto: $e');
    }
  }

  /// Enhanced control with mode management
  Future<bool> controlDeviceWithMode(
    String deviceId,
    bool turnOn, {
    int? duration,
    String? mode,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': turnOn,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      // Set mode if provided
      if (mode != null) {
        updates['mode'] = mode;
      }

      if (turnOn) {
        updates['startTime'] = DateTime.now().millisecondsSinceEpoch;
        if (duration != null) {
          updates['currentDuration'] = duration * 60; // Convert to seconds
        }
      } else {
        updates['currentDuration'] = 0;
        updates['startTime'] = null;
      }

      await _db.child('devices/$deviceId').update(updates);

      debugPrint(
          '✅ Device controlled: $deviceId → ${turnOn ? "ON" : "OFF"} (mode: $mode)');
      return true;
    } catch (e) {
      debugPrint('❌ Error controlling device: $e');
      return false;
    }
  }

  // ==================== SCHEDULES ====================

  Stream<List<ScheduleModel>> getSchedulesStream(String zoneId) {
    return _db
        .child('schedules')
        .orderByChild('zoneId')
        .equalTo(zoneId)
        .onValue
        .map((event) {
      final schedules = <ScheduleModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          schedules.add(ScheduleModel.fromMap(value, key));
        });
      }
      schedules.sort((a, b) => a.time.compareTo(b.time));
      return schedules;
    });
  }

  Stream<List<ScheduleModel>> getAllSchedulesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _db.child('schedules').onValue.map((event) {
      final schedules = <ScheduleModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          schedules.add(ScheduleModel.fromMap(value, key));
        });
      }
      schedules.sort((a, b) => a.time.compareTo(b.time));
      return schedules;
    });
  }

  Future<String?> addSchedule(ScheduleModel schedule) async {
    try {
      final ref = _db.child('schedules').push();
      await ref.set(schedule.toMap());
      debugPrint('✅ Schedule added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('❌ Error adding schedule: $e');
      return null;
    }
  }

  Future<bool> updateSchedule(ScheduleModel schedule) async {
    try {
      await _db.child('schedules/${schedule.id}').update(schedule.toMap());
      debugPrint('✅ Schedule updated: ${schedule.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> toggleSchedule(String scheduleId, bool enabled) async {
    try {
      await _db.child('schedules/$scheduleId').update({'enabled': enabled});
      debugPrint('✅ Schedule toggled: $scheduleId = $enabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error toggling schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _db.child('schedules/$scheduleId').remove();
      debugPrint('✅ Schedule deleted: $scheduleId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting schedule: $e');
      return false;
    }
  }

  // ==================== WATERING HISTORY ====================

  Future<void> logWateringEvent({
    required String zoneId,
    required String zoneName,
    required int duration,
    required String source,
  }) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final historyRef = _db.child('history/$monthKey/$zoneId');
      final snapshot = await historyRef.get();

      int totalSessions = 1;
      int totalDuration = duration;

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        totalSessions = (data['sessions'] ?? 0) + 1;
        totalDuration = (data['totalDuration'] ?? 0) + duration;
      }

      await historyRef.update({
        'zoneName': zoneName,
        'sessions': totalSessions,
        'totalDuration': totalDuration,
        'lastWatered': now.millisecondsSinceEpoch,
      });

      await _db.child('zones/$zoneId').update({
        'lastWatered': now.millisecondsSinceEpoch,
      });

      debugPrint('✅ Watering event logged for zone: $zoneId');
    } catch (e) {
      debugPrint('❌ Error logging watering event: $e');
    }
  }

  // ==================== SENSORS ====================

  Stream<List<SensorModel>> getSensorsStream(String zoneId) {
    return _db
        .child('sensors')
        .orderByChild('zoneId')
        .equalTo(zoneId)
        .onValue
        .map((event) {
      final sensors = <SensorModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          sensors.add(SensorModel.fromMap(value, key));
        });
      }
      return sensors;
    });
  }

  Stream<List<SensorModel>> getAllSensorsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _db.child('sensors').onValue.map((event) {
      final sensors = <SensorModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          sensors.add(SensorModel.fromMap(value, key));
        });
      }
      return sensors;
    });
  }

  Future<String?> addSensor(SensorModel sensor) async {
    try {
      final ref = _db.child('sensors').push();
      await ref.set(sensor.toMap());
      debugPrint('✅ Sensor added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('❌ Error adding sensor: $e');
      return null;
    }
  }

  Future<bool> updateSensor(SensorModel sensor) async {
    try {
      await _db.child('sensors/${sensor.id}').update(sensor.toMap());
      debugPrint('✅ Sensor updated: ${sensor.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating sensor: $e');
      return false;
    }
  }

  Future<bool> deleteSensor(String sensorId) async {
    try {
      await _db.child('sensors/$sensorId').remove();

      // Delete sensor readings
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        await _db.child('sensor_readings/$sensorId/$dateKey').remove();
      }

      debugPrint('✅ Sensor deleted: $sensorId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting sensor: $e');
      return false;
    }
  }

  // ==================== SENSOR READINGS ====================

  Stream<List<SensorReadingModel>> getSensorReadingsStream(
    String sensorId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dateKeys = <String>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      final dateKey =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      dateKeys.add(dateKey);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return _db.child('sensor_readings/$sensorId').onValue.map((event) {
      final readings = <SensorReadingModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

        for (var dateKey in dateKeys) {
          if (data.containsKey(dateKey)) {
            final dayData = Map<dynamic, dynamic>.from(data[dateKey]);
            dayData.forEach((key, value) {
              final reading = SensorReadingModel.fromMap(value, key);
              if (reading.timestamp.isAfter(startDate) &&
                  reading.timestamp.isBefore(endDate)) {
                readings.add(reading);
              }
            });
          }
        }
      }

      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return readings;
    });
  }

  Future<void> addSensorReading(SensorReadingModel reading) async {
    try {
      final dateKey = '${reading.timestamp.year}'
          '-${reading.timestamp.month.toString().padLeft(2, '0')}'
          '-${reading.timestamp.day.toString().padLeft(2, '0')}';

      final timestampKey = reading.timestamp.millisecondsSinceEpoch.toString();

      final ref = _db
          .child('sensor_readings/${reading.sensorId}/$dateKey/$timestampKey');

      await ref.set(reading.toMap());

      await _db.child('sensors/${reading.sensorId}').update({
        'currentValue': reading.value,
        'lastUpdated': reading.timestamp.millisecondsSinceEpoch,
      });

      debugPrint('✅ Sensor reading added: ${reading.sensorId} at $dateKey');
    } catch (e) {
      debugPrint('❌ Error adding sensor reading: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  Stream<List<NotificationModel>> getNotificationsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _db
        .child('notifications/$currentUserId')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((event) {
      final notifications = <NotificationModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          notifications.add(NotificationModel.fromMap(value, key));
        });
      }
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  Future<String?> addNotification(NotificationModel notification) async {
    if (currentUserId == null) return null;

    try {
      final ref = _db.child('notifications/$currentUserId').push();
      await ref.set(notification.toMap());
      debugPrint('✅ Notification added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('❌ Error adding notification: $e');
      return null;
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) return false;

    try {
      await _db
          .child('notifications/$currentUserId/$notificationId')
          .update({'isRead': true});
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    if (currentUserId == null) return false;

    try {
      await _db.child('notifications/$currentUserId/$notificationId').remove();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  Future<void> clearAllNotifications() async {
    if (currentUserId == null) return;

    try {
      await _db.child('notifications/$currentUserId').remove();
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // ==================== LEAK DETECTION ====================

  Stream<LeakDetectionModel?> getLeakDetectionStream(String zoneId) {
    return _db.child('leak_detection/$zoneId').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        return LeakDetectionModel.fromMap(data, zoneId);
      }
      return null;
    });
  }

  Stream<List<LeakDetectionModel>> getAllLeakDetectionsStream() {
    return _db.child('leak_detection').onValue.map((event) {
      final detections = <LeakDetectionModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          detections.add(LeakDetectionModel.fromMap(value, key));
        });
      }
      return detections;
    });
  }

  Future<bool> updateLeakDetection(LeakDetectionModel detection) async {
    try {
      await _db
          .child('leak_detection/${detection.zoneId}')
          .set(detection.toMap());
      debugPrint('✅ Leak detection updated: ${detection.zoneId}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating leak detection: $e');
      return false;
    }
  }

  Future<void> addLeakAlert(String zoneId, LeakAlertModel alert) async {
    try {
      await _db
          .child('leak_detection/$zoneId/alerts/${alert.id}')
          .set(alert.toMap());
      debugPrint('✅ Leak alert added: $zoneId');
    } catch (e) {
      debugPrint('❌ Error adding leak alert: $e');
    }
  }

  // ==================== SCHEDULE SKIP INFO (for Weather Auto-Skip) ====================

  Future<void> updateScheduleSkipInfo(
    String scheduleId,
    Map<String, dynamic> skipInfo,
  ) async {
    try {
      await _db.child('schedule_skip_info/$scheduleId').set(skipInfo);
      debugPrint('✅ Schedule skip info updated: $scheduleId');
    } catch (e) {
      debugPrint('❌ Error updating schedule skip info: $e');
    }
  }

  Future<Map<String, dynamic>?> getScheduleSkipInfo(String scheduleId) async {
    try {
      final snapshot = await _db.child('schedule_skip_info/$scheduleId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting schedule skip info: $e');
      return null;
    }
  }

  Future<void> clearScheduleSkipInfo(String scheduleId) async {
    try {
      await _db.child('schedule_skip_info/$scheduleId').remove();
      debugPrint('✅ Schedule skip info cleared: $scheduleId');
    } catch (e) {
      debugPrint('❌ Error clearing schedule skip info: $e');
    }
  }

  // ==================== AUTO WATERING (for Soil Moisture Auto) ====================

  Future<void> updateZoneAutoWatering(String zoneId, bool enabled) async {
    try {
      await _db.child('zones/$zoneId').update({
        'autoWateringEnabled': enabled,
        'autoWateringUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Zone auto watering updated: $zoneId = $enabled');
    } catch (e) {
      debugPrint('❌ Error updating zone auto watering: $e');
    }
  }

  Future<bool> isZoneAutoWateringEnabled(String zoneId) async {
    try {
      final snapshot =
          await _db.child('zones/$zoneId/autoWateringEnabled').get();
      if (snapshot.exists) {
        return snapshot.value as bool;
      }
      return false; // Default to disabled
    } catch (e) {
      debugPrint('❌ Error checking auto watering status: $e');
      return false;
    }
  }

  // ==================== WATERING HISTORY (PHASE 4) ====================

  Stream<List<WateringHistoryModel>> getWateringHistoryStream({
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    Query query = _db.child('watering_history');

    if (zoneId != null) {
      query = query.orderByChild('zoneId').equalTo(zoneId);
    }

    return query.onValue.map((event) {
      final history = <WateringHistoryModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final record = WateringHistoryModel.fromMap(value, key);
          if (record.startTime.isAfter(start) &&
              record.startTime.isBefore(end)) {
            history.add(record);
          }
        });
      }
      history.sort((a, b) => b.startTime.compareTo(a.startTime));
      return history;
    });
  }

  Stream<List<WateringHistoryModel>> getAllWateringHistoryStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getWateringHistoryStream(startDate: startDate, endDate: endDate);
  }

  Future<void> logWateringHistory(WateringHistoryModel history) async {
    try {
      final historyId =
          '${history.startTime.millisecondsSinceEpoch ~/ 1000}_${history.zoneId}';

      final ref = _db.child('watering_history/$historyId');

      final data = {
        'zoneId': history.zoneId,
        'zoneName': history.zoneName,
        'startTime': history.startTime.millisecondsSinceEpoch,
        'endTime': history.endTime.millisecondsSinceEpoch,
        'duration': history.duration,
        'waterUsed': history.waterUsed,
        'source': history.source,
        'completed': history.completed,
        if (history.notes != null) 'notes': history.notes,
      };

      await ref.set(data);
      debugPrint('✅ Watering history logged: ${history.zoneName} ($historyId)');
    } catch (e) {
      debugPrint('❌ Error logging history: $e');
    }
  }

  // ==================== PLANT LIBRARY (PHASE 4) ====================

  Stream<List<PlantProfileModel>> getAllPlantProfilesStream() {
    return _db.child('plant_library').onValue.map((event) {
      final plants = <PlantProfileModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          plants.add(PlantProfileModel.fromMap(value, key));
        });
      }
      return plants;
    });
  }

  Stream<List<PlantProfileModel>> getPlantProfilesByCategoryStream(
      String category) {
    return _db
        .child('plant_library')
        .orderByChild('category')
        .equalTo(category)
        .onValue
        .map((event) {
      final plants = <PlantProfileModel>[];
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          plants.add(PlantProfileModel.fromMap(value, key));
        });
      }
      return plants;
    });
  }

  Future<PlantProfileModel?> getPlantProfile(String plantId) async {
    try {
      final snapshot = await _db.child('plant_library/$plantId').get();
      if (snapshot.exists) {
        return PlantProfileModel.fromMap(
          Map<dynamic, dynamic>.from(snapshot.value as Map),
          plantId,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting plant profile: $e');
      return null;
    }
  }

  Future<void> addPlantProfile(PlantProfileModel plant) async {
    try {
      await _db.child('plant_library/${plant.id}').set(plant.toMap());
      debugPrint('✅ Plant profile added: ${plant.name}');
    } catch (e) {
      debugPrint('❌ Error adding plant profile: $e');
    }
  }

  // ==================== ZONE PROFILES (PHASE 4) ====================

  Future<ZoneProfileModel?> getZoneProfile(String zoneId) async {
    try {
      final snapshot = await _db.child('zone_profiles/$zoneId').get();
      if (snapshot.exists) {
        return ZoneProfileModel.fromMap(
          Map<dynamic, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting zone profile: $e');
      return null;
    }
  }

  Future<void> saveZoneProfile(ZoneProfileModel profile) async {
    try {
      await _db.child('zone_profiles/${profile.zoneId}').set(profile.toMap());
      debugPrint('✅ Zone profile saved: ${profile.zoneId}');
    } catch (e) {
      debugPrint('❌ Error saving zone profile: $e');
    }
  }
}
