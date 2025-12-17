class ScheduleModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final String time; // Format: "HH:mm"
  final int duration; // Duration in minutes
  final List<int> activeDays; // 1=Monday, 7=Sunday
  final bool enabled;
  final bool weatherSkip;
  final DateTime createdAt;

  ScheduleModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.time,
    required this.duration,
    required this.activeDays,
    this.enabled = true,
    this.weatherSkip = false,
    required this.createdAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'time': time,
      'duration': duration,
      'activeDays': activeDays,
      'enabled': enabled,
      'weatherSkip': weatherSkip,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create from Firebase Map
  factory ScheduleModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? 'Unknown Zone',
      time: map['time'] ?? '00:00',
      duration: map['duration'] ?? 5,
      activeDays: List<int>.from(map['activeDays'] ?? [1, 2, 3, 4, 5]),
      enabled: map['enabled'] ?? true,
      weatherSkip: map['weatherSkip'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // Copy with method
  ScheduleModel copyWith({
    String? time,
    int? duration,
    List<int>? activeDays,
    bool? enabled,
    bool? weatherSkip,
  }) {
    return ScheduleModel(
      id: id,
      zoneId: zoneId,
      zoneName: zoneName,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      activeDays: activeDays ?? this.activeDays,
      enabled: enabled ?? this.enabled,
      weatherSkip: weatherSkip ?? this.weatherSkip,
      createdAt: createdAt,
    );
  }

  // Get formatted days string
  String getActiveDaysString() {
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    if (activeDays.length == 7) return 'Hàng ngày';
    if (activeDays.length == 5 &&
        !activeDays.contains(6) &&
        !activeDays.contains(7)) {
      return 'Thứ 2 - Thứ 6';
    }
    return activeDays.map((day) => dayNames[day - 1]).join(', ');
  }

  // Check if schedule should run today
  bool shouldRunToday() {
    if (!enabled) return false;
    final today = DateTime.now().weekday;
    return activeDays.contains(today);
  }

  // Get next run time
  DateTime? getNextRunTime() {
    if (!enabled) return null;

    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Check today first
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);

    // If time has passed today, start from tomorrow
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    // Find next active day
    for (int i = 0; i < 7; i++) {
      if (activeDays.contains(nextRun.weekday)) {
        return nextRun;
      }
      nextRun = nextRun.add(const Duration(days: 1));
    }

    return null;
  }

  // Format duration for display
  String getDurationString() {
    if (duration < 60) {
      return '$duration phút';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '$hours giờ';
      }
      return '$hours giờ $minutes phút';
    }
  }
}
