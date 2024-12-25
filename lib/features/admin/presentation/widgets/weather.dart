// weather_api_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'dart:async';
import '../../../../features/.authentication/data/weather_service.dart';
import '../../domain/weather_forecast.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/weather_translation.dart'; // Ensure correct path

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

  // Track the currently expanded index
  int? _expandedIndex;

  // Fixed height
  final double fixedHeight = 160.0;

  @override
  void initState() {
    super.initState();
    // Initialize WeatherApiService with a real API key
    _weatherService = WeatherApiService(apiKey: '152f1bb7ea9d40608d754333242512'); // Replace with actual API key
    _futureForecast = _weatherService.fetchWeatherForecast(location: widget.location, days: 7);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String translateCondition(String condition) {
    // Convert condition string to lowercase and trim whitespace
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

  // Map weather conditions to background colors
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

  // Handle expansion and collapse
  void _handleExpand(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
        print('Collapsed WeatherDetail for index $index');
      } else {
        _expandedIndex = index;
        print('Expanded WeatherDetail for index $index');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Current expanded index: $_expandedIndex');

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate container width based on screen size
      double screenWidth = constraints.maxWidth;
      double containerWidth = screenWidth > 600 ? 190 : 170; // Reduced from 200 to 190 and from 160 to 150

      return Container(
        color: Colors.blueGrey[50], // Overall background color
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<WeatherForecast>>(
          future: _futureForecast,
          builder: (context, snapshot) {
            print('Connection State: ${snapshot.connectionState}');
            if (snapshot.hasData) {
              print('Data received: ${snapshot.data}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading state
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Error state
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // No data state
              return const Center(
                child: Text(
                  'No weather data available.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            } else {
              // Data loaded successfully
              final forecasts = snapshot.data!;

              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true, // Always show scrollbar
                thickness: 8.0, // Scrollbar thickness
                radius: const Radius.circular(4.0),
                child: SizedBox(
                  height: fixedHeight, // Fixed height to prevent overflow
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                    physics: const BouncingScrollPhysics(), // Scrolling effect
                    itemCount: forecasts.length,
                    itemBuilder: (context, index) {
                      WeatherForecast forecast = forecasts[index];

                      // Calculate date and day of week for each box
                      DateTime date = DateTime.now().add(Duration(days: index));
                      String dayOfWeek = DateFormat('EEEE', 'vi').format(date); // Get day
                      String dateString = DateFormat('dd/MM/yyyy').format(date); // Get date

                      // Original condition to determine background color
                      String originalCondition = forecast.conditionText;

                      // Translate weather condition
                      String conditionText = translateCondition(originalCondition);

                      // Determine background color based on original condition
                      Color bgColor = getBackgroundColor(originalCondition);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: containerWidth + (_expandedIndex == index ? 200 + 16.0 : 8),
                        child: Stack(
                          clipBehavior: Clip.none, // Ensure content can overflow
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
    // Make the weather icon tappable to toggle WeatherDetail
    Widget weatherIcon = MouseRegion(
      cursor: SystemMouseCursors.click, // Thay đổi hình dạng con trỏ thành hình bàn tay
      child: GestureDetector(
        onTap: () {
          onExpand(index);
        },
        child: CachedNetworkImage(
          imageUrl: forecast.conditionIcon.startsWith('http') ? forecast.conditionIcon : 'https:${forecast.conditionIcon}',
          width: 50, // Increased icon size
          height: 50,
          placeholder: (context, url) => const SizedBox(
            width: 50,
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.all(0.0), // Ensure no padding
      height: fixedHeight, // Fixed height to match parent
      decoration: BoxDecoration(
        color: backgroundColor, // Dynamic background color
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(0.0), // Smooth corners
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Changed từ center để thêm khoảng cách từ trên
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // **Thêm Khoảng Cách Từ Trên**
          SizedBox(height: 8.0), // Thêm khoảng cách từ trên, bạn có thể điều chỉnh giá trị này

          // Main content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Để các phần bắt đầu từ trên
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // **Adjusted Section: Padding Around Day and Date**
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added horizontal padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          fontSize: 14, // Reduced font size from 16 to 14
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 14, // Reduced font size from 16 to 14
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // **Adjusted Section: Average Temperature**
                // Changed from Row to Column to move value to the next line and center it
                Column(
                  children: [
                    Text(
                      'Nhiệt độ trung bình:',
                      style: TextStyle(
                        fontSize: 14, // Adjusted font size
                        color: Colors.blueGrey[700],
                      ),
                      textAlign: TextAlign.center, // Center the text
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${forecast.tempC.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 17, // Adjusted font size from 24 to 17
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      textAlign: TextAlign.center, // Center the text
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Tappable Weather Icon
                weatherIcon,
              ],
            ),
          ),
          const SizedBox(height: 12), // Optional spacing
        ],
      ),
    );
  }
}

class WeatherDetail extends StatefulWidget {
  final WeatherForecast forecast;
  final VoidCallback onClose;
  final double fixedHeight;
  final String translatedConditionText; // Added parameter

  const WeatherDetail({
    Key? key,
    required this.forecast,
    required this.onClose,
    required this.fixedHeight,
    required this.translatedConditionText, // Added parameter
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
      begin: const Offset(-1.0, 0.0), // Slide từ trái
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
  final String translatedConditionText; // Added parameter

  const WeatherDetailContent({
    Key? key,
    required this.forecast,
    required this.onClose,
    required this.fixedHeight,
    required this.translatedConditionText, // Added parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: fixedHeight, // Fixed height matching main boxes
      padding: const EdgeInsets.all(12.0), // Reduced from 16.0 to 12.0
      margin: const EdgeInsets.all(0), // Increased from 8.0 to 12.0 for more spacing
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(0.0), // Smooth corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **Adjusted Section: Centered Title**
          // Changed from Row with Expanded to Center widget to center the title
          Center(
            child: Text(
              translatedConditionText, // Use translated value
              style: const TextStyle(
                fontSize: 14, // Reduced from 16 to 14
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center, // Center the text
            ),
          ),
          const SizedBox(height: 8),
          // Detailed information
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nhiệt độ (Temperature)
              Text(
                'Cao nhất: ${forecast.minTempC.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                'Thấp nhất: ${forecast.maxTempC.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              // Gió (Wind)
              Text(
                'Gió: ${forecast.windKph.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              // Độ ẩm (Humidity)
              Text(
                'Độ ẩm: ${forecast.humidity}%',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              // Lượng mưa (Precipitation)
              Text(
                'Lượng mưa: ${forecast.precipitationMm} mm',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
