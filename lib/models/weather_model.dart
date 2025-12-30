class WeatherModel {
  final String locationName;
  final double temperature; // Celsius
  final double humidity; // Percentage
  final String description;
  final String mainCondition; // Clear, Clouds, Rain, etc.
  final double precipitation; // mm
  final double windSpeed; // m/s
  final DateTime timestamp;
  final String icon;

  WeatherModel({
    required this.locationName,
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.mainCondition,
    required this.precipitation,
    required this.windSpeed,
    required this.timestamp,
    required this.icon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      locationName: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num).toDouble() - 273.15, // K to C
      humidity: (json['main']['humidity'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      mainCondition: json['weather'][0]['main'] ?? '',
      precipitation: (json['rain']?['1h'] ?? 0.0).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['dt'] * 1000,
      ),
      icon: json['weather'][0]['icon'] ?? '01d',
    );
  }

  // Check if weather is rainy
  bool get isRainy =>
      mainCondition.toLowerCase().contains('rain') ||
      mainCondition.toLowerCase().contains('drizzle') ||
      mainCondition.toLowerCase().contains('thunderstorm');

  // Check if weather is good for watering
  bool get isGoodForWatering =>
      !isRainy &&
      precipitation < 1.0 &&
      temperature > 5.0 &&
      temperature < 40.0;

  // Get weather icon emoji
  String get weatherEmoji {
    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'locationName': locationName,
      'temperature': temperature,
      'humidity': humidity,
      'description': description,
      'mainCondition': mainCondition,
      'precipitation': precipitation,
      'windSpeed': windSpeed,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'icon': icon,
    };
  }
}

class WeatherForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double precipitation;
  final double precipitationProbability; // Percentage
  final String condition;
  final String icon;

  WeatherForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.precipitation,
    required this.precipitationProbability,
    required this.condition,
    required this.icon,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      tempMin: (json['main']['temp_min'] as num).toDouble() - 273.15,
      tempMax: (json['main']['temp_max'] as num).toDouble() - 273.15,
      precipitation: (json['rain']?['3h'] ?? 0.0).toDouble(),
      precipitationProbability: (json['pop'] * 100).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
    );
  }

  bool get willRain =>
      condition.toLowerCase().contains('rain') ||
      precipitationProbability > 60.0 ||
      precipitation > 2.0;

  String get weatherEmoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }
}

class SeasonalAdjustment {
  final int month;
  final String season;
  final double wateringMultiplier; // 0.5 - 1.5
  final String recommendation;

  SeasonalAdjustment({
    required this.month,
    required this.season,
    required this.wateringMultiplier,
    required this.recommendation,
  });

  // Get seasonal adjustment for current month
  static SeasonalAdjustment forMonth(int month) {
    // Vietnam climate: Tropical monsoon
    switch (month) {
      case 12:
      case 1:
      case 2:
        // Winter - Cool and dry
        return SeasonalAdjustment(
          month: month,
          season: 'Mùa đông',
          wateringMultiplier: 0.7,
          recommendation: 'Giảm tưới do trời lạnh và ít bay hơi',
        );
      case 3:
      case 4:
      case 5:
        // Spring/Summer - Hot and humid
        return SeasonalAdjustment(
          month: month,
          season: 'Mùa xuân - hè',
          wateringMultiplier: 1.3,
          recommendation: 'Tăng tưới do trời nóng và bay hơi nhiều',
        );
      case 6:
      case 7:
      case 8:
      case 9:
        // Rainy season
        return SeasonalAdjustment(
          month: month,
          season: 'Mùa mưa',
          wateringMultiplier: 0.6,
          recommendation: 'Giảm tưới do mưa nhiều',
        );
      case 10:
      case 11:
        // Autumn - Transitional
        return SeasonalAdjustment(
          month: month,
          season: 'Mùa thu',
          wateringMultiplier: 0.9,
          recommendation: 'Tưới vừa phải do thời tiết mát mẻ',
        );
      default:
        return SeasonalAdjustment(
          month: month,
          season: 'Unknown',
          wateringMultiplier: 1.0,
          recommendation: 'Tưới bình thường',
        );
    }
  }

  // Calculate adjusted duration
  int adjustDuration(int baseDuration) {
    return (baseDuration * wateringMultiplier).round();
  }
}
