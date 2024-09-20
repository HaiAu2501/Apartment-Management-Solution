// lib/features/authentication/presentation/home_page.dart

import 'package:flutter/material.dart';
import '../data/authentication_service.dart';

class HomePage extends StatelessWidget {
  final String role;
  final String idToken;
  final String uid;
  final AuthenticationService authService;

  HomePage({
    required this.role,
    required this.idToken,
    required this.uid,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    String welcomeMessage = '';
    Widget? homepageContent;

    switch (role) {
      case 'admin':
        welcomeMessage = 'Chào mừng Admin!';
        homepageContent = Placeholder(); // Trang chủ dành cho Admin
        break;
      case 'resident':
        welcomeMessage = 'Chào mừng Cư dân!';
        homepageContent = Placeholder(); // Trang chủ dành cho Cư dân
        break;
      case 'third_party':
        welcomeMessage = 'Chào mừng Bên Thứ 3!';
        homepageContent = Placeholder(); // Trang chủ dành cho Bên Thứ 3
        break;
      default:
        welcomeMessage = 'Chào mừng!';
        homepageContent = Placeholder();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang Chủ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(welcomeMessage, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            homepageContent ?? Container(),
          ],
        ),
      ),
    );
  }
}
