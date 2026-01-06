class SensorModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final String name;
  final SensorType type;
  final String unit;
  final double currentValue;
  final double minThreshold;
  final double maxThreshold;
  final DateTime lastUpdated;
  final bool isActive;
  final bool alertEnabled;
  final String? deviceId;

  SensorModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.name,
    required this.type,
    required this.unit,
    required this.currentValue,
    required this.minThreshold,
    required this.maxThreshold,
    required this.lastUpdated,
    this.isActive = true,
    this.alertEnabled = true,
    this.deviceId,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'name': name,
      'type': type.name,
      'unit': unit,
      'currentValue': currentValue,
      'minThreshold': minThreshold,
      'maxThreshold': maxThreshold,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isActive': isActive,
      'alertEnabled': alertEnabled,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  // Create from Firebase Map
  factory SensorModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return SensorModel(
      id: id,
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      name: map['name'] ?? 'Unknown Sensor',
      type: SensorType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SensorType.soilMoisture,
      ),
      unit: map['unit'] ?? '',
      currentValue: (map['currentValue'] ?? 0).toDouble(),
      minThreshold: (map['minThreshold'] ?? 0).toDouble(),
      maxThreshold: (map['maxThreshold'] ?? 100).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isActive: map['isActive'] ?? true,
      alertEnabled: map['alertEnabled'] ?? true,
      deviceId: map['deviceId'],
    );
  }

  // Copy with method
  SensorModel copyWith({
    double? currentValue,
    DateTime? lastUpdated,
    bool? isActive,
    bool? alertEnabled,
    double? minThreshold,
    double? maxThreshold,
  }) {
    return SensorModel(
      id: id,
      zoneId: zoneId,
      zoneName: zoneName,
      name: name,
      type: type,
      unit: unit,
      currentValue: currentValue ?? this.currentValue,
      minThreshold: minThreshold ?? this.minThreshold,
      maxThreshold: maxThreshold ?? this.maxThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      alertEnabled: alertEnabled ?? this.alertEnabled,
    );
  }

  // Get sensor status
  SensorStatus getStatus() {
    if (!isActive) return SensorStatus.inactive;
    if (currentValue < minThreshold) return SensorStatus.low;
    if (currentValue > maxThreshold) return SensorStatus.high;
    return SensorStatus.normal;
  }

  // Get status text
  String getStatusText() {
    switch (getStatus()) {
      case SensorStatus.low:
        return 'Thấp';
      case SensorStatus.high:
        return 'Cao';
      case SensorStatus.normal:
        return 'Bình thường';
      case SensorStatus.inactive:
        return 'Không hoạt động';
    }
  }

  // Get status color
  String getStatusColor() {
    switch (getStatus()) {
      case SensorStatus.low:
        return '#FFA726'; // Orange
      case SensorStatus.high:
        return '#EF5350'; // Red
      case SensorStatus.normal:
        return '#66BB6A'; // Green
      case SensorStatus.inactive:
        return '#BDBDBD'; // Grey
    }
  }

  // Get sensor icon
  String getIcon() {
    switch (type) {
      case SensorType.soilMoisture:
        return '💧';
      case SensorType.temperature:
        return '🌡️';
      case SensorType.light:
        return '☀️';
      case SensorType.flow:
        return '💦';
      case SensorType.humidity:
        return '💨';
    }
  }

  // Format value with unit
  String getFormattedValue() {
    return '${currentValue.toStringAsFixed(1)} $unit';
  }

  // Check if needs alert
  bool needsAlert() {
    return alertEnabled &&
        isActive &&
        (currentValue < minThreshold || currentValue > maxThreshold);
  }
}

enum SensorType {
  soilMoisture,
  temperature,
  light,
  flow,
  humidity,
}

enum SensorStatus {
  normal,
  low,
  high,
  inactive,
}

extension SensorTypeExtension on SensorType {
  String get displayName {
    switch (this) {
      case SensorType.soilMoisture:
        return 'Độ ẩm đất';
      case SensorType.temperature:
        return 'Nhiệt độ';
      case SensorType.light:
        return 'Ánh sáng';
      case SensorType.flow:
        return 'Lưu lượng nước';
      case SensorType.humidity:
        return 'Độ ẩm không khí';
    }
  }

  String get defaultUnit {
    switch (this) {
      case SensorType.soilMoisture:
        return '%';
      case SensorType.temperature:
        return '°C';
      case SensorType.light:
        return 'lux';
      case SensorType.flow:
        return 'L/min';
      case SensorType.humidity:
        return '%';
    }
  }

  double get defaultMin {
    switch (this) {
      case SensorType.soilMoisture:
        return 30.0;
      case SensorType.temperature:
        return 15.0;
      case SensorType.light:
        return 20.0;
      case SensorType.flow:
        return 3.0;
      case SensorType.humidity:
        return 40.0;
    }
  }

  double get defaultMax {
    switch (this) {
      case SensorType.soilMoisture:
        return 80.0;
      case SensorType.temperature:
        return 35.0;
      case SensorType.light:
        return 800.0;
      case SensorType.flow:
        return 20.0;
      case SensorType.humidity:
        return 80.0;
    }
  }
}
