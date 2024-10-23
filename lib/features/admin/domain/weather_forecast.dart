// lib/domain/weather_forecast.dart

class WeatherForecast {
  final String conditionText;
  final String conditionIcon;
  final DateTime date;
  final double tempC;
  final double tempF;
  final double minTempC;
  final double maxTempC;
  final double windKph;
  final int humidity;
  final double precipitationMm;

  WeatherForecast({
    required this.conditionText,
    required this.conditionIcon,
    required this.date,
    required this.tempC,
    required this.tempF,
    required this.minTempC,
    required this.maxTempC,
    required this.windKph,
    required this.humidity,
    required this.precipitationMm,
  });

  factory WeatherForecast.fromWeatherApiJson(Map<String, dynamic> json) {
    return WeatherForecast(
      conditionText: json['day']['condition']['text'],
      conditionIcon: json['day']['condition']['icon'],
      date: DateTime.parse(json['date']),
      tempC: (json['day']['avgtemp_c'] as num).toDouble(),
      tempF: (json['day']['avgtemp_f'] as num).toDouble(),
      minTempC: (json['day']['mintemp_c'] as num).toDouble(),
      maxTempC: (json['day']['maxtemp_c'] as num).toDouble(),
      windKph: (json['day']['maxwind_kph'] as num).toDouble(),
      humidity: json['day']['avghumidity'],
      precipitationMm: (json['day']['totalprecip_mm'] as num).toDouble(),
    );
  }
}
