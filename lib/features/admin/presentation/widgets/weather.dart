// weather_api_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'dart:async';
import '../../../../features/.authentication/data/weather_service.dart';
import '../../domain/weather_forecast.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/weather_translation.dart'; // Đảm bảo đường dẫn đúng

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

  // Theo dõi chỉ số đang mở rộng
  int? _expandedIndex;

  //chiều cao cố định
  final double fixedHeight = 230.0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo WeatherApiService với API key thực tế
    _weatherService = WeatherApiService(apiKey: '5a177b13d873492ca8f71841242310'); // Thay bằng API key thực tế
    _futureForecast = _weatherService.fetchWeatherForecast(location: widget.location, days: 7);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String translateCondition(String condition) {
    // Chuyển đổi chuỗi điều kiện sang lowercase và loại bỏ khoảng trắng thừa
    String normalizedCondition = condition.toLowerCase().trim();
    return weatherTranslations[normalizedCondition] ?? condition;
  }

  bool isDesktop() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  // Bản đồ điều kiện thời tiết sang màu nền
  Color getBackgroundColor(String condition) {
    switch (condition.toLowerCase()) {
      // **Sunny Conditions**
      case 'sunny':
        return Colors.yellow[200]!;

      // **Partly Cloudy Conditions**
      case 'patchy rain nearby':
      case 'patchy light drizzle':
      case 'patchy light rain':
      case 'patchy light snow':
      case 'patchy moderate snow':
      case 'patchy heavy snow':
      case 'patchy snow possible':
      case 'patchy sleet possible':
      case 'patchy freezing drizzle possible':
        return Colors.lightBlue[100]!;

      // **Cloudy and Foggy Conditions**
      case 'cloudy':
      case 'partly cloudy':
      case 'có mây':
      case 'overcast':
      case 'fog':
      case 'freezing fog':
        return const Color.fromARGB(255, 63, 55, 55)!;

      // **Rain Conditions**
      case 'light drizzle':
      case 'freezing drizzle':
      case 'heavy freezing drizzle':
      case 'light rain':
      case 'moderate rain at times':
      case 'moderate rain':
      case 'heavy rain at times':
      case 'heavy rain':
      case 'light freezing rain':
      case 'moderate or heavy freezing rain':
      case 'light rain shower':
      case 'moderate or heavy rain shower':
      case 'torrential rain shower':
      case 'light showers of ice pellets':
      case 'moderate or heavy showers of ice pellets':
      case 'patchy light rain with thunder':
      case 'moderate or heavy rain with thunder':
        return Colors.blue[200]!;

      // **Snow Conditions**
      case 'blowing snow':
      case 'blizzard':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
      case 'light snow showers':
      case 'moderate or heavy snow showers':
        return Colors.blueGrey[200]!;

      // **Thunderstorm Conditions**
      case 'thundery outbreaks possible':
      case 'thunderstorm':
        return Colors.deepPurple[200]!;

      // **Sleet Conditions**
      case 'light sleet':
      case 'moderate or heavy sleet':
      case 'light sleet showers':
      case 'moderate or heavy sleet showers':
        return Colors.blueGrey[300]!;

      // **Ice Pellets Conditions**
      case 'ice pellets':
        return Colors.grey[400]!;

      // **Default Condition**
      default:
        return Colors.white;
    }
  }

  // Xử lý mở rộng và thu gọn
  void _handleExpand(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
        print('Đã thu gọn WeatherDetail cho index $index');
      } else {
        _expandedIndex = index;
        print('Đã mở rộng WeatherDetail cho index $index');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Chỉ số mở rộng hiện tại: $_expandedIndex');

    return LayoutBuilder(builder: (context, constraints) {
      // Tính toán chiều rộng container dựa trên kích thước màn hình
      double screenWidth = constraints.maxWidth;
      double containerWidth = screenWidth > 600 ? 190 : 150; // Giảm từ 200 xuống 180 và từ 160 xuống 140

      return Container(
        color: Colors.blueGrey[50], // Màu nền tổng thể
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<WeatherForecast>>(
          future: _futureForecast,
          builder: (context, snapshot) {
            print('Connection State: ${snapshot.connectionState}');
            if (snapshot.hasData) {
              print('Data received: ${snapshot.data}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Trạng thái đang tải
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
              // Trạng thái không có dữ liệu
              return const Center(
                child: Text(
                  'Không có dữ liệu thời tiết.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            } else {
              // Dữ liệu đã tải thành công
              final forecasts = snapshot.data!;

              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true, // Luôn hiển thị scrollbar
                thickness: 8.0, // Độ dày scrollbar
                radius: const Radius.circular(4.0),
                child: SizedBox(
                  height: fixedHeight, // Chiều cao cố định để ngăn overflow
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal, // Kích hoạt cuộn ngang
                    physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn
                    itemCount: forecasts.length,
                    itemBuilder: (context, index) {
                      WeatherForecast forecast = forecasts[index];

                      // Tính toán ngày và thứ trong tuần cho mỗi ô
                      DateTime date = DateTime.now().add(Duration(days: index));
                      String dayOfWeek = DateFormat('EEEE', 'vi').format(date); // Lấy thứ
                      String dateString = DateFormat('dd/MM/yyyy').format(date); // Lấy ngày

                      // Điều kiện gốc để xác định màu nền
                      String originalCondition = forecast.conditionText;

                      // Dịch điều kiện thời tiết
                      String conditionText = translateCondition(originalCondition);

                      // Xác định màu nền dựa trên điều kiện gốc
                      Color bgColor = getBackgroundColor(originalCondition);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: containerWidth + (_expandedIndex == index ? 200 + 16.0 : 8),
                        child: Stack(
                          clipBehavior: Clip.none, // Thêm dòng này
                          children: [
                            if (_expandedIndex == index)
                              Positioned(
                                left: containerWidth + 7.5,
                                top: 0,
                                child: WeatherDetail(
                                  forecast: forecast,
                                  onClose: () {
                                    _handleExpand(index);
                                  },
                                  fixedHeight: fixedHeight,
                                  translatedConditionText: conditionText,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                WeatherBox(
                                  index: index,
                                  containerWidth: containerWidth,
                                  dayOfWeek: dayOfWeek,
                                  dateString: dateString,
                                  forecast: forecast,
                                  conditionText: conditionText,
                                  isDesktop: isDesktop(),
                                  backgroundColor: bgColor,
                                  onExpand: _handleExpand,
                                  isExpanded: _expandedIndex == index,
                                  fixedHeight: fixedHeight,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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

class WeatherBox extends StatelessWidget {
  final int index;
  final double containerWidth;
  final String dayOfWeek;
  final String dateString;
  final WeatherForecast forecast;
  final String conditionText;
  final bool isDesktop;
  final Color backgroundColor;
  final Function(int) onExpand;
  final bool isExpanded;
  final double fixedHeight;

  const WeatherBox({
    Key? key,
    required this.index,
    required this.containerWidth,
    required this.dayOfWeek,
    required this.dateString,
    required this.forecast,
    required this.conditionText,
    required this.isDesktop,
    required this.backgroundColor,
    required this.onExpand,
    required this.isExpanded,
    required this.fixedHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nút mũi tên
    Widget arrowButton = IconButton(
      icon: Icon(
        isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
        size: 20, // Tăng kích thước để dễ nhìn hơn
        color: Colors.blueGrey[800],
      ),
      onPressed: () {
        onExpand(index);
      },
    );

    // Icon thời tiết
    Widget weatherIcon = CachedNetworkImage(
      imageUrl: forecast.conditionIcon.startsWith('http') ? forecast.conditionIcon : 'https:${forecast.conditionIcon}',
      width: 50, // Tăng kích thước icon
      height: 50,
      placeholder: (context, url) => const SizedBox(
        width: 50,
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
    );

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.all(0.0), // Đảm bảo không có padding
      height: fixedHeight, // Chiều cao cố định để match parent
      decoration: BoxDecoration(
        color: backgroundColor, // Màu nền động
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(0.0), // Bo góc đẹp mắt
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nội dung chính
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ngày và ngày tháng
                Text(
                  '$dayOfWeek\n$dateString',
                  style: TextStyle(
                    fontSize: 14, // Giảm kích thước phông chữ từ 16 xuống 14
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true, // Cho phép ngắt dòng
                ),
                const SizedBox(height: 12),
                // Nhãn "Nhiệt độ trung bình"
                Text(
                  'Nhiệt độ trung bình',
                  style: TextStyle(
                    fontSize: 12, // Giảm kích thước phông chữ từ 14 xuống 12
                    color: Colors.blueGrey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Nhiệt độ trung bình
                Text(
                  '${forecast.tempC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 20, // Giảm kích thước phông chữ từ 24 xuống 20
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 0),
                // Icon thời tiết
                weatherIcon,
              ],
            ),
          ),
          // Nút mũi tên đặt bên dưới
          arrowButton,
          const SizedBox(height: 12)
        ],
      ),
    );
  }
}

class WeatherDetail extends StatefulWidget {
  final WeatherForecast forecast;
  final VoidCallback onClose;
  final double fixedHeight;
  final String translatedConditionText; // Thêm tham số này

  const WeatherDetail({
    Key? key,
    required this.forecast,
    required this.onClose,
    required this.fixedHeight,
    required this.translatedConditionText, // Thêm tham số này
  }) : super(key: key);

  @override
  _WeatherDetailState createState() => _WeatherDetailState();
}

class _WeatherDetailState extends State<WeatherDetail> with SingleTickerProviderStateMixin {
  late AnimationController _detailAnimationController;
  late Animation<Offset> _detailSlideAnimation;

  @override
  void initState() {
    super.initState();
    _detailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _detailSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Changed from 1.0 to -1.0 to slide from left
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _detailAnimationController,
      curve: Curves.easeInOut,
    ));
    _detailAnimationController.forward();
  }

  @override
  void dispose() {
    _detailAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _detailSlideAnimation,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(0.0),
        child: SizedBox(
          width: 200,
          height: widget.fixedHeight,
          child: WeatherDetailContent(
            forecast: widget.forecast,
            onClose: widget.onClose,
            fixedHeight: widget.fixedHeight,
            translatedConditionText: widget.translatedConditionText,
          ),
        ),
      ),
    );
  }
}

class WeatherDetailContent extends StatelessWidget {
  final WeatherForecast forecast;
  final VoidCallback onClose;
  final double fixedHeight;
  final String translatedConditionText; // Thêm tham số này

  const WeatherDetailContent({
    Key? key,
    required this.forecast,
    required this.onClose,
    required this.fixedHeight,
    required this.translatedConditionText, // Thêm tham số này
  }) : super(key: key);

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0), // Giảm từ 4.0 xuống 2.0
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14, // Giảm từ 16 xuống 14
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0), // Giảm từ 4.0 xuống 2.0
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14, // Giảm từ 16 xuống 14
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: fixedHeight, // Chiều cao cố định giống như các ô chính
      padding: const EdgeInsets.all(12.0), // Giảm từ 16.0 xuống 12.0
      margin: const EdgeInsets.all(0), // Tăng từ 8.0 xuống 12.0 để tạo khoảng cách lớn hơn
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(0.0), // Bo góc đẹp mắt
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với nút đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Điều kiện thời tiết đã được dịch
              Expanded(
                child: Text(
                  translatedConditionText, // Sử dụng giá trị đã dịch
                  style: const TextStyle(
                    fontSize: 14, // Giảm kích thước phông chữ từ 16 xuống 14
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Nút đóng
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 0),
          // Bảng thông tin chi tiết
          Table(
            columnWidths: const {
              0: FlexColumnWidth(5),
              1: FlexColumnWidth(6),
            },
            children: [
              _buildTableRow('Nhiệt độ thấp nhất:', '${forecast.minTempC.toStringAsFixed(1)}°C'),
              _buildTableRow('Nhiệt độ cao nhất:', '${forecast.maxTempC.toStringAsFixed(1)}°C'),
              _buildTableRow('Gió:', '${forecast.windKph.toStringAsFixed(1)} km/h'),
              _buildTableRow('Độ ẩm:', '${forecast.humidity}%'),
              _buildTableRow('Lượng mưa:', '${forecast.precipitationMm} mm'),
            ],
          ),
        ],
      ),
    );
  }
}
