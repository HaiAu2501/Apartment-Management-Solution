// lib/features/admin/presentation/widgets/fee_statistics.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/fees_repository.dart';

/// Lớp hỗ trợ cho dữ liệu biểu đồ đường
class LineChartDataPoint {
  final String month;
  final double amount;

  const LineChartDataPoint({
    required this.month,
    required this.amount,
  });
}

class FeeStatistics extends StatefulWidget {
  final FeesRepository feesRepository;
  final String idToken;

  const FeeStatistics({
    Key? key,
    required this.feesRepository,
    required this.idToken,
  }) : super(key: key);

  @override
  _FeeStatisticsState createState() => _FeeStatisticsState();
}

class _FeeStatisticsState extends State<FeeStatistics> {
  late Future<Map<String, dynamic>> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _fetchStatistics();
  }

  Future<Map<String, dynamic>> _fetchStatistics() async {
    try {
      final frequencies = await widget.feesRepository.getFeeFrequencies(widget.idToken);
      final nearestDueDays = await widget.feesRepository.getNearestFeeDueDays(widget.idToken);
      return {
        'frequencies': frequencies,
        'nearestDueDays': nearestDueDays,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  // Hàm tạo các phần của biểu đồ tròn
  List<PieChartSectionData> _getPieSections(Map<String, int> frequencies) {
    final List<String> frequencyLabels = [
      'Hàng tuần',
      'Hàng tháng',
      'Hàng quý',
      'Hàng năm',
      'Một lần',
      'Không bắt buộc',
      'Khác',
    ];

    double total = frequencies.values.fold(0, (sum, item) => sum + item);

    return frequencyLabels.map((label) {
      final value = frequencies[label] ?? 0;
      final double percentage = total > 0 ? (value / total) * 100 : 0;

      return PieChartSectionData(
        color: _getFrequencyColor(label),
        value: percentage,
        title: percentage > 0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 40, // Giảm giá trị radius để biểu đồ vừa vặn hơn
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Hàm tạo dữ liệu cho biểu đồ đường
  LineChartData _getLineChartData(List<LineChartDataPoint> dataPoints) {
    List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i].amount));
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: _leftTitleWidgetsLineChart,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.purple,
          barWidth: 4,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 1300,
      lineTouchData: LineTouchData(
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.purple, strokeWidth: 2),
              FlDotData(show: true),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              return LineTooltipItem(
                'Tháng ${_lineChartDataPoints[touchedSpot.spotIndex].month}\n'
                'Thu nhập: ${touchedSpot.y.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // Widget cho các tiêu đề trục X
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Jan', style: style);
        break;
      case 1:
        text = const Text('Feb', style: style);
        break;
      case 2:
        text = const Text('Mar', style: style);
        break;
      case 3:
        text = const Text('Apr', style: style);
        break;
      case 4:
        text = const Text('May', style: style);
        break;
      case 5:
        text = const Text('Jun', style: style);
        break;
      case 6:
        text = const Text('Jul', style: style);
        break;
      case 7:
        text = const Text('Aug', style: style);
        break;
      case 8:
        text = const Text('Sep', style: style);
        break;
      case 9:
        text = const Text('Oct', style: style);
        break;
      case 10:
        text = const Text('Nov', style: style);
        break;
      case 11:
        text = const Text('Dec', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  // Widget cho các tiêu đề trục Y của biểu đồ đường
  Widget _leftTitleWidgetsLineChart(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    String text;
    if (value == 0) {
      text = '0k';
    } else if (value % 200 == 0) {
      text = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  /// Lấy màu sắc dựa trên tần suất
  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'Hàng tuần':
        return Colors.blueAccent;
      case 'Hàng tháng':
        return Colors.greenAccent;
      case 'Hàng quý':
        return Colors.orangeAccent;
      case 'Hàng năm':
        return Colors.purpleAccent;
      case 'Một lần':
        return Colors.redAccent;
      case 'Không bắt buộc':
        return Colors.tealAccent;
      case 'Khác':
      default:
        return Colors.grey;
    }
  }

  /// Lấy nhãn tần suất dựa trên chỉ số cột
  String _getFrequencyLabel(int index) {
    const List<String> frequencyLabels = [
      'Hàng tuần',
      'Hàng tháng',
      'Hàng quý',
      'Hàng năm',
      'Một lần',
      'Không bắt buộc',
      'Khác',
    ];

    if (index >= 0 && index < frequencyLabels.length) {
      return frequencyLabels[index];
    } else {
      return '';
    }
  }

  /// Dữ liệu biểu đồ đường giả định, sẽ thay thế bằng dữ liệu thực nếu cần
  final List<LineChartDataPoint> _lineChartDataPoints = const [
    LineChartDataPoint(month: 'Jan', amount: 500),
    LineChartDataPoint(month: 'Feb', amount: 700),
    LineChartDataPoint(month: 'Mar', amount: 600),
    LineChartDataPoint(month: 'Apr', amount: 800),
    LineChartDataPoint(month: 'May', amount: 750),
    LineChartDataPoint(month: 'Jun', amount: 900),
    LineChartDataPoint(month: 'Jul', amount: 850),
    LineChartDataPoint(month: 'Aug', amount: 950),
    LineChartDataPoint(month: 'Sep', amount: 1000),
    LineChartDataPoint(month: 'Oct', amount: 1100),
    LineChartDataPoint(month: 'Nov', amount: 1050),
    LineChartDataPoint(month: 'Dec', amount: 1200),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final frequencies = Map<String, int>.from(data['frequencies']);
          final nearestDueDays = data['nearestDueDays'] as int;

          // Xử lý lời nhắc
          String reminderText;
          if (nearestDueDays == -1) {
            reminderText = 'Không có khoản phí nào sắp đến hạn.';
          } else if (nearestDueDays == 0) {
            reminderText = 'Khoản phí gần nhất đến hạn hôm nay.';
          } else if (nearestDueDays > 0) {
            reminderText = 'Bạn còn $nearestDueDays ngày nữa để đến hạn khoản phí gần nhất.';
          } else {
            reminderText = 'Không có dữ liệu về hạn khoản phí.';
          }

          return Column(
            children: [
              // Row chứa biểu đồ tròn và biểu đồ đường
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Biểu đồ tròn với chú thích bên phải
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 250, // Đặt chiều cao cố định
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Biểu đồ tròn
                              Expanded(
                                flex: 2,
                                child: AspectRatio(
                                  aspectRatio: 1, // Đảm bảo biểu đồ tròn giữ tỷ lệ
                                  child: PieChart(
                                    PieChartData(
                                      sections: _getPieSections(frequencies),
                                      centerSpaceRadius: 30,
                                      sectionsSpace: 2,
                                      borderData: FlBorderData(show: false),
                                      pieTouchData: PieTouchData(
                                        enabled: true,
                                        touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                                          // Xử lý touch nếu cần
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Chú thích bên phải
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: frequencies.entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              color: _getFrequencyColor(entry.key),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${entry.key}: ${entry.value} khoản phí',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Biểu đồ đường
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 250, // Đặt chiều cao cố định
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tiêu đề
                              Text(
                                'Thu Nhập Theo Tháng',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Nội dung chính
                              Expanded(
                                child: LineChart(_getLineChartData(_lineChartDataPoints)),
                              ),
                              const SizedBox(height: 8),
                              // Chú thích
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Tổng Thu Nhập'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nhắc nhở ngày đến hạn
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.redAccent[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          reminderText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }
}
