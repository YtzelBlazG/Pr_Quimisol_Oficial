import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';
import '../../../../shared/widgets/social_button.dart';
import '../widgets/login_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Duration _loginTime = Duration(seconds: 2);

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showConfirm = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoginHeader(),

                // Usuario
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese su usuario',
                    prefixIcon: Icon(Icons.person, color: Palette.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese su contraseña',
                    prefixIcon: Icon(Icons.lock, color: Palette.primary),
                  ),
                ),

                // Confirm password (aparece al tocar el TextButton)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _showConfirm
                      ? Padding(
                          key: const ValueKey('confirm'),
                          padding: const EdgeInsets.only(top: 16),
                          child: TextField(
                            controller: _confirmController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Confirme su contraseña',
                              prefixIcon:
                                  Icon(Icons.lock_outline, color: Palette.primary),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(value: false, onChanged: (v) {}),
                    const Text('Recordarme', style: TextStyle(color: Palette.primary)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Palette.primary)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Aquí podrías validar si _showConfirm está activo y comparar pass/confirm
                  },
                  child: const Text('INICIAR SESIÓN',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: FontAwesomeIcons.google,
                      onPressed: () async => await Future.delayed(_loginTime),
                    ),
                    const SizedBox(width: 10),
                    SocialButton(
                      icon: FontAwesomeIcons.facebookF,
                      onPressed: () async => await Future.delayed(_loginTime),
                    ),
                    const SizedBox(width: 10),
                    SocialButton(
                      icon: FontAwesomeIcons.instagram,
                      onPressed: () async => await Future.delayed(_loginTime),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() => _showConfirm = !_showConfirm);
                  },
                  child: const Text(
                    '¿No tienes una cuenta? Crear cuenta',
                    style: TextStyle(color: Palette.primary),
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
