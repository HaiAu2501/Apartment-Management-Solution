// lib/features/authentication/presentation/login_page.dart

import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ams/core/utils/extensions.dart';

class LoginPage extends StatefulWidget {
  final AuthenticationService authService;

  LoginPage({required this.authService});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? message;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      // Đăng nhập người dùng
      String? idToken = await widget.authService.signIn(email, password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Kiểm tra xem người dùng đã được phê duyệt chưa
          final userDocUrl =
              'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/users/$uid?key=${widget.authService.apiKey}';

          final userResponse = await http.get(
            Uri.parse(userDocUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body)['fields'];
            String role = userData['role']['stringValue'];
            String status = userData['status']['stringValue'];

            if (status == 'approval') {
              // Tài khoản đã được phê duyệt
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
              // Tài khoản chưa được phê duyệt
              setState(() {
                message = 'Tài khoản của bạn đang chờ phê duyệt.';
                isLoading = false;
              });
            }
          } else if (userResponse.statusCode == 404) {
            // Tài khoản chưa được phê duyệt (không có trong 'users' collection)
            setState(() {
              message = 'Tài khoản của bạn đang chờ phê duyệt.';
              isLoading = false;
            });
          } else {
            setState(() {
              message = 'Lỗi khi kiểm tra trạng thái tài khoản.';
              isLoading = false;
            });
            print('Lỗi khi kiểm tra người dùng: ${userResponse.statusCode}');
            print('Chi tiết lỗi: ${userResponse.body}');
          }
        } else {
          setState(() {
            message = 'Không lấy được UID người dùng.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          message = 'Đăng nhập thất bại.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi đăng nhập: $e');
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
                  child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Email
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Email không hợp lệ.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Mật khẩu
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Thông báo
                if (message != null)
                  Text(
                    message!,
                    style: TextStyle(
                        color: message!.contains('thành công')
                            ? Colors.green
                            : Colors.red),
                  ),
                SizedBox(height: 20),
                // Nút Submit
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: login,
                        child: Text('Đăng Nhập'),
                      ),
                SizedBox(height: 10),
                // Nút Đăng Ký
                TextButton(
                  onPressed: navigateToRegister,
                  child: Text('Chưa có tài khoản? Đăng ký ngay!'),
                )
              ],
            ),
          ))),
        ));
  }
}
