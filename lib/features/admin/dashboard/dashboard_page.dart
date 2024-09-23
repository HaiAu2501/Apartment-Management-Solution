import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
      ),
      body: const Center(
        child: Text('Chào mừng bạn đến với ứng dụng Quản Lý Chung Cư!'),
      ),
    );
  }
}
