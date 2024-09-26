import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'package:animations/animations.dart';
import 'resident_info_page.dart';
import 'guest_info_page.dart';
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
  bool isLoginMode = true;

  // Login form controllers and key
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  // Register form controllers and key
  final _registerFormKey = GlobalKey<FormState>();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController = TextEditingController();
  String selectedRole = 'resident';

  bool isLoading = false;
  String? message;

  // Method to toggle between login and register modes
  void toggleLoginMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      message = null; // Clear any messages when switching modes
    });
  }

  // Handle login
  Future<void> handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String email = loginEmailController.text.trim();
    String password = loginPasswordController.text.trim();

    try {
      // Sign in the user
      String? idToken = await widget.authService.signIn(email, password);
      if (idToken != null) {
        // Get the user's UID
        String? uid = await widget.authService.getUserUid(idToken);
        if (uid != null) {
          // Determine the user's role
          String? role = await getUserRole(uid, idToken);

          if (role == null) {
            setState(() {
              message = 'Không tìm thấy vai trò của người dùng.';
              isLoading = false;
            });
            return;
          }

          // Navigate based on role and status
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
            // Check approval status
            String? status = await getUserStatus('residents', uid, idToken);
            if (status == 'Chờ duyệt') {
              setState(() {
                message = 'Tài khoản của bạn đang trong trạng thái "Chờ duyệt". Vui lòng đợi admin phê duyệt.';
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
          } else if (role == 'guest') {
            // Check approval status
            String? status = await getUserStatus('guests', uid, idToken);
            if (status == 'Chờ duyệt') {
              setState(() {
                message = 'Tài khoản của bạn đang trong trạng thái "Chờ duyệt". Vui lòng đợi admin phê duyệt.';
                isLoading = false;
              });
            } else if (status == 'Đã duyệt') {
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

  // Handle registration navigation
  Future<void> navigateToInfoPage() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    String email = registerEmailController.text.trim();
    String password = registerPasswordController.text.trim();

    try {
      // Navigate to the appropriate info page without creating an account
      if (selectedRole == 'resident') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResidentInfoPage(
              authService: widget.authService,
              email: email,
              password: password,
            ),
          ),
        );
      } else if (selectedRole == 'guest') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GuestInfoPage(
              authService: widget.authService,
              email: email,
              password: password,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi: $e';
        isLoading = false;
      });
      print('Lỗi khi chuyển hướng: $e');
    }
  }

  // Function to get user role
  Future<String?> getUserRole(String uid, String idToken) async {
    // Check in 'admin' collection
    String adminUrl = 'https://firestore.googleapis.com/v1/projects/${widget.authService.projectId}/databases/(default)/documents/admin/$uid?key=${widget.authService.apiKey}';
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

      // Check in 'residents' collection
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

      // Check in 'guests' collection
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

      // Not found in any collection
      return null;
    } catch (e) {
      print('Lỗi khi kiểm tra vai trò người dùng: $e');
      return null;
    }
  }

  // Function to get user status
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

  // Build method with transitions
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 500;
        return Scaffold(
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromRGBO(161, 214, 178, 1), Color.fromRGBO(241, 243, 194, 1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Background bubbles (same as your original code)
              // ... (Include the background widgets from your original code)

              // Multiple background bubbles
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
              // Main content
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
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: isMobile ? buildMobileContent() : buildDesktopContent(),
                  ),
                ),
              ),

              // Display message when there is an error or information
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

              // Display loading indicator
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

  Widget buildMobileContent() {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 500),
      reverse: !isLoginMode,
      transitionBuilder: (
        Widget child,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
      child: isLoginMode ? buildLoginForm() : buildRegisterForm(),
    );
  }

  Widget buildDesktopContent() {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 500),
      reverse: !isLoginMode,
      transitionBuilder: (
        Widget child,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
      child: isLoginMode ? buildLoginContent() : buildRegisterContent(),
    );
  }

  Widget buildLoginContent() {
    return IntrinsicHeight(
      key: const ValueKey('loginContent'),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: buildLoginForm(),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: buildLoginSideMessage(),
          ),
        ],
      ),
    );
  }

  Widget buildRegisterContent() {
    return IntrinsicHeight(
      key: const ValueKey('registerContent'),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: buildRegisterForm(),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: buildRegisterSideMessage(),
          ),
        ],
      ),
    );
  }

  // Login Form
  Widget buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('loginForm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 71),
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
            controller: loginEmailController,
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
            controller: loginPasswordController,
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
                // Handle forgot password
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
          // Login Button with Gradient
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
                backgroundColor: Colors.transparent, // Transparent background
                shadowColor: Colors.transparent, // No shadow
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // White text
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Register Button with gradient border and white background
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Border thickness
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.circular(6), // Slightly smaller radius to create border effect
                ),
                child: TextButton(
                  onPressed: toggleLoginMode,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text(
                    'Đăng Ký',
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 71),
        ],
      ),
    );
  }

  // Register Form
  Widget buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('registerForm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 50),
          const Text(
            'ĐĂNG KÝ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: registerEmailController,
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
            controller: registerPasswordController,
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
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              labelText: 'Vai trò',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: <String>['resident', 'guest'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value == 'resident' ? 'Cư Dân' : 'Khách'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedRole = newValue!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng chọn vai trò.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Register Button with Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: navigateToInfoPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // Transparent background
                shadowColor: Colors.transparent, // No shadow
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // White text
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Back to Login Button with gradient border and white background
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 119, 198, 122), Color.fromARGB(255, 252, 242, 150)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Border thickness
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.circular(6), // Slightly smaller radius to create border effect
                ),
                child: TextButton(
                  onPressed: toggleLoginMode,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green, // Green text
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

  // Login Side Message
  Widget buildLoginSideMessage() {
    return Container(
      key: const ValueKey('loginMessage'),
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
        alignment: Alignment.center, // Align left
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
    );
  }

  // Register Side Message
  Widget buildRegisterSideMessage() {
    return Container(
      key: const ValueKey('registerMessage'),
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
        alignment: Alignment.center, // Align left
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vui lòng',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'nhập thông tin đăng ký!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
