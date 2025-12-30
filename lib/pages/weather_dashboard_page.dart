import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherDashboardPage extends StatefulWidget {
  const WeatherDashboardPage({Key? key}) : super(key: key);

  @override
  State<WeatherDashboardPage> createState() => _WeatherDashboardPageState();
}

class _WeatherDashboardPageState extends State<WeatherDashboardPage> {
  final WeatherService _weatherService = WeatherService();

  WeatherModel? _currentWeather;
  List<WeatherForecast> _forecast = [];
  SeasonalAdjustment? _seasonalAdjustment;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load current weather
      final weather = await _weatherService.getCurrentWeather(
        forceRefresh: true,
      );

      // Load forecast
      final forecast = await _weatherService.getForecast(
        forceRefresh: true,
      );

      // Get seasonal adjustment
      final seasonal = _weatherService.getSeasonalAdjustment();

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _forecast = forecast;
          _seasonalAdjustment = seasonal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu thời tiết: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thời tiết',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00C1C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Weather Card
                      if (_currentWeather != null) _buildCurrentWeatherCard(),

                      const SizedBox(height: 16),

                      // Seasonal Adjustment Card
                      if (_seasonalAdjustment != null)
                        _buildSeasonalAdjustmentCard(),

                      const SizedBox(height: 16),

                      // Forecast Section
                      const Text(
                        'Dự báo 5 ngày',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildForecastList(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00C1C4)),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu thời tiết...',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1C4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final weather = _currentWeather!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00C1C4),
              const Color(0xFF00C1C4).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  weather.weatherEmoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      Text(
                        weather.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  Icons.water_drop,
                  '${weather.humidity.toStringAsFixed(0)}%',
                  'Độ ẩm',
                ),
                _buildWeatherDetail(
                  Icons.air,
                  '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  'Gió',
                ),
                _buildWeatherDetail(
                  Icons.grain,
                  '${weather.precipitation.toStringAsFixed(1)} mm',
                  'Mưa',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: weather.isGoodForWatering
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    weather.isGoodForWatering
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.isGoodForWatering
                          ? 'Thời tiết tốt để tưới cây'
                          : 'Nên hoãn tưới cây',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonalAdjustmentCard() {
    final seasonal = _seasonalAdjustment!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điều chỉnh theo mùa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      Text(
                        seasonal.season,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C1C4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '×${seasonal.wateringMultiplier.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C1C4),
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seasonal.recommendation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    if (_forecast.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu dự báo',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: Colors.grey,
          ),
        ),
      );
    }

    // Group by date and take first of each day
    final dailyForecast = <String, WeatherForecast>{};
    for (var forecast in _forecast) {
      final dateKey = DateFormat('yyyy-MM-dd').format(forecast.date);
      if (!dailyForecast.containsKey(dateKey)) {
        dailyForecast[dateKey] = forecast;
      }
    }

    return Column(
      children: dailyForecast.values.take(5).map((forecast) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE').format(forecast.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM').format(forecast.date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Weather Icon
                Text(
                  forecast.weatherEmoji,
                  style: const TextStyle(fontSize: 32),
                ),

                const SizedBox(width: 16),

                // Temperature Range
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${forecast.tempMax.toStringAsFixed(0)}° / ${forecast.tempMin.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${forecast.precipitationProbability.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rain Warning
                if (forecast.willRain)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.umbrella,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
