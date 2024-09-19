import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterForm extends StatefulWidget {
  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
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
                // Xác nhận mật khẩu
                TextFormField(
                  decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                  onSaved: (value) => _confirmPassword =
                      value!, // Lưu giá trị vào biến _confirmPassword
                  validator: (value) {
                    if (value != _password) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),
                // Nút đăng ký
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      setState(() {
                        _loading = true;
                        _error = '';
                      });
                      try {
                        await authProvider.register(_email, _password);
                        if (authProvider.user != null) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                          _loading = false;
                        });
                      }
                    }
                  },
                  child: Text('Đăng Ký'),
                ),
                SizedBox(height: 12),
                // Hiển thị lỗi
                Text(
                  _error,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
  }
}
