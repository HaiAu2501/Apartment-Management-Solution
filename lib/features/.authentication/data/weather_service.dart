// lib/features/.authentication/data/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../admin/domain/weather_forecast.dart';
import 'package:intl/intl.dart';

class WeatherApiService {
  final String apiKey; // Your WeatherAPI.com API key
  final String baseUrl = 'https://api.weatherapi.com/v1/';

  // Initialize apiKey via constructor only
  WeatherApiService({required this.apiKey});

  /// Fetches weather forecast for the next [days] days for a given [location].
  Future<List<WeatherForecast>> fetchWeatherForecast({
    required String location,
    int days = 7, // Number of days to fetch
  }) async {
    final url = Uri.parse('${baseUrl}forecast.json?key=$apiKey&q=$location&days=$days&aqi=no&alerts=no');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      // Optionally, print the response body for debugging
      print('Failed to fetch weather data: ${response.body}');
      throw Exception('Failed to fetch weather data: ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);

    // Check if 'forecast' and 'forecastday' exist
    if (data['forecast'] == null || data['forecast']['forecastday'] == null) {
      print('Invalid response structure: ${response.body}');
      throw Exception('Invalid response structure.');
    }

    final List<dynamic> forecastDays = data['forecast']['forecastday'];

    if (forecastDays.isEmpty) {
      throw Exception('No weather data available.');
    }

    List<WeatherForecast> forecasts = forecastDays.map((day) {
      // Optionally, print each day's data for debugging
      // print('Parsing forecast day: $day');
      return WeatherForecast.fromWeatherApiJson(day);
    }).toList();

    return forecasts;
  }
}
