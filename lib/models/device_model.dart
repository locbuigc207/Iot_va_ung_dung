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
    );
  }

  // Copy with method
  DeviceModel copyWith({
    bool? status,
    DateTime? lastUpdated,
    double? flowRate,
    int? currentDuration,
    DateTime? startTime,
  }) {
    return DeviceModel(
      id: id,
      name: name,
      zoneId: zoneId,
      type: type,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      flowRate: flowRate ?? this.flowRate,
      currentDuration: currentDuration ?? this.currentDuration,
      startTime: startTime ?? this.startTime,
    );
  }

  // Get status display text
  String getStatusText() {
    if (!status) return 'Tắt';
    if (currentDuration != null && currentDuration! > 0) {
      final minutes = currentDuration! ~/ 60;
      final seconds = currentDuration! % 60;
      return 'Đang tưới ($minutes:${seconds.toString().padLeft(2, '0')})';
    }
    return 'Đang bật';
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
}
