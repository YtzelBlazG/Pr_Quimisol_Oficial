import '../sources/auth_api.dart';

class AuthRepository {
  final AuthApi api;
  AuthRepository(this.api);

  Future<bool> login(String email, String password) async {
    final data = await api.login(email, password);
    return data['ok'] == true;
  }

  Future<bool> register(Map<String, dynamic> body) async {
    final data = await api.register(body);
    return data['ok'] == true;
  }
}
