import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../models/schedule_model.dart';
import '../models/zone_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== ZONES ====================

  // Get all zones for current user
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

  // Add new zone
  Future<String?> addZone(ZoneModel zone) async {
    if (currentUserId == null) return null;

    try {
      final ref = _db.child('zones').push();
      final zoneWithId = zone.copyWith();
      await ref.set(zoneWithId.toMap());

      // Also create corresponding device
      await _createDevice(ref.key!, zone.name);

      debugPrint('Zone added successfully: ${ref.key}');
      return ref.key;
    } catch (e) {
      debugPrint('Error adding zone: $e');
      return null;
    }
  }

  // Update zone
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

  // Delete zone
  Future<bool> deleteZone(String zoneId) async {
    try {
      // Delete zone
      await _db.child('zones/$zoneId').remove();

      // Delete associated schedules
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

      // Delete associated device
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

      debugPrint('Zone deleted: $zoneId');
      return true;
    } catch (e) {
      debugPrint('Error deleting zone: $e');
      return false;
    }
  }

  // ==================== DEVICES ====================

  // Create device for zone
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
        flowRate: 5.0, // Default 5 liters/minute
      );
      await deviceRef.set(device.toMap());
    } catch (e) {
      debugPrint('Error creating device: $e');
    }
  }

  // Get device for zone
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

  // Control device (ON/OFF)
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
          updates['currentDuration'] = duration * 60; // Convert to seconds
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

  // Update device duration countdown (called from timer)
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

  // Get schedules for zone
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
      // Sort by time
      schedules.sort((a, b) => a.time.compareTo(b.time));
      return schedules;
    });
  }

  // Get all schedules for current user
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

  // Add schedule
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

  // Update schedule
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

  // Toggle schedule enabled
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

  // Delete schedule
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

  // Log watering event
  Future<void> logWateringEvent({
    required String zoneId,
    required String zoneName,
    required int duration,
    required String source, // 'manual' or 'schedule'
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

      // Also update zone's lastWatered
      await _db.child('zones/$zoneId').update({
        'lastWatered': now.millisecondsSinceEpoch,
      });

      debugPrint('Watering event logged for zone: $zoneId');
    } catch (e) {
      debugPrint('Error logging watering event: $e');
    }
  }
}
