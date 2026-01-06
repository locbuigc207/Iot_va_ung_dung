import 'package:flutter/material.dart';

class DeviceModel {
  final String id;
  final String name;
  final String zoneId;
  final String type; // pump, valve, sensor
  final bool status; // on/off
  final DateTime lastUpdated;
  final double? flowRate;
  final int? currentDuration;
  final DateTime? startTime;
  final String? deviceMAC;
  final String? uniqueId;

  // Mode và forced auto fields
  final String mode; // "manual" hoặc "auto"
  final bool forcedAuto; // true nếu đang bị force auto do soil thấp

  DeviceModel({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.type,
    this.status = false,
    required this.lastUpdated,
    this.flowRate,
    this.currentDuration,
    this.startTime,
    this.deviceMAC,
    this.uniqueId,
    this.mode = 'auto', // Default auto
    this.forcedAuto = false, // Default không force
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'zoneId': zoneId,
      'type': type,
      'status': status,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'flowRate': flowRate,
      'mode': mode,
      'forcedAuto': forcedAuto,
      if (currentDuration != null) 'currentDuration': currentDuration,
      if (startTime != null) 'startTime': startTime!.millisecondsSinceEpoch,
      if (deviceMAC != null) 'deviceMAC': deviceMAC,
      if (uniqueId != null) 'uniqueId': uniqueId,
    };
  }

  // Create from Firebase Map
  factory DeviceModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DeviceModel(
      id: id,
      name: map['name'] ?? 'Unknown Device',
      zoneId: map['zoneId'] ?? '',
      type: map['type'] ?? 'pump',
      status: map['status'] ?? false,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      flowRate: map['flowRate']?.toDouble(),
      currentDuration: map['currentDuration'],
      startTime: map['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
          : null,
      deviceMAC: map['deviceMAC'],
      uniqueId: map['uniqueId'],
      mode: map['mode'] ?? 'auto',
      forcedAuto: map['forcedAuto'] ?? false,
    );
  }

  // Copy with method
  DeviceModel copyWith({
    String? id,
    String? name,
    String? zoneId,
    String? type,
    bool? status,
    DateTime? lastUpdated,
    double? flowRate,
    int? currentDuration,
    DateTime? startTime,
    String? deviceMAC,
    String? uniqueId,
    String? mode,
    bool? forcedAuto,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      zoneId: zoneId ?? this.zoneId,
      type: type ?? this.type,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      flowRate: flowRate ?? this.flowRate,
      currentDuration: currentDuration ?? this.currentDuration,
      startTime: startTime ?? this.startTime,
      deviceMAC: deviceMAC ?? this.deviceMAC,
      uniqueId: uniqueId ?? this.uniqueId,
      mode: mode ?? this.mode,
      forcedAuto: forcedAuto ?? this.forcedAuto,
    );
  }

  // Get mode display text
  String getModeDisplayText() {
    if (forcedAuto) return 'Tự động (Bắt buộc)';
    return mode == 'manual' ? 'Thủ công' : 'Tự động';
  }

  // Get mode icon
  IconData getModeIcon() {
    if (forcedAuto) return Icons.warning_amber;
    return mode == 'manual' ? Icons.touch_app : Icons.auto_awesome;
  }

  // Get mode color
  Color getModeColor() {
    if (forcedAuto) return Colors.orange;
    return mode == 'manual' ? Colors.blue : Colors.green;
  }

  // Get status text with mode
  String getStatusText() {
    if (!status) return 'Tắt (${getModeDisplayText()})';
    if (currentDuration != null && currentDuration! > 0) {
      final minutes = currentDuration! ~/ 60;
      final seconds = currentDuration! % 60;
      return 'Đang tưới ($minutes:${seconds.toString().padLeft(2, '0')}) - ${getModeDisplayText()}';
    }
    return 'Đang bật (${getModeDisplayText()})';
  }

  // Get device type icon
  String getDeviceIcon() {
    switch (type) {
      case 'pump':
        return '💧';
      case 'valve':
        return '🚰';
      case 'sensor':
        return '📊';
      default:
        return '⚙️';
    }
  }

  // Check if device is currently watering
  bool get isWatering => status && (currentDuration ?? 0) > 0;

  // Check if device can be controlled manually
  bool get canControlManually => !forcedAuto;

  // Calculate estimated water used (liters)
  double? getEstimatedWaterUsed() {
    if (flowRate == null || startTime == null || !status) return null;
    final minutesRunning = DateTime.now().difference(startTime!).inMinutes;
    return flowRate! * minutesRunning;
  }

  // Get remaining time as formatted string
  String? getRemainingTimeString() {
    if (currentDuration == null || currentDuration! <= 0) return null;
    final minutes = currentDuration! ~/ 60;
    final seconds = currentDuration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get status description for notification
  String getStatusDescription() {
    if (forcedAuto) {
      return 'Thiết bị đang ở chế độ tự động bắt buộc do độ ẩm đất thấp';
    }
    if (!status) {
      return 'Thiết bị đang tắt';
    }
    if (isWatering) {
      return 'Thiết bị đang tưới, còn ${getRemainingTimeString() ?? "N/A"}';
    }
    return 'Thiết bị đang bật';
  }

  @override
  String toString() {
    return 'DeviceModel(id: $id, name: $name, type: $type, status: $status, mode: $mode, forcedAuto: $forcedAuto)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceModel &&
        other.id == id &&
        other.name == name &&
        other.zoneId == zoneId &&
        other.type == type &&
        other.status == status &&
        other.mode == mode &&
        other.forcedAuto == forcedAuto;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      zoneId,
      type,
      status,
      mode,
      forcedAuto,
    );
  }
}
