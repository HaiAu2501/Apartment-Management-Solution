// lib/features/admin/presentation/widgets/fee_statistics.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FeeStatistics extends StatelessWidget {
  const FeeStatistics({Key? key}) : super(key: key);

  // Dữ liệu giả cho biểu đồ tròn
  final List<_PieChartSectionData> pieChartSections = const [
    _PieChartSectionData(
      title: 'Hàng tháng',
      value: 40,
      count: 4,
      color: Colors.blueAccent,
    ),
    _PieChartSectionData(
      title: 'Hàng quý',
      value: 30,
      count: 3,
      color: Colors.greenAccent,
    ),
    _PieChartSectionData(
      title: 'Hàng năm',
      value: 30,
      count: 3,
      color: Colors.orangeAccent,
    ),
  ];

  // Tổng số lượng phí (dữ liệu giả)
  final int totalFees = 10;

  // Dữ liệu giả cho biểu đồ đường
  final List<_LineChartDataPoint> lineChartDataPoints = const [
    _LineChartDataPoint(month: 'Jan', amount: 500),
    _LineChartDataPoint(month: 'Feb', amount: 700),
    _LineChartDataPoint(month: 'Mar', amount: 600),
    _LineChartDataPoint(month: 'Apr', amount: 800),
    _LineChartDataPoint(month: 'May', amount: 750),
    _LineChartDataPoint(month: 'Jun', amount: 900),
    _LineChartDataPoint(month: 'Jul', amount: 850),
    _LineChartDataPoint(month: 'Aug', amount: 950),
    _LineChartDataPoint(month: 'Sep', amount: 1000),
    _LineChartDataPoint(month: 'Oct', amount: 1100),
    _LineChartDataPoint(month: 'Nov', amount: 1050),
    _LineChartDataPoint(month: 'Dec', amount: 1200),
  ];

  // Hàm tạo các phần của biểu đồ tròn
  List<PieChartSectionData> getPieSections() {
    return pieChartSections.map((section) {
      return PieChartSectionData(
        color: section.color,
        value: section.value,
        title: '${section.value}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Hàm tạo dữ liệu cho biểu đồ đường
  LineChartData getLineChartData() {
    List<FlSpot> spots = [];
    for (int i = 0; i < lineChartDataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), lineChartDataPoints[i].amount));
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: leftTitleWidgets,
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
                'Tháng ${lineChartDataPoints[touchedSpot.spotIndex].month}\n'
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
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
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

  // Widget cho các tiêu đề trục Y
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    String text;
    if (value == 0) {
      text = '0k';
    } else if (value % 200 == 0) {
      text = '${value ~/ 1000}k';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row chứa biểu đồ tròn và biểu đồ đường
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Biểu đồ tròn với chú thích bổ sung
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
                          'Phân Bổ Khoản Phí',
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Biểu đồ tròn
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sections: getPieSections(),
                                    centerSpaceRadius: 30,
                                    sectionsSpace: 2,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Chú thích bổ sung
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng số khoản phí: $totalFees',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...pieChartSections.map((section) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              color: section.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${section.title}: ${section.count} phí',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
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
                          child: LineChart(getLineChartData()),
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
                    'Bạn còn 10 ngày nữa để đến hạn khoản phí gần nhất.',
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
  }
}

// Lớp hỗ trợ cho dữ liệu biểu đồ tròn
class _PieChartSectionData {
  final String title;
  final double value; // Giá trị phần trăm
  final int count; // Số lượng khoản phí
  final Color color;

  const _PieChartSectionData({
    required this.title,
    required this.value,
    required this.count,
    required this.color,
  });
}

// Lớp hỗ trợ cho dữ liệu biểu đồ đường
class _LineChartDataPoint {
  final String month;
  final double amount;

  const _LineChartDataPoint({
    required this.month,
    required this.amount,
  });
}
