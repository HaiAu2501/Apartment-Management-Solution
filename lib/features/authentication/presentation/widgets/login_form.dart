import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../../../resident_management/presentation/pages/resident_list_page.dart';

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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResidentListPage(),
                            ),
                          );
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
}
