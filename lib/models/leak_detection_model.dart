class LeakDetectionModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final bool isMonitoring;
  final double expectedFlowRate;
  final double actualFlowRate;
  final double leakThreshold; // percentage
  final DateTime lastCheck;
  final LeakStatus status;
  final List<LeakAlertModel> recentAlerts;

  LeakDetectionModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    this.isMonitoring = true,
    required this.expectedFlowRate,
    required this.actualFlowRate,
    this.leakThreshold = 20.0, // 20% deviation
    required this.lastCheck,
    required this.status,
    this.recentAlerts = const [],
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'isMonitoring': isMonitoring,
      'expectedFlowRate': expectedFlowRate,
      'actualFlowRate': actualFlowRate,
      'leakThreshold': leakThreshold,
      'lastCheck': lastCheck.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  // Create from Firebase Map
  factory LeakDetectionModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return LeakDetectionModel(
      id: id,
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      isMonitoring: map['isMonitoring'] ?? true,
      expectedFlowRate: (map['expectedFlowRate'] ?? 5.0).toDouble(),
      actualFlowRate: (map['actualFlowRate'] ?? 5.0).toDouble(),
      leakThreshold: (map['leakThreshold'] ?? 20.0).toDouble(),
      lastCheck: DateTime.fromMillisecondsSinceEpoch(
        map['lastCheck'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      status: LeakStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LeakStatus.normal,
      ),
    );
  }

  // Copy with method
  LeakDetectionModel copyWith({
    bool? isMonitoring,
    double? actualFlowRate,
    DateTime? lastCheck,
    LeakStatus? status,
  }) {
    return LeakDetectionModel(
      id: id,
      zoneId: zoneId,
      zoneName: zoneName,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      expectedFlowRate: expectedFlowRate,
      actualFlowRate: actualFlowRate ?? this.actualFlowRate,
      leakThreshold: leakThreshold,
      lastCheck: lastCheck ?? this.lastCheck,
      status: status ?? this.status,
      recentAlerts: recentAlerts,
    );
  }

  // Calculate deviation percentage
  double getDeviationPercentage() {
    if (expectedFlowRate == 0) return 0;
    return ((actualFlowRate - expectedFlowRate).abs() / expectedFlowRate) * 100;
  }

  // Check if leak detected
  bool hasLeak() {
    return status == LeakStatus.leakDetected ||
        status == LeakStatus.criticalLeak;
  }

  // Get status text
  String getStatusText() {
    switch (status) {
      case LeakStatus.normal:
        return 'Bình thường';
      case LeakStatus.warning:
        return 'Cảnh báo';
      case LeakStatus.leakDetected:
        return 'Phát hiện rò rỉ';
      case LeakStatus.criticalLeak:
        return 'Rò rỉ nghiêm trọng';
      case LeakStatus.inactive:
        return 'Không theo dõi';
    }
  }

  // Get status color
  String getStatusColor() {
    switch (status) {
      case LeakStatus.normal:
        return '#66BB6A'; // Green
      case LeakStatus.warning:
        return '#FFA726'; // Orange
      case LeakStatus.leakDetected:
        return '#EF5350'; // Red
      case LeakStatus.criticalLeak:
        return '#C62828'; // Dark Red
      case LeakStatus.inactive:
        return '#BDBDBD'; // Grey
    }
  }

  // Get recommendation
  String getRecommendation() {
    switch (status) {
      case LeakStatus.normal:
        return 'Hệ thống hoạt động bình thường';
      case LeakStatus.warning:
        return 'Kiểm tra hệ thống để đảm bảo không có vấn đề';
      case LeakStatus.leakDetected:
        return 'Kiểm tra đường ống và van ngay lập tức';
      case LeakStatus.criticalLeak:
        return 'TẮT HỆ THỐNG và kiểm tra ngay!';
      case LeakStatus.inactive:
        return 'Bật theo dõi để phát hiện rò rỉ';
    }
  }
}

class LeakAlertModel {
  final String id;
  final DateTime timestamp;
  final double expectedFlow;
  final double actualFlow;
  final LeakSeverity severity;

  LeakAlertModel({
    required this.id,
    required this.timestamp,
    required this.expectedFlow,
    required this.actualFlow,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'expectedFlow': expectedFlow,
      'actualFlow': actualFlow,
      'severity': severity.name,
    };
  }

  factory LeakAlertModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return LeakAlertModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      expectedFlow: (map['expectedFlow'] ?? 0).toDouble(),
      actualFlow: (map['actualFlow'] ?? 0).toDouble(),
      severity: LeakSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => LeakSeverity.low,
      ),
    );
  }

  double getDeviation() {
    if (expectedFlow == 0) return 0;
    return ((actualFlow - expectedFlow).abs() / expectedFlow) * 100;
  }
}

enum LeakStatus {
  normal,
  warning,
  leakDetected,
  criticalLeak,
  inactive,
}

enum LeakSeverity {
  low,
  medium,
  high,
  critical,
}
