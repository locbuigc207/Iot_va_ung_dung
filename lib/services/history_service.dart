import 'package:flutter/material.dart';

import '../models/watering_history_model.dart';
import 'firebase_service.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Get watering history for a zone
  Stream<List<WateringHistoryModel>> getZoneHistory(
    String zoneId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firebaseService.getWateringHistoryStream(
      zoneId: zoneId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get all watering history
  Stream<List<WateringHistoryModel>> getAllHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firebaseService.getAllWateringHistoryStream(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Generate water usage report
  Future<WaterUsageReport> generateReport(
    String zoneId,
    String zoneName,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final history = await getZoneHistory(
      zoneId,
      startDate: startDate,
      endDate: endDate,
    ).first;

    return WaterUsageReport.fromHistory(
      history,
      zoneId,
      zoneName,
      startDate,
      endDate,
    );
  }

  // Generate comparison report (current vs previous period)
  Future<Map<String, WaterUsageReport>> generateComparisonReport(
    String zoneId,
    String zoneName,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final duration = endDate.difference(startDate);
    final previousStart = startDate.subtract(duration);
    final previousEnd = startDate;

    final currentReport = await generateReport(
      zoneId,
      zoneName,
      startDate,
      endDate,
    );

    final previousReport = await generateReport(
      zoneId,
      zoneName,
      previousStart,
      previousEnd,
    );

    return {
      'current': currentReport,
      'previous': previousReport,
    };
  }

  // Get daily summary
  Future<Map<DateTime, double>> getDailySummary(
    String zoneId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final history = await getZoneHistory(
      zoneId,
      startDate: startDate,
      endDate: endDate,
    ).first;

    final dailySummary = <DateTime, double>{};

    for (var record in history) {
      final date = DateTime(
        record.startTime.year,
        record.startTime.month,
        record.startTime.day,
      );

      dailySummary[date] = (dailySummary[date] ?? 0) + record.waterUsed;
    }

    return dailySummary;
  }

  // Get hourly distribution (when watering happens most)
  Future<Map<int, int>> getHourlyDistribution(
    String zoneId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final history = await getZoneHistory(
      zoneId,
      startDate: startDate,
      endDate: endDate,
    ).first;

    final hourlyDist = <int, int>{};

    for (var record in history) {
      final hour = record.startTime.hour;
      hourlyDist[hour] = (hourlyDist[hour] ?? 0) + 1;
    }

    return hourlyDist;
  }

  // Export history to CSV (string format)
  String exportToCSV(List<WateringHistoryModel> history) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Date,Zone,Start Time,End Time,Duration (min),Water Used (L),Source,Completed',
    );

    // Data rows
    for (var record in history) {
      buffer.writeln(
        '${record.startTime.toIso8601String()},${record.zoneName},'
        '${record.startTime.toIso8601String()},${record.endTime.toIso8601String()},'
        '${record.duration},${record.waterUsed},${record.source},${record.completed}',
      );
    }

    return buffer.toString();
  }

  // Calculate water savings from automation
  Future<Map<String, dynamic>> calculateWaterSavings(
    String zoneId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final history = await getZoneHistory(
      zoneId,
      startDate: startDate,
      endDate: endDate,
    ).first;

    final manualWater = history
        .where((h) => h.source == 'manual')
        .fold<double>(0, (sum, h) => sum + h.waterUsed);

    final autoWater = history
        .where((h) => h.source == 'auto')
        .fold<double>(0, (sum, h) => sum + h.waterUsed);

    final scheduleWater = history
        .where((h) => h.source == 'schedule')
        .fold<double>(0, (sum, h) => sum + h.waterUsed);

    // Estimated savings: compare auto/schedule vs if all were manual
    // Assumption: manual watering is typically 20% less efficient
    final estimatedManualEquivalent = (autoWater + scheduleWater) * 1.2;
    final waterSaved = estimatedManualEquivalent - (autoWater + scheduleWater);

    return {
      'manualWater': manualWater,
      'autoWater': autoWater,
      'scheduleWater': scheduleWater,
      'estimatedSavings': waterSaved,
      'savingsPercentage': estimatedManualEquivalent > 0
          ? (waterSaved / estimatedManualEquivalent) * 100
          : 0,
    };
  }

  // Get best watering times based on history success
  Future<List<int>> getOptimalWateringHours(
    String zoneId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final hourlyDist = await getHourlyDistribution(zoneId, startDate, endDate);

    // Sort hours by frequency
    final sorted = hourlyDist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top 3 hours
    return sorted.take(3).map((e) => e.key).toList();
  }

  // Log watering event (enhanced version)
  Future<void> logWateringEvent({
    required String zoneId,
    required String zoneName,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    required double waterUsed,
    required String source,
    bool completed = true,
    String? notes,
  }) async {
    await _firebaseService.logWateringHistory(
      WateringHistoryModel(
        id: '',
        zoneId: zoneId,
        zoneName: zoneName,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        waterUsed: waterUsed,
        source: source,
        completed: completed,
        notes: notes,
      ),
    );

    debugPrint(
        '✅ Watering event logged: $zoneName ($duration min, $waterUsed L)');
  }
}
