import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API Key - Replace with your actual key
  static const String _apiKey = '4938a3be7c3ce2fd0214b4f50e227196';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Default location - Hanoi, Vietnam
  static const double _defaultLat = 21.0285;
  static const double _defaultLon = 105.8542;

  WeatherModel? _currentWeather;
  List<WeatherForecast> _forecast = [];
  DateTime? _lastUpdate;
  Timer? _updateTimer;

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Get current weather
  Future<WeatherModel?> getCurrentWeather({
    double? lat,
    double? lon,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh &&
        _currentWeather != null &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
      return _currentWeather;
    }

    try {
      final latitude = lat ?? _defaultLat;
      final longitude = lon ?? _defaultLon;

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey',
      );

      debugPrint('🌤️ Fetching current weather...');
      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentWeather = WeatherModel.fromJson(data);
        _lastUpdate = DateTime.now();
        debugPrint('✅ Weather fetched: ${_currentWeather!.description}');
        return _currentWeather;
      } else {
        debugPrint('❌ Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Weather fetch error: $e');
      return _currentWeather; // Return cached data if available
    }
  }

  // Get 5-day forecast
  Future<List<WeatherForecast>> getForecast({
    double? lat,
    double? lon,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh &&
        _forecast.isNotEmpty &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
      return _forecast;
    }

    try {
      final latitude = lat ?? _defaultLat;
      final longitude = lon ?? _defaultLon;

      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey',
      );

      debugPrint('🌤️ Fetching weather forecast...');
      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List forecastList = data['list'];

        _forecast =
            forecastList.map((item) => WeatherForecast.fromJson(item)).toList();

        _lastUpdate = DateTime.now();
        debugPrint('✅ Forecast fetched: ${_forecast.length} items');
        return _forecast;
      } else {
        debugPrint('❌ Forecast API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Forecast fetch error: $e');
      return _forecast; // Return cached data if available
    }
  }

  // Check if it will rain in next 24 hours
  Future<bool> willRainIn24Hours({double? lat, double? lon}) async {
    final forecast = await getForecast(lat: lat, lon: lon);

    if (forecast.isEmpty) return false;

    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));

    final next24HoursForecast = forecast.where((f) {
      return f.date.isAfter(now) && f.date.isBefore(next24Hours);
    }).toList();

    // Check if any forecast predicts rain
    final willRain = next24HoursForecast.any((f) => f.willRain);

    debugPrint(
        '🌧️ Will rain in 24h: $willRain (checked ${next24HoursForecast.length} forecasts)');

    return willRain;
  }

  // Get rain probability for next 24 hours
  Future<double> getRainProbability24Hours({double? lat, double? lon}) async {
    final forecast = await getForecast(lat: lat, lon: lon);

    if (forecast.isEmpty) return 0.0;

    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));

    final next24HoursForecast = forecast.where((f) {
      return f.date.isAfter(now) && f.date.isBefore(next24Hours);
    }).toList();

    if (next24HoursForecast.isEmpty) return 0.0;

    // Calculate average probability
    final avgProbability = next24HoursForecast
            .map((f) => f.precipitationProbability)
            .reduce((a, b) => a + b) /
        next24HoursForecast.length;

    return avgProbability;
  }

  // Get seasonal adjustment
  SeasonalAdjustment getSeasonalAdjustment() {
    final currentMonth = DateTime.now().month;
    return SeasonalAdjustment.forMonth(currentMonth);
  }

  // Calculate adjusted watering duration based on weather and season
  Future<int> calculateAdjustedDuration({
    required int baseDuration,
    double? lat,
    double? lon,
  }) async {
    // Get seasonal adjustment
    final seasonal = getSeasonalAdjustment();
    int adjustedDuration = seasonal.adjustDuration(baseDuration);

    // Get current weather
    final weather = await getCurrentWeather(lat: lat, lon: lon);

    if (weather != null) {
      // Adjust based on current conditions
      if (weather.isRainy) {
        // Skip or reduce significantly if currently raining
        adjustedDuration = 0;
      } else if (weather.temperature > 30) {
        // Hot weather - increase by 20%
        adjustedDuration = (adjustedDuration * 1.2).round();
      } else if (weather.temperature < 15) {
        // Cool weather - decrease by 20%
        adjustedDuration = (adjustedDuration * 0.8).round();
      }

      // Adjust based on humidity
      if (weather.humidity > 80) {
        // High humidity - reduce by 10%
        adjustedDuration = (adjustedDuration * 0.9).round();
      } else if (weather.humidity < 40) {
        // Low humidity - increase by 10%
        adjustedDuration = (adjustedDuration * 1.1).round();
      }
    }

    // Ensure minimum duration
    if (adjustedDuration < 1) adjustedDuration = 1;

    debugPrint(
        '💧 Duration adjusted: $baseDuration min → $adjustedDuration min');

    return adjustedDuration;
  }

  // Start auto-update timer
  void startAutoUpdate() {
    _updateTimer?.cancel();

    // Update every 30 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      debugPrint('🔄 Auto-updating weather data...');
      getCurrentWeather(forceRefresh: true);
      getForecast(forceRefresh: true);
    });

    debugPrint('✅ Weather auto-update started');
  }

  // Stop auto-update
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    debugPrint('🛑 Weather auto-update stopped');
  }

  // Clear cache
  void clearCache() {
    _currentWeather = null;
    _forecast = [];
    _lastUpdate = null;
  }

  // Dispose
  void dispose() {
    stopAutoUpdate();
    clearCache();
  }
}
