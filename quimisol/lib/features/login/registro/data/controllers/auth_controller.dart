import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repo;
  bool loading = false;
  String? error;

  AuthController(this.repo);

  Future<bool> login(String email, String password) async {
    loading = true; error = null; notifyListeners();
    try {
      final ok = await repo.login(email, password);
      return ok;
    } catch (_) {
      error = 'Login failed';
      return false;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> body) async {
    loading = true; error = null; notifyListeners();
    try {
      final ok = await repo.register(body);
      return ok;
    } catch (_) {
      error = 'Register failed';
      return false;
    } finally {
      loading = false; notifyListeners();
    }
  }
}
