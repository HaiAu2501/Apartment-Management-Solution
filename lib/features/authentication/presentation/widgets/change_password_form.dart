import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import này

class ChangePasswordForm extends StatefulWidget {
  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String _newPassword = '';
  String _confirmPassword = '';
  String _fullName = '';
  String _phoneNumber = '';
  String _error = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Hoàn Thiện Thông Tin')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // Thêm để tránh overflow
                  child: Column(
                    children: [
                      // Mật khẩu mới
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Mật khẩu mới'),
                        obscureText: true,
                        validator: Validators.validatePassword,
                        onSaved: (value) => _newPassword = value!,
                      ),
                      // Xác nhận mật khẩu
                      TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Xác nhận mật khẩu'),
                        obscureText: true,
                        validator: (value) {
                          if (value != _newPassword) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      // Họ và tên
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Họ và tên'),
                        validator: Validators.validateName,
                        onSaved: (value) => _fullName = value!,
                      ),
                      // Số điện thoại
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Số điện thoại'),
                        validator: Validators.validateNumber,
                        onSaved: (value) => _phoneNumber = value!,
                      ),
                      SizedBox(height: 20),
                      // Nút xác nhận
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              _loading = true;
                              _error = '';
                            });
                            try {
                              await authProvider.changePassword(_newPassword);
                              // Lấy apartmentId từ người dùng hiện tại
                              String apartmentId =
                                  authProvider.user?.associatedApartment ?? '';

                              // Lưu thông tin cá nhân vào 'residents' collection
                              await FirebaseFirestore.instance
                                  .collection('residents')
                                  .doc(authProvider.user!.uid)
                                  .set({
                                'fullName': _fullName,
                                'phoneNumber': _phoneNumber,
                                'email': authProvider.user!.email,
                                'apartmentId': apartmentId,
                                'additionalInfo':
                                    {}, // Thêm các thông tin bổ sung nếu cần
                              });
                              // Cập nhật trạng thái người dùng
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(authProvider.user!.uid)
                                  .update({
                                'status': 'waiting_for_approval',
                              });
                              // Thông báo và điều hướng
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Đã cập nhật thông tin, vui lòng chờ xác nhận từ quản trị viên.')),
                              );
                              await authProvider.logout();
                              Navigator.pushReplacementNamed(context, '/');
                            } catch (e) {
                              setState(() {
                                _error = e.toString();
                                _loading = false;
                              });
                            }
                          }
                        },
                        child: Text('Xác Nhận'),
                      ),
                      SizedBox(height: 12),
                      // Hiển thị lỗi
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
