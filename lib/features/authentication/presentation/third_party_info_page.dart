import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'login_page.dart';
import 'package:intl/intl.dart'; // Thêm thư viện để định dạng ngày tháng
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThirdPartyInfoPage extends StatefulWidget {
  final AuthenticationService authService;
  final String email;
  final String password;

  ThirdPartyInfoPage({
    required this.authService,
    required this.email,
    required this.password,
  });

  @override
  _ThirdPartyInfoPageState createState() => _ThirdPartyInfoPageState();
}

class _ThirdPartyInfoPageState extends State<ThirdPartyInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  String selectedGender = 'Nam'; // Mặc định là 'Nam'
  DateTime? dob;
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();

  bool isLoading = false;
  String? message;

  // Hàm xử lý đăng ký và tạo tài liệu trong queue
  Future<void> submitInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (dob == null) {
      setState(() {
        message = 'Vui lòng chọn ngày sinh.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String fullName = fullNameController.text.trim();
    String gender = selectedGender;
    String dobFormatted = DateFormat('dd/MM/yyyy').format(dob!);
    String phone = phoneController.text.trim();
    String id = idController.text.trim();
    String jobTitle = jobTitleController.text.trim();

    try {
      // Đăng ký người dùng
      String? idToken =
          await widget.authService.signUp(widget.email, widget.password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Tạo dữ liệu để gửi lên queue
          Map<String, dynamic> queueData = {
            'fullName': fullName,
            'gender': gender,
            'dob': dobFormatted, // Định dạng: DD/MM/YYYY
            'phone': phone,
            'id': id,
            'uid': uid,
            'jobTitle': jobTitle,
            'email': widget.email,
            'role': 'Bên thứ 3',
            'status': 'Chờ duyệt',
          };

          // Tạo document trong collection 'queue'
          bool success =
              await widget.authService.createQueueDocument(idToken, queueData);

          if (success) {
            setState(() {
              message =
                  'Đăng ký thông tin thành công. Đang chờ admin phê duyệt.';
              isLoading = false;
            });
            // Chuyển hướng về trang đăng nhập sau khi thành công
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LoginPage(authService: widget.authService),
              ),
            );
          } else {
            setState(() {
              message = 'Đăng ký thông tin thất bại.';
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
      print('Lỗi khi đăng ký: $e');
    }
  }

  // Hàm chọn ngày sinh
  Future<void> selectDOB() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        dob = pickedDate;
        dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // Hàm logout
  Future<void> logout() async {
    // Thực hiện logout nếu cần (ví dụ: xóa token, dữ liệu cục bộ)
    // Sau đó chuyển hướng về trang đăng nhập
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Nhập Thông Tin Bên Thứ 3'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: logout,
              tooltip: 'Đăng xuất',
            )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Họ và Tên
                TextFormField(
                  controller: fullNameController,
                  decoration: InputDecoration(labelText: 'Họ và Tên'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Giới tính
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(labelText: 'Giới tính'),
                  items: <String>['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn giới tính.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Ngày sinh (GestureDetector với TextFormField)
                GestureDetector(
                  onTap: selectDOB,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: dobController,
                      decoration: InputDecoration(
                        labelText: 'Ngày tháng năm sinh (DD/MM/YYYY)',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (dob == null) {
                          return 'Vui lòng chọn ngày sinh.';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Số điện thoại
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại.';
                    }
                    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Số ID
                TextFormField(
                  controller: idController,
                  decoration:
                      InputDecoration(labelText: 'Số CCCD/CMND/Hộ chiếu'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số ID.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Chức vụ
                TextFormField(
                  controller: jobTitleController,
                  decoration: InputDecoration(labelText: 'Chức vụ'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập chức vụ.';
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
                        onPressed: submitInfo,
                        child: Text('Gửi Thông Tin'),
                      ),
              ],
            ),
          )),
        ));
  }
}
