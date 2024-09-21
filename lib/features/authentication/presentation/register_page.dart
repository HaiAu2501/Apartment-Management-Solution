import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'resident_info_page.dart';
import 'third_party_info_page.dart';

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

  String selectedRole = 'resident'; // Mặc định là 'Cư dân'

  bool isLoading = false;
  String? message;

  Future<void> navigateToInfoPage() async {
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
      // Chuyển hướng tới trang nhập thông tin tương ứng mà không tạo tài khoản
      if (selectedRole == 'resident') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResidentInfoPage(
              authService: widget.authService,
              email: email,
              password: password,
            ),
          ),
        );
      } else if (selectedRole == 'thirdParty') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ThirdPartyInfoPage(
              authService: widget.authService,
              email: email,
              password: password,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi chuyển hướng: $e');
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
                  items: <String>['resident', 'thirdParty'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'resident' ? 'Cư Dân' : 'Bên Thứ 3'),
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
                        onPressed: navigateToInfoPage,
                        child: Text('Đăng Ký'),
                      ),
              ],
            ),
          ))),
        ));
  }
}
