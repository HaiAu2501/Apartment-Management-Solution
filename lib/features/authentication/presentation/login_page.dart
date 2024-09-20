// lib/features/authentication/presentation/login_page.dart

import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final AuthenticationService authService;

  LoginPage({required this.authService});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ email và mật khẩu.';
        isLoading = false;
      });
      return;
    }

    try {
      // Đăng nhập người dùng
      String? idToken = await widget.authService.signIn(email, password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Lấy vai trò từ Firestore
          String? role = await widget.authService.getUserRole(uid, idToken);
          if (role != null) {
            if (role == 'admin' ||
                role == 'resident' ||
                role == 'third_party') {
              // Chuyển hướng tới trang chủ tương ứng
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    role: role,
                    idToken: idToken,
                    uid: uid,
                    authService: widget.authService,
                  ),
                ),
              );
            } else {
              setState(() {
                errorMessage = 'Vai trò không hợp lệ.';
                isLoading = false;
              });
            }
          } else {
            setState(() {
              errorMessage = 'Không xác định được vai trò người dùng.';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'Không lấy được UID người dùng.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Đăng nhập thất bại.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Đăng Nhập'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
              child: SingleChildScrollView(
                  child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: Text('Đăng Nhập'),
                    ),
              SizedBox(height: 10),
              TextButton(
                onPressed: navigateToRegister,
                child: Text('Chưa có tài khoản? Đăng ký ngay!'),
              )
            ],
          ))),
        ));
  }
}

// Extension để viết hoa chữ cái đầu
extension StringCasingExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
