// lib/features/authentication/presentation/register_page.dart

import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'user_info_page.dart';
import 'package:ams/core/utils/extensions.dart';

class RegisterPage extends StatefulWidget {
  final AuthenticationService authService;

  RegisterPage({required this.authService});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'resident'; // Mặc định là resident

  bool isLoading = false;
  String? message;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String role = selectedRole;

    try {
      // Đăng ký người dùng
      String? idToken = await widget.authService.signUp(email, password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          setState(() {
            message = 'Đăng ký thành công! Hãy nhập thêm thông tin cá nhân.';
            isLoading = false;
          });
          // Chuyển hướng tới trang nhập thông tin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoPage(
                authService: widget.authService,
                idToken: idToken,
                uid: uid,
                role: role,
              ),
            ),
          );
        } else {
          setState(() {
            message = 'Không lấy được UID người dùng.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          message = 'Đăng ký thất bại.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Đăng Ký'),
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
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Vai trò
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Vai trò'),
                  items:
                      <String>['resident', 'third_party'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.capitalize()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn vai trò.';
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
                        onPressed: register,
                        child: Text('Đăng Ký'),
                      ),
              ],
            ),
          ))),
        ));
  }
}
