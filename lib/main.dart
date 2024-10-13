import 'package:flutter/material.dart';
import 'features/.authentication/data/auth_service.dart';
import 'features/.authentication/presentation/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Khai báo apiKey và projectId của dự án Firebase để thao tác với Hệ quản trị Cơ sở dữ liệu Firestore
  final String apiKey = 'AIzaSyBtspfJdmslGCkv5MvWu9gkMYuLNwvfzKU';
  final String projectId = 'apartment-management-solution';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo Dịch vụ xác thực
    final authService = AuthenticationService(apiKey: apiKey, projectId: projectId);

    return MaterialApp(
      title: 'Quản Lý Chung Cư',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Màu nền cho các trang
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // Màu nền của AppBar
        ),
      ),
      // Trang mở đầu của ứng dụng là trang đăng nhập
      home: LoginPage(authService: authService),
    );
  }
}
