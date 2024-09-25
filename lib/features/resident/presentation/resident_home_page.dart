import 'package:flutter/material.dart';
import '../../.authentication/data/authentication_service.dart';
import '../../.authentication/presentation/login_page.dart';

class ResidentHomePage extends StatelessWidget {
  final AuthenticationService authService;
  final String idToken;
  final String uid;

  const ResidentHomePage({
    super.key,
    required this.authService,
    required this.idToken,
    required this.uid,
  });

  // Hàm logout
  Future<void> logout(BuildContext context) async {
    // Thực hiện logout nếu cần (ví dụ: xóa token, dữ liệu cục bộ)
    // Sau đó chuyển hướng về trang đăng nhập
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ Cư Dân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Chức năng dành cho Cư Dân sẽ được phát triển sau.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
