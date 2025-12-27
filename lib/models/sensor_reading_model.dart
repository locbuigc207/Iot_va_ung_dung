class SensorReadingModel {
  final String id;
  final String sensorId;
  final double value;
  final DateTime timestamp;
  final bool isAlert;

  SensorReadingModel({
    required this.id,
    required this.sensorId,
    required this.value,
    required this.timestamp,
    this.isAlert = false,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'sensorId': sensorId,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAlert': isAlert,
    };
  }

  // Create from Firebase Map
  factory SensorReadingModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return SensorReadingModel(
      id: id,
      sensorId: map['sensorId'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isAlert: map['isAlert'] ?? false,
    );
  }

  // For charting
  double get timeValue => timestamp.millisecondsSinceEpoch.toDouble();
}
