import 'package:flutter/material.dart';
import 'widgets/weather.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  // Helper widget để tạo các card
  Widget _buildCard(String title, String content, {IconData? icon}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.lightGreen[100],
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 30,
                color: Colors.green[700],
              ),
            if (icon != null) const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const WeatherApiWidget(location: 'Hanoi'), // Widget thời tiết
            const SizedBox(height: 20),

            // Hàng 1: 3 card
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    'Thông Báo Quan Trọng',
                    'Các thông báo mới nhất từ ban quản lý.',
                    icon: Icons.notifications,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Tóm Tắt Tài Chính',
                    'Tình hình tài chính hiện tại và các khoản chi tiêu gần đây.',
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Trạng Thái Hệ Thống',
                    'Trạng thái các hệ thống quan trọng trong chung cư.',
                    icon: Icons.settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hàng 2: 2 card
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    'Cảnh Báo & Bảo Trì',
                    'Các cảnh báo về bảo trì và công việc bảo trì đang tiến hành.',
                    icon: Icons.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Phản Hồi & Đánh Giá',
                    'Phản hồi và đánh giá gần đây từ cư dân.',
                    icon: Icons.feedback,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hàng 3: 4 card
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    'Trạng Thái An Ninh',
                    'Thông tin về hệ thống an ninh và các sự cố an ninh.',
                    icon: Icons.security,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Tài Liệu Quan Trọng',
                    'Truy cập nhanh đến các tài liệu quan trọng.',
                    icon: Icons.folder,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Cập Nhật Phần Mềm',
                    'Phiên bản hiện tại và các bản vá lỗi mới nhất.',
                    icon: Icons.update,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'Lịch Sử & Ghi Chép',
                    'Lịch sử các hoạt động đã diễn ra trong hệ thống.',
                    icon: Icons.history,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Trang chủ đang được phát triển...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
