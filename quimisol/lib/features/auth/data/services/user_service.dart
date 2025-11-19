import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://192.168.213.85:3005";

  Future<Map<String, dynamic>> login(String correo, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "contrasena": password}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error en login: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> register(
    String nombre,
    String correo,
    String password,
    String telefono,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "correo": correo,
        "contrasena": password,
        "telefono": telefono,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error en registro: ${res.body}");
    }
  }
}
