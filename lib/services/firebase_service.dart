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
      await _createDevice(ref.key!, zone.name);
      debugPrint('Zone added successfully: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('Error adding zone: $e');
      return null;
    }
  }

  Future<bool> updateZone(ZoneModel zone) async {
    try {
      await _db.child('zones/${zone.id}').update(zone.toMap());
      debugPrint('Zone updated: ${zone.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating zone: $e');
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

      // ✅ NEW: Delete sensors
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

      debugPrint('Zone deleted: $zoneId');
      return true;
    } catch (e) {
      debugPrint('Error deleting zone: $e');
      return false;
    }
  }

  // ==================== DEVICES ====================

  Future<void> _createDevice(String zoneId, String zoneName) async {
    try {
      final deviceRef = _db.child('devices').push();
      final device = DeviceModel(
        id: deviceRef.key!,
        name: 'Pump - $zoneName',
        zoneId: zoneId,
        type: 'pump',
        status: false,
        lastUpdated: DateTime.now(),
        flowRate: 5.0,
      );
      await deviceRef.set(device.toMap());
    } catch (e) {
      debugPrint('Error creating device: $e');
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
      debugPrint('Device ${turnOn ? "turned ON" : "turned OFF"}: $deviceId');
      return true;
    } catch (e) {
      debugPrint('Error controlling device: $e');
      return false;
    }
  }

  Future<void> updateDeviceDuration(String deviceId, int duration) async {
    try {
      await _db.child('devices/$deviceId').update({
        'currentDuration': duration,
      });
    } catch (e) {
      debugPrint('Error updating duration: $e');
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
      debugPrint('Schedule added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('Error adding schedule: $e');
      return null;
    }
  }

  Future<bool> updateSchedule(ScheduleModel schedule) async {
    try {
      await _db.child('schedules/${schedule.id}').update(schedule.toMap());
      debugPrint('Schedule updated: ${schedule.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> toggleSchedule(String scheduleId, bool enabled) async {
    try {
      await _db.child('schedules/$scheduleId').update({'enabled': enabled});
      debugPrint('Schedule toggled: $scheduleId = $enabled');
      return true;
    } catch (e) {
      debugPrint('Error toggling schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _db.child('schedules/$scheduleId').remove();
      debugPrint('Schedule deleted: $scheduleId');
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
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

      debugPrint('Watering event logged for zone: $zoneId');
    } catch (e) {
      debugPrint('Error logging watering event: $e');
    }
  }

  // ==================== ✅ NEW: SENSORS ====================

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
      debugPrint('Sensor added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('Error adding sensor: $e');
      return null;
    }
  }

  Future<bool> updateSensor(SensorModel sensor) async {
    try {
      await _db.child('sensors/${sensor.id}').update(sensor.toMap());
      debugPrint('Sensor updated: ${sensor.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating sensor: $e');
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

      debugPrint('Sensor deleted: $sensorId');
      return true;
    } catch (e) {
      debugPrint('Error deleting sensor: $e');
      return false;
    }
  }

  // ==================== ✅ NEW: SENSOR READINGS ====================

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
      final dateKey =
          '${reading.timestamp.year}-${reading.timestamp.month.toString().padLeft(2, '0')}-${reading.timestamp.day.toString().padLeft(2, '0')}';

      final ref = _db.child(
          'sensor_readings/${reading.sensorId}/$dateKey/${reading.timestamp.millisecondsSinceEpoch}');
      await ref.set(reading.toMap());

      // Update sensor current value
      await _db.child('sensors/${reading.sensorId}').update({
        'currentValue': reading.value,
        'lastUpdated': reading.timestamp.millisecondsSinceEpoch,
      });

      debugPrint('Sensor reading added: ${reading.sensorId}');
    } catch (e) {
      debugPrint('Error adding sensor reading: $e');
    }
  }

  // ==================== ✅ NEW: NOTIFICATIONS ====================

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
      debugPrint('Notification added: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('Error adding notification: $e');
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
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    if (currentUserId == null) return false;

    try {
      await _db.child('notifications/$currentUserId/$notificationId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  Future<void> clearAllNotifications() async {
    if (currentUserId == null) return;

    try {
      await _db.child('notifications/$currentUserId').remove();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // ==================== ✅ NEW: LEAK DETECTION ====================

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
      debugPrint('Leak detection updated: ${detection.zoneId}');
      return true;
    } catch (e) {
      debugPrint('Error updating leak detection: $e');
      return false;
    }
  }

  Future<void> addLeakAlert(String zoneId, LeakAlertModel alert) async {
    try {
      await _db
          .child('leak_detection/$zoneId/alerts/${alert.id}')
          .set(alert.toMap());
      debugPrint('Leak alert added: $zoneId');
    } catch (e) {
      debugPrint('Error adding leak alert: $e');
    }
  }
}
