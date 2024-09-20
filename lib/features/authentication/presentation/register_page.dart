import 'package:flutter/material.dart';
import '../data/authentication_service.dart';

class RegisterPage extends StatefulWidget {
  final AuthenticationService authService;

  RegisterPage({required this.authService});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'resident'; // Mặc định là resident

  bool isLoading = false;
  String? message;

  Future<void> register() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String role = selectedRole;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = 'Vui lòng nhập đầy đủ email và mật khẩu.';
        isLoading = false;
      });
      return;
    }

    try {
      // Đăng ký người dùng
      String? idToken = await widget.authService.signUp(email, password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Tạo tài liệu người dùng trong Firestore với vai trò được chọn
          bool success = await widget.authService
              .createUserDocument(idToken, uid, email, role);
          if (success) {
            setState(() {
              message =
                  'Đăng ký thành công! Bạn có thể đăng nhập ngay bây giờ.';
              isLoading = false;
            });
          } else {
            setState(() {
              message = 'Đăng ký thất bại.';
              isLoading = false;
            });
          }
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
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(labelText: 'Vai trò'),
                items: <String>['resident', 'third_party'].map((String value) {
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
              ),
              SizedBox(height: 20),
              if (message != null)
                Text(
                  message!,
                  style: TextStyle(
                      color: message!.contains('thành công')
                          ? Colors.green
                          : Colors.red),
                ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register,
                      child: Text('Đăng Ký'),
                    ),
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
