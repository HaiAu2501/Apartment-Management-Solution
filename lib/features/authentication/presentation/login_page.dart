import 'package:flutter/material.dart';
import '../data/authentication_service.dart';
import 'register_page.dart';
import '../../admin/presentation/admin_home_page.dart';
import '../../resident/presentation/resident_home_page.dart';
import '../../third_party/presentation/third_party_home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final AuthenticationService authService;

  LoginPage({required this.authService});

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Nhập'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: OutlineInputBorder(),
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
                        SizedBox(height: 20),
                        // Thông báo lỗi hoặc thành công
                        if (message != null)
                          Text(
                            message!,
                            style: TextStyle(
                              color: message!.contains('thành công')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        SizedBox(height: 20),
                        // Nút Đăng Nhập
                        ElevatedButton(
                          onPressed: handleLogin,
                          child: Text('Đăng Nhập'),
                        ),
                        SizedBox(height: 10),
                        // Nút Đăng Ký
                        TextButton(
                          onPressed: navigateToRegister,
                          child: Text('Chưa có tài khoản? Đăng ký ngay!'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
