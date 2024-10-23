// weather_api_widget.dart

import 'package:flutter/material.dart';
import '../../../../features/.authentication/data/weather_service.dart';
import '../../domain/weather_forecast.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Đảm bảo bạn đã thêm package này
import '../../../../core/utils/weather_translation.dart'; // Import bản đồ chuyển đổi

class WeatherApiWidget extends StatefulWidget {
  final String location;

  const WeatherApiWidget({Key? key, required this.location}) : super(key: key);

  @override
  _WeatherApiWidgetState createState() => _WeatherApiWidgetState();
}

class _WeatherApiWidgetState extends State<WeatherApiWidget> {
  late WeatherApiService _weatherService;
  late Future<List<WeatherForecast>> _futureForecast;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo WeatherApiService với API key
    _weatherService = WeatherApiService(apiKey: '5a177b13d873492ca8f71841242310');
    _futureForecast = _weatherService.fetchWeatherForecast(location: widget.location, days: 7);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String translateCondition(String condition) {
    // Chuẩn hóa chuỗi về chữ thường và loại bỏ khoảng trắng thừa
    String normalizedCondition = condition.toLowerCase().trim();
    return weatherTranslations[normalizedCondition] ?? condition;
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng LayoutBuilder để làm cho bố cục phản hồi
    return LayoutBuilder(builder: (context, constraints) {
      // Tính toán kích thước dựa trên màn hình
      double screenWidth = constraints.maxWidth;
      double containerWidth = screenWidth > 600 ? 200 : 160; // Tùy chỉnh kích thước

      return Container(
        color: Colors.blueGrey[50], // Màu nền tổng thể
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<WeatherForecast>>(
          future: _futureForecast,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Trạng thái tải dữ liệu
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Trạng thái lỗi
              return Center(
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Không có dữ liệu
              return const Center(
                child: Text(
                  'Không có dữ liệu thời tiết.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            } else {
              // Dữ liệu đã được tải thành công
              final forecasts = snapshot.data!;

              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true, // Hiển thị thanh cuộn luôn luôn
                thickness: 8.0, // Độ dày của thanh cuộn
                radius: const Radius.circular(4.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal, // Kích hoạt cuộn ngang
                  physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn
                  child: Row(
                    children: forecasts.asMap().entries.map((entry) {
                      int index = entry.key;
                      WeatherForecast forecast = entry.value;

                      // Tính toán ngày và thứ cho mỗi ô
                      DateTime date = DateTime.now().add(Duration(days: index));
                      String dayOfWeek = DateFormat('EEEE', 'vi').format(date); // Lấy thứ
                      String dateString = DateFormat('dd/MM/yyyy').format(date); // Lấy ngày

                      // Dịch trạng thái thời tiết
                      String conditionText = translateCondition(forecast.conditionText);

                      // Debug: In ra conditionText gốc và đã dịch
                      // print('Original: ${forecast.conditionText} -> Translated: $conditionText');

                      return Container(
                        width: containerWidth, // Kích thước cố định cho mỗi ô
                        margin: const EdgeInsets.symmetric(horizontal: 5.0), // Khoảng cách giữa các ô
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hiển thị ngày và thứ
                            Text(
                              '$dayOfWeek\n$dateString',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: 'https:${forecast.conditionIcon}',
                                  width: 30,
                                  height: 50,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    conditionText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Divider(color: Colors.blueGrey[200]),
                            const SizedBox(height: 4),
                            Text(
                              'Nhiệt độ trung bình: ${forecast.tempC.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhiệt độ thấp nhất: ${forecast.minTempC.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhiệt độ cao nhất: ${forecast.maxTempC.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gió: ${forecast.windKph.toStringAsFixed(1)} km/h',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Độ ẩm: ${forecast.humidity}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lượng mưa: ${forecast.precipitationMm} mm',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
          },
        ),
      );
    });
  }
}
