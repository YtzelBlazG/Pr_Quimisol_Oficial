import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_model.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  // 🔹 Obtener usuario por ID
  Future<UserModel?> getUser(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/usuarios/$id'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    }
    return null;
  }

  // 🔹 Actualizar usuario por ID
  Future<UserModel?> updateUser(int id, {required String correo}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception("Error updating user: ${res.body}");
    }
  }

  // 🔹 Actualizar correo usando idPersona
  Future<UserModel?> updateUserByPersona(int idPersona, {required String correo}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/usuarios/by-persona/$idPersona'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception("Error updating user by persona: ${res.body}");
    }
  }
}
