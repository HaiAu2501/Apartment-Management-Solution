import 'package:flutter/material.dart';

class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khiếu nại'),
      ),
      body: const Center(
        child: Text('Chào mừng bạn đến với ứng dụng Quản Lý Chung Cư!'),
      ),
    );
  }
}
