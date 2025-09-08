import 'package:flutter/material.dart';
import '/features/auth/presentation/screens/login_screen.dart';

class AppRouter {
  static const String initialRoute = '/login';

  static Map<String, WidgetBuilder> get routes => {
        '/login': (_) => const LoginPage(),
      };
}
