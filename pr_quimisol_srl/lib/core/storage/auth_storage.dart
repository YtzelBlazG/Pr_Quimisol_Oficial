import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _kLoggedIn = 'logged_in';
  static const _kNombre   = 'user_nombre';
  static const _kCorreo   = 'user_correo';

  /// 🔔 Notificador global del estado de sesión
  static final ValueNotifier<bool> loginStatus = ValueNotifier<bool>(false);

  /// Llama esto al inicio de la app (o desde HomePage.initState una vez)
  static Future<void> init() async {
    loginStatus.value = await isLoggedIn();
  }

  static Future<void> saveUser({
    required String nombre,
    required String correo,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, true);
    await p.setString(_kNombre, nombre);
    await p.setString(_kCorreo, correo);
    loginStatus.value = true; // 🔔 avisa a la UI
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kNombre);
    await p.remove(_kCorreo);
    loginStatus.value = false; // 🔔 avisa a la UI
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<String?> getNombre() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kNombre);
  }

  static Future<String?> getCorreo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kCorreo);
  }
}
