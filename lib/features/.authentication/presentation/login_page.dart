import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'register_page.dart';
import '../../admin/presentation/home_page.dart';
import '../../resident/presentation/resident_home_page.dart';
import '../../guest/presentation/guest_home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final AuthenticationService authService;

  const LoginPage({super.key, required this.authService});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? message;
  bool _submitted = false; // Add this line

  // Hàm xử lý đăng nhập
  Future<void> handleLogin() async {
    setState(() {
      _submitted = true; // Update the submitted flag
    });

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
      Map<String, dynamic>? authData = await widget.authService.signIn(email, password);
      if (authData != null) {
        String idToken = authData['idToken'];
        String uid = authData['uid'];
        String email = authData['email'];

        String? role = await getUserRole(uid, idToken);

        if (role == null) {
          setState(() {
            message = 'Không tìm thấy vai trò của người dùng.';
            isLoading = false;
          });
          return;
        }

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHomePage(
                authService: widget.authService,
                idToken: idToken,
                uid: uid,
                email: email,
              ),
            ),
          );
        } else if (role == 'resident') {
          // Xử lý tương tự cho resident
        } else if (role == 'guest') {
          // Xử lý tương tự cho guest
        } else {
          setState(() {
            message = 'Vai trò người dùng không hợp lệ.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi đăng nhập: $e');
    }
  }

  // Hàm lấy vai trò của người dùng từ các collection
  Future<String?> getUserRole(String uid, String idToken) async {
    // Kiểm tra trong collection 'admin'
    String adminUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/admin/$uid?key=${widget.authService.apiKey}';
    try {
      final adminResponse = await http.get(
        Uri.parse(adminUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      print('adminResponse: ${adminResponse.statusCode}');

      if (adminResponse.statusCode == 200) {
        return 'admin';
      }

      // Kiểm tra trong collection 'residents'
      String residentsUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/residents/$uid?key=${widget.authService.apiKey}';
      final residentsResponse = await http.get(
        Uri.parse(residentsUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (residentsResponse.statusCode == 200) {
        return 'resident';
      }

      // Kiểm tra trong collection 'guests'
      String guestsUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/guests/$uid?key=${widget.authService.apiKey}';
      final guestsResponse = await http.get(
        Uri.parse(guestsUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (guestsResponse.statusCode == 200) {
        return 'guest';
      }

      // Nếu không tìm thấy trong bất kỳ collection nào
      return null;
    } catch (e) {
      print('Lỗi khi kiểm tra vai trò người dùng: $e');
      return null;
    }
  }

  // Hàm lấy trạng thái của người dùng từ collection cụ thể
  Future<String?> getUserStatus(String collection, String uid, String idToken) async {
    String url = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/$collection/$uid?key=${widget.authService.apiKey}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fields']['status']['stringValue'];
      } else {
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy trạng thái người dùng: $e');
      return null;
    }
  }

  // Hàm chuyển hướng đến trang đăng ký
  void navigateToRegister() {
    setState(() {
      message = null;
      _submitted = false; // Reset the submitted flag
      _formKey.currentState?.reset();
      emailController.clear();
      passwordController.clear();
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(authService: widget.authService),
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
              // ... (Các widget Positioned khác không thay đổi)
              // Nội dung chính
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: isMobile ? double.infinity : 600,
                    width: isMobile ? double.infinity : 800, // Độ rộng tùy theo thiết bị
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
                        ? buildLoginForm()
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bên trái: Form đăng nhập
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    // Thêm Center để căn giữa theo chiều dọc
                                    child: buildLoginForm(),
                                  ),
                                  /*
                                Hoặc sử dụng Column:
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    buildLoginForm(),
                                  ],
                                ),
                                */
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
                                      alignment: Alignment.center, // Căn lề trái
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Chào mừng',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'đến với ứng dụng!',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
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
                      decoration: BoxDecoration(
                        color: message!.contains('thành công') ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Hàm xây dựng form đăng nhập
  Widget buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ĐĂNG NHẬP',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: emailController,
            autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: 'Email',
              helperText: ' ', // Dự trữ không gian cho thông báo lỗi
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: passwordController,
            autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: 'Mật khẩu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Xử lý khi nhấn Quên mật khẩu (không có xử lý gì)
              },
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: Color.fromARGB(255, 119, 198, 122),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Nút Đăng Nhập với Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // Nền trong suốt
                shadowColor: Colors.transparent, // Không bóng đổ
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // Chữ màu trắng
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Nút Đăng Ký với viền gradient và nền trắng
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Độ dày viền
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Nền trắng
                  borderRadius: BorderRadius.circular(6), // Bán kính góc nhỏ hơn để tạo hiệu ứng viền
                ),
                child: TextButton(
                  onPressed: navigateToRegister,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white, // Nền trắng
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Đăng Ký',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green, // Chữ màu xanh lá
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
