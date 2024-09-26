import 'package:flutter/material.dart';
import 'features/.authentication/data/auth_service.dart';
import 'features/.authentication/presentation/login_page.dart';

void main() {
  runApp(const MyApp());
}

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // Skip transition for the initial route
    if (route.isFirst) {
      return child;
    }

    const curve = Curves.easeInOut;

    // Determine if it's a push or a pop based on the animation status
    bool isPush = animation.status == AnimationStatus.forward;

    // Define the tween based on push or pop
    final tween = Tween<Offset>(
      begin: isPush ? const Offset(0.0, 1.0) : const Offset(0.0, -1.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: curve));

    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  final String apiKey = 'YOUR_API_KEY';
  final String projectId = 'YOUR_PROJECT_ID';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthenticationService(apiKey: apiKey, projectId: projectId);

    return MaterialApp(
      title: 'Quản Lý Chung Cư',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
            TargetPlatform.windows: CustomPageTransitionBuilder(),
            TargetPlatform.macOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      home: LoginPage(authService: authService),
    );
  }
}
