import 'package:flutter/material.dart';
import 'features/.authentication/data/authentication_service.dart';
import 'features/.authentication/presentation/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String apiKey = 'AIzaSyBtspfJdmslGCkv5MvWu9gkMYuLNwvfzKU';
  final String projectId = 'apartment-management-solution';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthenticationService(apiKey: apiKey, projectId: projectId);

    return MaterialApp(
      title: 'Quản Lý Chung Cư',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(authService: authService),
    );
  }
}
