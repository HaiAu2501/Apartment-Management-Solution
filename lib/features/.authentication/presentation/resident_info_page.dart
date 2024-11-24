import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'login_page.dart';
import 'package:intl/intl.dart'; // Thêm thư viện để định dạng ngày tháng
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

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  String selectedGender = 'Nam'; // Mặc định là 'Nam'
  DateTime? dob;
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController apartmentNumberController = TextEditingController();

  bool isLoading = false;
  String? message;

  // Hàm xử lý đăng ký và tạo tài liệu trong queue
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
    String password = widget.password; // Sử dụng mật khẩu người dùng nhập

    // Tạo dữ liệu để gửi lên queue
    Map<String, dynamic> queueData = {
      'fullName': fullName,
      'gender': gender,
      'dob': dobFormatted, // Định dạng: DD/MM/YYYY
      'phone': phone,
      'id': id,
      'floor': int.parse(floor),
      'apartmentNumber': int.parse(apartmentNumber),
      'email': widget.email,
      'password': password, // Thêm trường password
      'role': 'Cư dân',
      'status': 'Chờ duyệt',
      'requestId': Uuid().v4(), // Tạo requestId làm documentID
    };

    try {
      // Tạo document trong collection 'queue'
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 500;
        return Scaffold(
          body: Stack(
            children: [
              // Nền gradient toàn màn hình
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromRGBO(161, 214, 178, 1), Color.fromRGBO(241, 243, 194, 1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Thêm nhiều bong bóng nền hơn
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 250, // đường kính của bubble
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
                  width: 200, // đường kính của bubble
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
                  width: 150, // đường kính của bubble
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
                  width: 300, // đường kính của bubble
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
              // Nội dung chính
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: isMobile ? double.infinity : 600,
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bên trái: Form nhập thông tin cư dân
                                Expanded(
                                  flex: 1,
                                  child: buildRegisterForm(),
                                ),
                                const SizedBox(width: 32),
                                // Bên phải: Chào mừng
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
              // Hiển thị thông báo khi có lỗi hoặc thông tin
              if (message != null)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: message!.contains('thành công') ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        message!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // Hiển thị loading
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

  // Hàm xây dựng form đăng ký
  Widget buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          const Text(
            'THÔNG TIN CƯ DÂN',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 15),
          // Họ và Tên
          TextFormField(
            controller: fullNameController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              labelText: 'Họ và Tên',
              helperText: ' ', // Dự trữ không gian cho thông báo lỗi
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập họ và tên.';
              }
              return null;
            },
          ),
          const SizedBox(height: 5),
          // Ngày sinh (GestureDetector với TextFormField)
          GestureDetector(
            onTap: selectDOB,
            child: AbsorbPointer(
              child: TextFormField(
                controller: dobController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  labelText: 'Ngày tháng năm sinh (DD/MM/YYYY)',
                  helperText: ' ', // Dự trữ không gian cho thông báo lỗi
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
          const SizedBox(height: 5),
          // Giới tính và Số điện thoại trên cùng một hàng
          Row(
            children: [
              // Giới tính
              Expanded(
                flex: 45,
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.transgender),
                    labelText: 'Giới tính',
                    helperText: ' ', // Dự trữ không gian cho thông báo lỗi
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
              ),
              const SizedBox(width: 15), // Khoảng cách giữa hai ô
              // Số điện thoại
              Expanded(
                flex: 55,
                child: TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    labelText: 'Số điện thoại',
                    helperText: ' ', // Dự trữ không gian cho thông báo lỗi
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại.';
                    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) return 'Số điện thoại không hợp lệ.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Số ID
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.card_membership),
              labelText: 'Số CCCD/CMND/Hộ chiếu',
              helperText: ' ', // Dự trữ không gian cho thông báo lỗi
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số ID.';
              return null;
            },
          ),
          const SizedBox(height: 5),
          // Tầng và Số căn hộ trên cùng một hàng
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: floorController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.layers),
                    labelText: 'Tầng',
                    helperText: ' ', // Dự trữ không gian cho thông báo lỗi
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập tầng.';
                    if (int.tryParse(value) == null) return 'Tầng phải là số.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 15), // Khoảng cách giữa hai ô
              Expanded(
                child: TextFormField(
                  controller: apartmentNumberController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.home),
                    labelText: 'Số căn hộ',
                    helperText: ' ', // Dự trữ không gian cho thông báo lỗi
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số căn hộ.';
                    if (int.tryParse(value) == null) return 'Số căn hộ phải là số.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          // Thông báo
          if (message != null)
            Text(
              message!,
              style: TextStyle(color: message!.contains('thành công') ? Colors.green : Colors.red),
            ),
          const SizedBox(height: 5),
          // Nút Gửi Thông Tin với Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(8)),
            child: ElevatedButton(
              onPressed: submitInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // Nền trong suốt
                shadowColor: Colors.transparent, // Không bóng đổ
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Gửi Thông Tin',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Nút Quay lại Đăng Nhập với viền gradient và nền trắng
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Độ dày viền
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6) // Bán kính góc nhỏ hơn để tạo hiệu ứng viền
                    ),
                child: TextButton(
                  onPressed: logout, // Quay lại trang đăng nhập
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white, // Nền trắng
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
