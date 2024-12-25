import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

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
  final TextEditingController fullNameController = TextEditingController();
  String selectedGender = 'Nam';
  DateTime? dob;
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController apartmentNumberController = TextEditingController();
  bool isLoading = false;
  String? message;

  Future<void> submitInfo() async {
    if (!_formKey.currentState!.validate()) return;

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
    String password = widget.password;

    Map<String, dynamic> queueData = {
      'fullName': fullName,
      'gender': gender,
      'dob': dobFormatted,
      'phone': phone,
      'id': id,
      'floor': int.parse(floor),
      'apartmentNumber': int.parse(apartmentNumber),
      'email': widget.email,
      'password': password,
      'role': 'Cư dân',
      'status': 'Chờ duyệt',
      'requestId': Uuid().v4(),
    };

    try {
      bool success = await widget.authService.createQueueDocument(queueData);

      if (success) {
        setState(() {
          message = 'Đăng ký thông tin thành công. Đang chờ admin phê duyệt.';
          isLoading = false;
        });
      } else {
        setState(() {
          message = 'Đăng ký thông tin thất bại.';
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

  Future<void> logout() async {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(authService: widget.authService)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 500;
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromRGBO(161, 214, 178, 1), Color.fromRGBO(241, 243, 194, 1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(161, 214, 178, 0.25), Color.fromRGBO(241, 243, 194, 0.75)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(161, 214, 178, 1), Color.fromRGBO(241, 243, 194, 1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                right: 50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(161, 214, 178, 0.75), Color.fromRGBO(241, 243, 194, 0.25)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                right: 500,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(161, 214, 178, 0.75), Color.fromRGBO(241, 243, 194, 0.25)],
                      begin: Alignment.topCenter,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: isMobile ? double.infinity : 800,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? buildRegisterForm()
                        : IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: buildRegisterForm(),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Align(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Quý cư dân',
                                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            'vui lòng nhập thông tin!',
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              if (message != null)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: message!.contains('thành công') ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: Text(message!, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'THÔNG TIN CƯ DÂN',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: fullNameController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              labelText: 'Họ và Tên',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập họ và tên.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.transgender),
              labelText: 'Giới tính',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: <String>['Nam', 'Nữ', 'Khác'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
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
          const SizedBox(height: 16),
          GestureDetector(
            onTap: selectDOB,
            child: AbsorbPointer(
              child: TextFormField(
                controller: dobController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  labelText: 'Ngày tháng năm sinh (DD/MM/YYYY)',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone),
              labelText: 'Số điện thoại',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại.';
              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) return 'Số điện thoại không hợp lệ.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.card_membership),
              labelText: 'Số CCCD/CMND/Hộ chiếu',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số ID.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: floorController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.layers),
              labelText: 'Tầng',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập tầng.';
              final floor = int.tryParse(value);
              if (floor == null || floor < 1 || floor > 10) {
                return 'Tầng phải là số từ 1 đến 10.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: apartmentNumberController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.home),
              labelText: 'Số căn hộ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số căn hộ.';
              final apartment = int.tryParse(value);
              if (apartment == null || apartment < 1 || apartment > 20) {
                return 'Số căn hộ phải là số từ 1 đến 20.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (message != null)
            Text(
              message!,
              style: TextStyle(color: message!.contains('thành công') ? Colors.green : Colors.red),
            ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)]), borderRadius: BorderRadius.circular(8)),
            child: ElevatedButton(
              onPressed: submitInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Gửi Thông Tin',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: TextButton(
                  onPressed: logout,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Quay lại Đăng Nhập', style: TextStyle(fontSize: 18, color: Colors.green)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
