// lib/core/services/mail_recovery_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quimisol/core/config/env.dart';

/// Servicio HTTP para la recuperación por correo.
/// Usa Env.apiBaseUrl (configúralo con --dart-define=API_BASE_URL=...).
class MailRecoveryService {
  MailRecoveryService({
    String? baseUrl,
    Duration? timeout,
  })  : _baseUrl = (baseUrl ?? Env.apiBaseUrl).replaceAll(RegExp(r'/$'), ''),
        _timeout = timeout ?? const Duration(seconds: 20);

  final String _baseUrl;
  final Duration _timeout;

  /// POST /mail/send-code  { email }
  Future<void> sendCode(String email) async {
    final r = await _post('$_baseUrl/mail/send-code', body: {'email': email});
    _ensureOk(r, fallback: 'No se pudo enviar el código');
  }

  /// POST /mail/resend-code  { email }
  Future<void> resendCode(String email) async {
    final r = await _post('$_baseUrl/mail/resend-code', body: {'email': email});
    _ensureOk(r, fallback: 'No se pudo reenviar el código');
  }

  /// POST /mail/verify-code  { email, code } → true si 200
  Future<bool> verifyCode(String email, String code) async {
    final r = await _post('$_baseUrl/mail/verify-code', body: {
      'email': email,
      'code': code,
    });

    if (r.statusCode == 200) return true;
    if (r.statusCode == 400 || r.statusCode == 404) return false;

    throw Exception(_extractMsg(r.body, fallback: 'Error al verificar código'));
  }

  /// POST /mail/reset-password  { email, code, newPassword }
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final r = await _post('$_baseUrl/mail/reset-password', body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    _ensureOk(r, fallback: 'No se pudo actualizar la contraseña');
  }

  // ----------------------
  // Helpers internos
  // ----------------------

  Future<http.Response> _post(
    String url, {
    required Map<String, dynamic> body,
  }) {
    return http
        .post(
          Uri.parse(url),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  void _ensureOk(http.Response r, {required String fallback}) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw Exception(_extractMsg(r.body, fallback: fallback));
  }

  String _extractMsg(String raw, {required String fallback}) {
    try {
      final m = jsonDecode(raw);
      return m['error']?.toString() ?? m['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
