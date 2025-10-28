import 'package:flutter/material.dart';

class Validators {
  static final _emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernameReg = RegExp(r'^[a-zA-Z0-9._-]{3,}$');
  static final _passwordReg = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  // === LOGIN ===
  static String? usernameOrEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingrese su usuario o correo';
    if (v.contains('@')) {
      if (!_emailReg.hasMatch(v)) return 'Ingrese un correo válido';
      return null;
    }
    if (!_usernameReg.hasMatch(v)) {
      return 'Usuario inválido (mín. 3, letras/números/._-)';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingrese su contraseña';
    if (!_passwordReg.hasMatch(v)) {
      return 'Mín. 8 car., al menos 1 letra y 1 número';
    }
    return null;
  }

  static String? confirmPassword(String? pass, String? confirm) {
    final p = pass ?? '';
    final c = confirm ?? '';
    if (c.isEmpty) return 'Confirme su contraseña';
    if (p != c) return 'Las contraseñas no coinciden';
    return null;
  }

  // === REGISTRO (nuevo) ===
  static final _nameReg = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]{2,}$");
  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingrese su nombre';
    if (!_nameReg.hasMatch(v)) return 'Nombre inválido (solo letras, 2+ caracteres)';
    return null;
  }

  static String? lastName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingrese su apellido';
    if (!_nameReg.hasMatch(v)) return 'Apellido inválido (solo letras, 2+ caracteres)';
    return null;
  }

  /// Teléfono local/intl sin símbolos: 7–15 dígitos
  static final _phoneReg = RegExp(r'^\d{7,15}$');
  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(' ', '');
    if (v.isEmpty) return 'Ingrese su teléfono';
    if (!_phoneReg.hasMatch(v)) return 'Teléfono inválido (7 a 15 dígitos)';
    return null;
  }

  // Helper Snack
  static void showSnack(BuildContext ctx, String msg, {bool success = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green[600] : Colors.red[600],
      ),
    );
  }
}
