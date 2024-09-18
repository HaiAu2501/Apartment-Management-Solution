import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/register_form.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text('Đăng Ký')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: RegisterForm(),
        ),
      ),
    );
  }
}
