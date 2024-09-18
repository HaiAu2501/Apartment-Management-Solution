import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/login_form.dart';
import '../../../resident_management/presentation/pages/resident_list_page.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text('Đăng Nhập')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: LoginForm(),
        ),
      ),
    );
  }
}
