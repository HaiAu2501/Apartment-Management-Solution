import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'register_page.dart';
import '../../admin/home/home_page.dart';
import '../../resident/presentation/resident_home_page.dart';
import '../../third_party/presentation/third_party_home_page.dart';
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

    try {
      // Đăng nhập người dùng
      String? idToken = await widget.authService.signIn(email, password);
      if (idToken != null) {
        // Lấy UID của người dùng
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Kiểm tra vai trò của người dùng trong các collection: admin, residents, thirdParties
          String? role = await getUserRole(uid, idToken);

          if (role == null) {
            setState(() {
              message = 'Không tìm thấy vai trò của người dùng.';
              isLoading = false;
            });
            return;
          }

          // Điều hướng dựa trên vai trò và trạng thái
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHomePage(
                  authService: widget.authService,
                  idToken: idToken,
                  uid: uid,
                ),
              ),
            );
          } else if (role == 'resident') {
            // Kiểm tra trạng thái phê duyệt
            String? status = await getUserStatus('residents', uid, idToken);
            if (status == 'Chờ duyệt') {
              setState(() {
                message =
                    'Tài khoản của bạn đang trong trạng thái "Chờ duyệt". Vui lòng đợi admin phê duyệt.';
                isLoading = false;
              });
            } else if (status == 'Đã duyệt') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResidentHomePage(
                    authService: widget.authService,
                    idToken: idToken,
                    uid: uid,
                  ),
                ),
              );
            } else {
              setState(() {
                message = 'Trạng thái tài khoản không hợp lệ.';
                isLoading = false;
              });
            }
          } else if (role == 'thirdParty') {
            // Kiểm tra trạng thái phê duyệt
            String? status = await getUserStatus('thirdParties', uid, idToken);
            if (status == 'Chờ duyệt') {
              setState(() {
                message =
                    'Tài khoản của bạn đang trong trạng thái "Chờ duyệt". Vui lòng đợi admin phê duyệt.';
                isLoading = false;
              });
            } else if (status == 'Đã duyệt') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ThirdPartyHomePage(
                    authService: widget.authService,
                    idToken: idToken,
                    uid: uid,
                  ),
                ),
              );
            } else {
              setState(() {
                message = 'Trạng thái tài khoản không hợp lệ.';
                isLoading = false;
              });
            }
          } else {
            setState(() {
              message = 'Vai trò người dùng không hợp lệ.';
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
          message =
              'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin đăng nhập.';
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
    String adminUrl =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/admin/$uid?key=${widget.authService.apiKey}';
    try {
      final adminResponse = await http.get(
        Uri.parse(adminUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (adminResponse.statusCode == 200) {
        return 'admin';
      }

      // Kiểm tra trong collection 'residents'
      String residentsUrl =
          'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/residents/$uid?key=${widget.authService.apiKey}';
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

      // Kiểm tra trong collection 'thirdParties'
      String thirdPartiesUrl =
          'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/thirdParties/$uid?key=${widget.authService.apiKey}';
      final thirdPartiesResponse = await http.get(
        Uri.parse(thirdPartiesUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (thirdPartiesResponse.statusCode == 200) {
        return 'thirdParty';
      }

      // Nếu không tìm thấy trong bất kỳ collection nào
      return null;
    } catch (e) {
      print('Lỗi khi kiểm tra vai trò người dùng: $e');
      return null;
    }
  }

  // Hàm lấy trạng thái của người dùng từ collection cụ thể
  Future<String?> getUserStatus(
      String collection, String uid, String idToken) async {
    String url =
        'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/$collection/$uid?key=${widget.authService.apiKey}';
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
                    colors: [
                      Color.fromRGBO(161, 214, 178, 1),
                      Color.fromRGBO(241, 243, 194, 1)
                    ],
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
                      colors: [
                        Color.fromRGBO(161, 214, 178, 0.25),
                        Color.fromRGBO(241, 243, 194, 0.75)
                      ],
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
                      colors: [
                        Color.fromRGBO(161, 214, 178, 1),
                        Color.fromRGBO(241, 243, 194, 1)
                      ],
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
                      colors: [
                        Color.fromRGBO(161, 214, 178, 0.75),
                        Color.fromRGBO(241, 243, 194, 0.25)
                      ],
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
                      colors: [
                        Color.fromRGBO(161, 214, 178, 0.75),
                        Color.fromRGBO(241, 243, 194, 0.25)
                      ],
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
                    width: isMobile
                        ? double.infinity
                        : 800, // Độ rộng tùy theo thiết bị
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
                                        colors: [
                                          Color.fromARGB(255, 119, 198, 122),
                                          Color.fromARGB(255, 252, 242, 150)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Align(
                                      alignment:
                                          Alignment.center, // Căn lề trái
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: message!.contains('thành công')
                            ? Colors.green
                            : Colors.red,
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
                colors: [
                  Color.fromARGB(255, 119, 198, 122),
                  Color.fromARGB(255, 252, 242, 150)
                ],
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
                colors: [
                  Color.fromARGB(255, 119, 198, 122),
                  Color.fromARGB(255, 252, 242, 150)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Độ dày viền
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Nền trắng
                  borderRadius: BorderRadius.circular(
                      6), // Bán kính góc nhỏ hơn để tạo hiệu ứng viền
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
