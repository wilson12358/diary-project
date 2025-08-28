import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // WeatherAPI.com API key - Free tier includes 1,000,000 calls per month
  static const String _apiKey = '0abe112b08c24473982203219252408';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  /// Get current weather for a location
  Future<Map<String, dynamic>?> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/current.json?key=$_apiKey&q=$latitude,$longitude&aqi=no',
      );

      if (kDebugMode) {
        print('🌤️ WeatherAPI.com: Fetching weather for coordinates: $latitude, $longitude');
        print('🌤️ WeatherAPI.com: API URL: $url');
      }

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (kDebugMode) {
        print('🌤️ WeatherAPI.com: Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('🌤️ WeatherAPI.com: Successfully parsed weather data');
        }
        return _parseWeatherData(data);
      } else {
        print('WeatherAPI.com error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Parse weather data from WeatherAPI.com response
  Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    try {
      final current = data['current'] ?? {};
      final location = data['location'] ?? {};
      final condition = current['condition'] ?? {};

      return {
        'temperature': current['temp_c']?.toDouble(),
        'feelsLike': current['feelslike_c']?.toDouble(),
        'humidity': current['humidity']?.toInt(),
        'pressure': current['pressure_mb']?.toInt(),
        'description': condition['text'] ?? '',
        'main': condition['text'] ?? '',
        'icon': condition['icon'] ?? '',
        'windSpeed': current['wind_kph']?.toDouble(),
        'windDirection': current['wind_degree']?.toInt(),
        'sunrise': null, // WeatherAPI.com current endpoint doesn't include sunrise/sunset
        'sunset': null,  // Would need forecast endpoint for this data
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'city': location['name'] ?? '',
        'country': location['country'] ?? '',
        'region': location['region'] ?? '',
        'localTime': location['localtime'] ?? '',
        'uv': current['uv']?.toDouble(),
        'visibility': current['vis_km']?.toDouble(),
        'precipitation': current['precip_mm']?.toDouble(),
      };
    } catch (e) {
      print('Error parsing WeatherAPI.com data: $e');
      return {};
    }
  }

  /// Get weather icon URL from WeatherAPI.com
  String getWeatherIconUrl(String iconCode) {
    // WeatherAPI.com provides full URLs, so we can return them directly
    if (iconCode.startsWith('http')) {
      return iconCode;
    }
    // Fallback to a default icon if needed
    return 'https://cdn.weatherapi.com/weather/64x64/day/113.png';
  }

  /// Get weather description in user-friendly format
  String getWeatherDescription(Map<String, dynamic> weatherData) {
    final temp = weatherData['temperature']?.toStringAsFixed(1);
    final description = weatherData['description'] ?? '';
    final city = weatherData['city'] ?? '';
    
    if (temp != null && city.isNotEmpty) {
      return '$city: ${temp}°C, $description';
    } else if (temp != null) {
      return '${temp}°C, $description';
    } else {
      return description.isNotEmpty ? description : 'Weather data unavailable';
    }
  }

  /// Get formatted temperature
  String getFormattedTemperature(Map<String, dynamic> weatherData) {
    final temp = weatherData['temperature'];
    if (temp != null) {
      return '${temp.toStringAsFixed(1)}°C';
    }
    return 'N/A';
  }

  /// Get weather summary for diary entry
  String getWeatherSummary(Map<String, dynamic> weatherData) {
    final temp = weatherData['temperature']?.toStringAsFixed(1);
    final description = weatherData['description'] ?? '';
    final humidity = weatherData['humidity'];
    final windSpeed = weatherData['windSpeed'];
    
    List<String> parts = [];
    
    if (temp != null) {
      parts.add('${temp}°C');
    }
    if (description.isNotEmpty) {
      parts.add(description);
    }
    if (humidity != null) {
      parts.add('Humidity: ${humidity}%');
    }
    if (windSpeed != null) {
      parts.add('Wind: ${windSpeed.toStringAsFixed(1)} m/s');
    }
    
    return parts.join(' • ');
  }
}
