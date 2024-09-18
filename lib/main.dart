import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/pages/register_page.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyBtspfJdmslGCkv5MvWu9gkMYuLNwvfzKU",
        authDomain: "apartment-management-solution.firebaseapp.com",
        projectId: "apartment-management-solution",
        storageBucket: "apartment-management-solution.appspot.com",
        messagingSenderId: "796863478810",
        appId: "1:796863478810:web:4975e734b45c28e6d525a3",
        measurementId: "G-EQ7XZE6HZ1"),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng Dụng Quản Lý',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        // Thêm các route khác nếu cần
      },
    );
  }
}
