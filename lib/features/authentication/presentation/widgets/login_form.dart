import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../../../../../main.dart';
import '../../../resident_management/presentation/pages/resident_home_page.dart';
import '../../../resident_management/presentation/pages/admin_home_page.dart';
import '../../../resident_management/presentation/pages/third_party_home_page.dart';
import 'change_password_form.dart';

class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _error = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return _loading
        ? Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(
              children: [
                // Email
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: Validators.validateEmail,
                  onSaved: (value) => _email = value!,
                ),
                // Mật khẩu
                TextFormField(
                  decoration: InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: Validators.validatePassword,
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),
                // Nút đăng nhập
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      setState(() {
                        _loading = true;
                        _error = '';
                      });
                      try {
                        await authProvider.login(_email, _password);
                        if (authProvider.user != null) {
                          if (authProvider.user!.status == 'pending') {
                            // Yêu cầu đổi mật khẩu và nhập thông tin cá nhân
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordForm(),
                              ),
                            );
                          } else {
                            // Điều hướng dựa trên vai trò
                            navigateBasedOnRole(authProvider.user!.role);
                          }
                        }
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                          _loading = false;
                        });
                      }
                    }
                  },
                  child: Text('Đăng Nhập'),
                ),
                SizedBox(height: 12),
                // Hiển thị lỗi
                Text(
                  _error,
                  style: TextStyle(color: Colors.red),
                ),
                // Nút chuyển đến trang đăng ký
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Chưa có tài khoản? Đăng ký'),
                ),
              ],
            ),
          );
  }

  void navigateBasedOnRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminHomePage()),
      );
    } else if (role == 'resident') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResidentHomePage()),
      );
    } else if (role == 'third_party') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ThirdPartyHomePage()),
      );
    } else {
      // Xử lý trường hợp không xác định
    }
  }
}
