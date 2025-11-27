import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/shared/widgets/gradient_background.dart';
import 'package:quimisol/shared/widgets/rounded_card.dart';
import 'reset_password_screen.dart';
import '../services/mail_recovery_service.dart';

class RequestCodeScreen extends StatefulWidget {
  const RequestCodeScreen({super.key});

  @override
  State<RequestCodeScreen> createState() => _RequestCodeScreenState();
}

class _RequestCodeScreenState extends State<RequestCodeScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  // 🔧 AJUSTA el baseUrl según tu entorno
  final _svc = MailRecoveryService(baseUrl: 'http://10.192.87.85:3005');

  bool _codeEnabled = false; // se activa luego de "ENVIAR CÓDIGO"
  bool _canContinue = false; // true = 6 dígitos
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onCodeChanged(String v) {
    setState(() => _canContinue = v.trim().length == 6);
  }

  void _changeEmail() {
    setState(() {
      _codeEnabled = false;
      _canContinue = false;
      _codeCtrl.clear();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Ingresa tu correo');
      return;
    }
    setState(() => _loading = true);
    try {
      await _svc.sendCode(email);
      setState(() => _codeEnabled = true);
      _snack('Código enviado a $email');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Ingresa tu correo');
      return;
    }
    setState(() => _loading = true);
    try {
      await _svc.resendCode(email);
      _snack('Código reenviado.');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _continue() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (email.isEmpty || code.length != 6) return;

    setState(() => _loading = true);
    try {
      final ok = await _svc.verifyCode(email, code);
      if (!ok) {
        _snack('Código inválido o expirado');
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: email, code: code),
        ),
      );
    } catch (e) {
      _snack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recuperar acceso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tu correo. Te enviaremos un código para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Correo o Teléfono
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Palette.primary,
                    ),
                  ),
                  enabled: !_codeEnabled && !_loading,
                ),

                // El botón desaparece y aparece el input de código
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: !_codeEnabled
                      ? Column(
                          key: const ValueKey('send'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loading ? null : _sendCode,
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('ENVIAR CÓDIGO'),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('code'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            TextField(
                              controller: _codeCtrl,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              onChanged: _onCodeChanged,
                              decoration: const InputDecoration(
                                hintText: 'Código de verificación (6 dígitos)',
                                counterText: '',
                                prefixIcon: Icon(
                                  Icons.pin,
                                  color: Palette.primary,
                                ),
                              ),
                              enabled: !_loading,
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                TextButton(
                                  onPressed: _loading ? null : _resendCode,
                                  child: const Text(
                                    'Reenviar código',
                                    style: TextStyle(color: Palette.primary),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _loading ? null : _changeEmail,
                                  child: const Text(
                                    'Cambiar correo',
                                    style: TextStyle(color: Palette.primary),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            ElevatedButton(
                              onPressed: (_canContinue && !_loading)
                                  ? _continue
                                  : null,
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('CONTINUAR'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
