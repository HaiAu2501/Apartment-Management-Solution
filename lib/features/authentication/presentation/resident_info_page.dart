import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'login_page.dart';
import 'package:intl/intl.dart'; // Thêm thư viện để định dạng ngày tháng
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResidentInfoPage extends StatefulWidget {
  final AuthenticationService authService;
  final String email;
  final String password;

  const ResidentInfoPage({
    super.key,
    required this.authService,
    required this.email,
    required this.password,
  });

  @override
  _ResidentInfoPageState createState() => _ResidentInfoPageState();
}

class _ResidentInfoPageState extends State<ResidentInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  String selectedGender = 'Nam'; // Mặc định là 'Nam'
  DateTime? dob;
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController apartmentNumberController =
      TextEditingController();

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
    String floor = floorController.text.trim();
    String apartmentNumber = apartmentNumberController.text.trim();

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
            'floor': int.parse(floor),
            'apartmentNumber': int.parse(apartmentNumber),
            'email': widget.email,
            'role': 'Cư dân',
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
          title: const Text('Nhập Thông Tin Cư Dân'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: logout,
              tooltip: 'Đăng xuất',
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Họ và Tên
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và Tên'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Giới tính
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
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
                const SizedBox(height: 10),
                // Ngày sinh (GestureDetector với TextFormField)
                GestureDetector(
                  onTap: selectDOB,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: dobController,
                      decoration: const InputDecoration(
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
                const SizedBox(height: 10),
                // Số điện thoại
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
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
                const SizedBox(height: 10),
                // Số ID
                TextFormField(
                  controller: idController,
                  decoration:
                      const InputDecoration(labelText: 'Số CCCD/CMND/Hộ chiếu'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số ID.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Tầng
                TextFormField(
                  controller: floorController,
                  decoration: const InputDecoration(labelText: 'Tầng'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tầng.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Tầng phải là số.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Số căn hộ
                TextFormField(
                  controller: apartmentNumberController,
                  decoration: const InputDecoration(labelText: 'Số căn hộ'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số căn hộ.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Số căn hộ phải là số.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Thông báo
                if (message != null)
                  Text(
                    message!,
                    style: TextStyle(
                        color: message!.contains('thành công')
                            ? Colors.green
                            : Colors.red),
                  ),
                const SizedBox(height: 20),
                // Nút Submit
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitInfo,
                        child: const Text('Gửi Thông Tin'),
                      ),
              ],
            ),
          )),
        ));
  }
}