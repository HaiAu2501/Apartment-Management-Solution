// lib/.authentication/presentation/login_page.dart

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

  // Hàm xử lý đăng nhập
  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    print('Bắt đầu quá trình đăng nhập với Email: $email');

    try {
      Map<String, dynamic>? authData = await widget.authService.signIn(email, password);
      print('Dữ liệu xác thực nhận được: $authData');

      if (authData != null) {
        // Kiểm tra nếu 'uid' không tồn tại hoặc null
        if (!authData.containsKey('uid') || authData['uid'] == null) {
          setState(() {
            message = 'UID người dùng không được tìm thấy.';
            isLoading = false;
          });
          print('UID người dùng là null hoặc không tồn tại.');
          return;
        }

        String idToken = authData['idToken'] ?? '';
        String uid = authData['uid'] ?? '';
        String email = authData['email'] ?? '';

        print('Đăng nhập thành công. UID: $uid, Email: $email');

        // Kiểm tra nếu 'uid' vẫn trống
        if (uid.isEmpty) {
          setState(() {
            message = 'UID người dùng trống.';
            isLoading = false;
          });
          print('UID người dùng trống.');
          return;
        }

        // Gọi getUserRole với uid
        String? role = await getUserRole(uid, idToken);
        print('Vai trò của người dùng: $role');

        if (role == null) {
          setState(() {
            message = 'Không tìm thấy vai trò của người dùng.';
            isLoading = false;
          });
          print('Không tìm thấy vai trò của người dùng.');
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
          // Truyền uid trực tiếp thay vì profileId
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResidentHomePage(
                authService: widget.authService,
                idToken: idToken,
                uid: uid, // Truyền uid thay vì profileId
              ),
            ),
          );
        } else if (role == 'guest') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GuestHomePage(
                authService: widget.authService,
                idToken: idToken,
                uid: uid,
              ),
            ),
          );
        } else {
          setState(() {
            message = 'Vai trò người dùng không hợp lệ.';
            isLoading = false;
          });
          print('Vai trò người dùng không hợp lệ.');
        }
      } else {
        setState(() {
          message = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập.';
          isLoading = false;
        });
        print('Dữ liệu xác thực là null.');
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi đăng nhập: $e');
    }
  }

  /// Hàm kiểm tra xem người dùng có phải là admin dựa trên uid không
  Future<bool> isAdmin(String uid, String idToken) async {
    String adminUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/admin/$uid?key=${widget.authService.apiKey}';
    try {
      print('Gửi yêu cầu kiểm tra admin với UID: $uid');
      final response = await http.get(
        Uri.parse(adminUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      print('Phản hồi từ Firestore (isAdmin): ${response.statusCode}');
      print('Phản hồi body (isAdmin): ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error in isAdmin: $e');
      return false;
    }
  }

  /// Hàm lấy vai trò của người dùng từ các collection
  Future<String?> getUserRole(String uid, String idToken) async {
    try {
      // Kiểm tra xem người dùng có phải là admin không dựa trên uid
      final isAdminResult = await isAdmin(uid, idToken);
      print('Kết quả isAdmin: $isAdminResult');
      if (isAdminResult) return 'admin';

      // Kiểm tra trong collection 'residents'
      String residentsUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/residents/$uid?key=${widget.authService.apiKey}';
      final residentsResponse = await http.get(
        Uri.parse(residentsUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      print('residentsResponse status: ${residentsResponse.statusCode}');
      print('residentsResponse body: ${residentsResponse.body}');

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
      print('guestsResponse status: ${guestsResponse.statusCode}');
      print('guestsResponse body: ${guestsResponse.body}');

      if (guestsResponse.statusCode == 200) {
        return 'guest';
      }

      // Nếu không tìm thấy trong bất kỳ collection nào
      return null;
    } catch (e) {
      print('Error in getUserRole: $e');
      return null;
    }
  }

  // Hàm chuyển hướng đến trang đăng ký
  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
                            children: [
                              // Bên trái: Form đăng nhập
                              Expanded(
                                flex: 1,
                                child: buildLoginForm(),
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
    });
  }

  // Hàm xây dựng form đăng nhập
  Widget buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 50),
          const Text(
            'ĐĂNG NHẬP',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            onFieldSubmitted: (_) => handleLogin(),
            controller: emailController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: 'Email',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
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
            onFieldSubmitted: (_) => handleLogin(),
          ),
          const SizedBox(height: 5),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
