import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../admin/presentation/home_page.dart';
import '../../resident/presentation/resident_home_page.dart';
import '../../third_party/presentation/third_party_home_page.dart';

class HomePage extends StatelessWidget {
  final String role;
  final String idToken;
  final String uid;
  final AuthenticationService authService;

  const HomePage({
    super.key,
    required this.role,
    required this.idToken,
    required this.uid,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    Widget homepageContent;

    switch (role) {
      case 'admin':
        homepageContent = AdminHomePage(
          authService: authService,
          idToken: idToken,
          uid: uid,
        );
        break;
      case 'resident':
        homepageContent = ResidentHomePage(
          authService: authService,
          idToken: idToken,
          uid: uid,
        );
        break;
      case 'third_party':
        homepageContent = ThirdPartyHomePage(
          authService: authService,
          idToken: idToken,
          uid: uid,
        );
        break;
      default:
        homepageContent = const Center(
          child: Text('Vai trò không hợp lệ.'),
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ'),
      ),
      body: homepageContent,
    );
  }
}
