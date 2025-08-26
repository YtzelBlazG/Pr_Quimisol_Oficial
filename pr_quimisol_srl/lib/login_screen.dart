import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'dashboard_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  // URL de tu servidor Node
  static const String apiUrl = "http://localhost:3000";

  Future<String?> _authUser(LoginData data) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": data.name,
          "contrasena": data.password,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["success"]) {
          return null; // login correcto
        } else {
          return json["message"];
        }
      } else {
        return "Error en el servidor (${response.statusCode})";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": data.name,
          "contrasena": data.password,
          "rol": "usuario",
          "estado": "activo",
        }),
      );

      if (response.statusCode == 200) {
        return null; // registro correcto
      } else {
        return "Error en el servidor (${response.statusCode})";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  Future<String?> _recoverPassword(String name) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl/usuarios"));
      if (response.statusCode == 200) {
        final usuarios = jsonDecode(response.body) as List;
        final existe = usuarios.any((u) => u["correo"] == name);
        if (existe) {
          return null;
        } else {
          return "Usuario no existe";
        }
      } else {
        return "Error en el servidor";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFfce8f1), // Rosa Pastel
            Color(0xFFfdf1f8), // Rosa Floral
            Color(0xFFbfa8bf), // Lavanda Empolvada
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FlutterLogin(
        title: 'EMBOTELLADOS',
        logo: const AssetImage('assets/images/logos.png'),
        onLogin: _authUser,
        onSignup: _signupUser,
        onRecoverPassword: _recoverPassword,
        theme: LoginTheme(
          primaryColor: const Color(0xFFd6a3c4), // Malva Elegante
          accentColor: const Color(0xFFa86aa6), // Orquídea Claro
          errorColor: const Color(0xFF6e4e6e), // Ciruela Suave
          pageColorLight: Colors.transparent,
          pageColorDark: Colors.transparent,

          cardTheme: CardTheme(
            color: Colors.white.withOpacity(0.7), // Glass effect
            elevation: 15,
            margin: const EdgeInsets.only(top: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),

          textFieldStyle: const TextStyle(
            color: Color(0xFF444444), // Gris encaje
            fontWeight: FontWeight.w500,
          ),

          buttonTheme: LoginButtonTheme(
            backgroundColor: const Color(0xFFb87aa5), // Violeta Romántico
            highlightColor: const Color(0xFFd6a3c4),
            splashColor: const Color(0xFFa86aa6),
            elevation: 6.0,
            highlightElevation: 10.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35.0),
            ),
          ),

          titleStyle: const TextStyle(
            color: Color(0xFF6e4e6e),
            fontFamily: 'Quicksand',
            fontSize: 42,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black26,
                offset: Offset(2, 2),
              )
            ],
          ),

          bodyStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF444444),
          ),
        ),
        loginProviders: <LoginProvider>[
          LoginProvider(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            callback: () async {
              await Future.delayed(loginTime);
              return null;
            },
          ),
          LoginProvider(
            icon: FontAwesomeIcons.facebookF,
            label: 'Facebook',
            callback: () async {
              await Future.delayed(loginTime);
              return null;
            },
          ),
          LoginProvider(
            icon: FontAwesomeIcons.instagram,

            label: 'Instagram ',
            callback: () async {
              await Future.delayed(loginTime);
              return null;
            },
          ),
        ],
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ));
        },
      ),
    );
  }
}
