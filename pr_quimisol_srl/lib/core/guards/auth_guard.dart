import 'package:flutter_modular/flutter_modular.dart';
import '../storage/auth_storage.dart';

/// Protege rutas privadas (ej: /home). Si NO hay sesión, redirige a /auth/login.
class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: '/auth/login');

  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    return await AuthStorage.isLoggedIn();
  }
}

/// Evita entrar a /auth/* si YA hay sesión; redirige a /home.
class LoggedInGuard extends RouteGuard {
  LoggedInGuard() : super(redirectTo: '/home');

  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    final ok = await AuthStorage.isLoggedIn();
    return !ok; // solo deja pasar si NO está logueado
  }
}
