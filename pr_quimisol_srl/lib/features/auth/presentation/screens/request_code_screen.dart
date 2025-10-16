import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';
import 'reset_password_screen.dart';

class RequestCodeScreen extends StatefulWidget {
  const RequestCodeScreen({super.key});

  @override
  State<RequestCodeScreen> createState() => _RequestCodeScreenState();
}

class _RequestCodeScreenState extends State<RequestCodeScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _codeEnabled = false; // se activa luego de "ENVIAR CÓDIGO"
  bool _canContinue = false; // true = 6 dígitos

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
                    prefixIcon: Icon(Icons.alternate_email, color: Palette.primary),
                  ),
                  enabled: !_codeEnabled, 
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
                              onPressed: () {
                                setState(() => _codeEnabled = true); // oculta el botón
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Código enviado')),
                                );
                              },
                              child: const Text('ENVIAR CÓDIGO'),
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
                                prefixIcon: Icon(Icons.pin, color: Palette.primary),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Código reenviado.')),
                                    );
                                  },
                                  child: const Text(
                                    'Reenviar código',
                                    style: TextStyle(color: Palette.primary),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _changeEmail,
                                  child: const Text(
                                    'Cambiar correo',
                                    style: TextStyle(color: Palette.primary),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            ElevatedButton(
                              onPressed: _canContinue
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                      builder: (_) => ResetPasswordScreen( email: _emailCtrl.text.trim()),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('CONTINUAR'),
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
