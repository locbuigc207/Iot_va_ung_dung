class WateringHistoryModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // minutes
  final double waterUsed; // liters
  final String source; // manual, schedule, auto
  final bool completed;
  final String? notes;

  WateringHistoryModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.waterUsed,
    required this.source,
    this.completed = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'duration': duration,
      'waterUsed': waterUsed,
      'source': source,
      'completed': completed,
      'notes': notes,
    };
  }

  factory WateringHistoryModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return WateringHistoryModel(
      id: id,
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map['startTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        map['endTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      duration: map['duration'] ?? 0,
      waterUsed: (map['waterUsed'] ?? 0.0).toDouble(),
      source: map['source'] ?? 'manual',
      completed: map['completed'] ?? true,
      notes: map['notes'],
    );
  }

  String getSourceDisplay() {
    switch (source) {
      case 'manual':
        return 'Thủ công';
      case 'schedule':
        return 'Lịch trình';
      case 'auto':
        return 'Tự động';
      default:
        return 'Khác';
    }
  }

  String getSourceIcon() {
    switch (source) {
      case 'manual':
        return '👤';
      case 'schedule':
        return '📅';
      case 'auto':
        return '🤖';
      default:
        return '❓';
    }
  }
}

class WaterUsageReport {
  final String zoneId;
  final String zoneName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalSessions;
  final int totalMinutes;
  final double totalLiters;
  final double avgMinutesPerSession;
  final double avgLitersPerSession;
  final Map<String, int> sourceBreakdown; // manual: x, schedule: y, auto: z

  WaterUsageReport({
    required this.zoneId,
    required this.zoneName,
    required this.startDate,
    required this.endDate,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalLiters,
    required this.avgMinutesPerSession,
    required this.avgLitersPerSession,
    required this.sourceBreakdown,
  });

  factory WaterUsageReport.fromHistory(
    List<WateringHistoryModel> history,
    String zoneId,
    String zoneName,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalSessions = history.length;
    final totalMinutes = history.fold<int>(0, (sum, h) => sum + h.duration);
    final totalLiters = history.fold<double>(0, (sum, h) => sum + h.waterUsed);

    final sourceBreakdown = <String, int>{
      'manual': history.where((h) => h.source == 'manual').length,
      'schedule': history.where((h) => h.source == 'schedule').length,
      'auto': history.where((h) => h.source == 'auto').length,
    };

    return WaterUsageReport(
      zoneId: zoneId,
      zoneName: zoneName,
      startDate: startDate,
      endDate: endDate,
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      totalLiters: totalLiters,
      avgMinutesPerSession:
          totalSessions > 0 ? totalMinutes / totalSessions : 0,
      avgLitersPerSession: totalSessions > 0 ? totalLiters / totalSessions : 0,
      sourceBreakdown: sourceBreakdown,
    );
  }

  double getComparisonPercentage(WaterUsageReport? previousReport) {
    if (previousReport == null || previousReport.totalLiters == 0) return 0;
    return ((totalLiters - previousReport.totalLiters) /
            previousReport.totalLiters) *
        100;
  }
}

class PlantProfileModel {
  final String id;
  final String name;
  final String scientificName;
  final String category; // vegetables, grass, flowers, trees, succulents
  final String description;
  final String imageUrl;

  // Watering requirements
  final int wateringFrequency; // days
  final int wateringDuration; // minutes per session
  final double optimalSoilMoisture; // percentage

  // Environmental preferences
  final String sunExposure; // full, partial, shade
  final List<String> soilTypes; // clay, sand, loam
  final double minTemperature; // celsius
  final double maxTemperature; // celsius
  final double minHumidity; // percentage
  final double maxHumidity; // percentage

  // Care tips
  final List<String> careTips;
  final String season; // spring, summer, fall, winter, all

  PlantProfileModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.wateringFrequency,
    required this.wateringDuration,
    required this.optimalSoilMoisture,
    required this.sunExposure,
    required this.soilTypes,
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.careTips,
    required this.season,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'wateringFrequency': wateringFrequency,
      'wateringDuration': wateringDuration,
      'optimalSoilMoisture': optimalSoilMoisture,
      'sunExposure': sunExposure,
      'soilTypes': soilTypes,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'careTips': careTips,
      'season': season,
    };
  }

  factory PlantProfileModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return PlantProfileModel(
      id: id,
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      category: map['category'] ?? 'vegetables',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      wateringFrequency: map['wateringFrequency'] ?? 3,
      wateringDuration: map['wateringDuration'] ?? 10,
      optimalSoilMoisture: (map['optimalSoilMoisture'] ?? 50.0).toDouble(),
      sunExposure: map['sunExposure'] ?? 'partial',
      soilTypes: List<String>.from(map['soilTypes'] ?? ['loam']),
      minTemperature: (map['minTemperature'] ?? 15.0).toDouble(),
      maxTemperature: (map['maxTemperature'] ?? 30.0).toDouble(),
      minHumidity: (map['minHumidity'] ?? 40.0).toDouble(),
      maxHumidity: (map['maxHumidity'] ?? 70.0).toDouble(),
      careTips: List<String>.from(map['careTips'] ?? []),
      season: map['season'] ?? 'all',
    );
  }

  String getCategoryIcon() {
    switch (category) {
      case 'vegetables':
        return '🥬';
      case 'grass':
        return '🌿';
      case 'flowers':
        return '🌺';
      case 'trees':
        return '🌳';
      case 'succulents':
        return '🌵';
      default:
        return '🌱';
    }
  }

  String getCategoryDisplay() {
    switch (category) {
      case 'vegetables':
        return 'Rau củ';
      case 'grass':
        return 'Cỏ';
      case 'flowers':
        return 'Hoa';
      case 'trees':
        return 'Cây';
      case 'succulents':
        return 'Sen đá';
      default:
        return 'Khác';
    }
  }
}

class ZoneProfileModel {
  final String zoneId;
  final String plantProfileId;
  final String plantName;

  // Terrain characteristics
  final double slope; // degrees (0-45)
  final String drainage; // poor, moderate, good, excellent
  final double sunHoursPerDay;
  final bool hasWindProtection;

  // Irrigation settings
  final double waterPressure; // PSI
  final int numberOfEmitters;
  final double emitterFlowRate; // liters per hour

  // Custom adjustments
  final double wateringMultiplier; // 0.5 - 2.0
  final Map<String, dynamic> customSettings;

  final DateTime createdAt;
  final DateTime? lastUpdated;

  ZoneProfileModel({
    required this.zoneId,
    required this.plantProfileId,
    required this.plantName,
    required this.slope,
    required this.drainage,
    required this.sunHoursPerDay,
    required this.hasWindProtection,
    required this.waterPressure,
    required this.numberOfEmitters,
    required this.emitterFlowRate,
    this.wateringMultiplier = 1.0,
    required this.customSettings,
    required this.createdAt,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'plantProfileId': plantProfileId,
      'plantName': plantName,
      'slope': slope,
      'drainage': drainage,
      'sunHoursPerDay': sunHoursPerDay,
      'hasWindProtection': hasWindProtection,
      'waterPressure': waterPressure,
      'numberOfEmitters': numberOfEmitters,
      'emitterFlowRate': emitterFlowRate,
      'wateringMultiplier': wateringMultiplier,
      'customSettings': customSettings,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  factory ZoneProfileModel.fromMap(Map<dynamic, dynamic> map) {
    return ZoneProfileModel(
      zoneId: map['zoneId'] ?? '',
      plantProfileId: map['plantProfileId'] ?? '',
      plantName: map['plantName'] ?? '',
      slope: (map['slope'] ?? 0.0).toDouble(),
      drainage: map['drainage'] ?? 'moderate',
      sunHoursPerDay: (map['sunHoursPerDay'] ?? 6.0).toDouble(),
      hasWindProtection: map['hasWindProtection'] ?? false,
      waterPressure: (map['waterPressure'] ?? 30.0).toDouble(),
      numberOfEmitters: map['numberOfEmitters'] ?? 1,
      emitterFlowRate: (map['emitterFlowRate'] ?? 4.0).toDouble(),
      wateringMultiplier: (map['wateringMultiplier'] ?? 1.0).toDouble(),
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
    );
  }

  String getDrainageDisplay() {
    switch (drainage) {
      case 'poor':
        return 'Kém';
      case 'moderate':
        return 'Trung bình';
      case 'good':
        return 'Tốt';
      case 'excellent':
        return 'Xuất sắc';
      default:
        return 'Không xác định';
    }
  }

  int calculateAdjustedDuration(int baseDuration) {
    // Adjust for slope (steeper = more water loss)
    var adjusted = baseDuration.toDouble();
    if (slope > 15) {
      adjusted *= 1.2;
    } else if (slope > 30) {
      adjusted *= 1.4;
    }

    // Adjust for drainage
    switch (drainage) {
      case 'poor':
        adjusted *= 0.8;
        break;
      case 'excellent':
        adjusted *= 1.2;
        break;
    }

    // Apply custom multiplier
    adjusted *= wateringMultiplier;

    return adjusted.round();
  }
}
