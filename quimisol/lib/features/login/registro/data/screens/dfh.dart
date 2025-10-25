import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/theme/palette.dart';
import '../../../../../shared/widgets/gradient_background.dart';
import '../../../../../shared/widgets/rounded_card.dart';
import '../../../../../shared/widgets/social_button.dart';
import '../../../../../shared/buttons/app_button.dart'; // botón reusable
import '../widgets/login_header.dart';
import '../services/user_service.dart';
import '../../../../../core/storage/auth_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Duration _socialDelay = Duration(seconds: 2);

  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final _service = UserService();

  bool _isLoading = false;
  bool _showRegister = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final nombre = _showRegister ? _nameController.text.trim() : null;
    final correo = _userController.text.trim();
    final pass = _passController.text;

    if (_showRegister) {
      // ---------- REGISTRO ----------
      if (nombre == null || nombre.isEmpty) {
        return _toast('Ingrese su nombre completo');
      }
      if (!_isValidEmail(correo)) {
        return _toast('Ingrese un correo válido');
      }
      if (pass.isEmpty) {
        return _toast('Ingrese su contraseña');
      }

      setState(() => _isLoading = true);
      try {
        final res = await _service.register(nombre, correo, pass);
        final idPersona = res is Map && res['idpersona'] is int
            ? res['idpersona'] as int
            : null;

        await AuthStorage.saveUser(
          nombre: nombre,
          correo: correo,
          idPersona: idPersona,
          rol: 'cliente',
        );

        _toast('Registro exitoso');

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Modular.to.pushReplacementNamed('/home-user', arguments: {
            'nombre': nombre,
            'correo': correo,
          });
        });
      } catch (e) {
        _toast('Error al registrarse: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ---------- LOGIN ----------
      if (!_isValidEmail(correo)) {
        return _toast('Ingrese un correo válido');
      }
      if (pass.isEmpty) {
        return _toast('Ingrese su contraseña');
      }

      setState(() => _isLoading = true);
      try {
        final res = await _service.login(correo, pass);

        final usr = (res is Map && res['usuario'] is Map)
            ? (res['usuario'] as Map<String, dynamic>)
            : <String, dynamic>{};

        final nombreOk = (usr['nombre'] ?? '') as String?;
        final correoOk = (usr['correo'] ?? correo) as String?;
        final idPersona =
            usr['idpersona'] is int ? usr['idpersona'] as int : null;
        final rol = (usr['rol'] ?? 'cliente').toString().toLowerCase();
        final telefonoOk = (usr['telefono'] ?? '') as String?;

        await AuthStorage.saveUser(
          nombre: nombreOk ?? '',
          correo: correoOk ?? '',
          idPersona: idPersona,
          telefono: telefonoOk,
          rol: rol,
        );

        _toast('Inicio de sesión exitoso');

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rol == 'admin') {
            Modular.to.pushReplacementNamed('/admin');
          } else {
            Modular.to.pushReplacementNamed('/home-user', arguments: {
              'nombre': nombreOk,
              'correo': correoOk,
            });
          }
        });
      } catch (e) {
        _toast('Error al iniciar sesión: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() => setState(() => _showRegister = !_showRegister);

  bool _isValidEmail(String v) {
    final r = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');
    return r.hasMatch(v);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Palette.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Modular.to.canPop()) {
              Modular.to.pop();
            } else {
              Modular.to.pushReplacementNamed('/home-guest');
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoginHeader(),

                // Nombre completo (solo registro)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showRegister
                      ? Padding(
                          key: const ValueKey('nombre'),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Ingrese su nombre completo',
                              prefixIcon:
                                  Icon(Icons.person, color: Palette.primary),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty-nombre')),
                ),

                // Correo
                TextField(
                  controller: _userController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese su correo',
                    prefixIcon: Icon(Icons.email, color: Palette.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextField(
                  controller: _passController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Ingrese su contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Palette.primary),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                AppButton(
                  label: _showRegister ? 'REGISTRARSE' : 'INICIAR SESIÓN',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: FontAwesomeIcons.google,
                      onPressed: () async => await Future.delayed(_socialDelay),
                    ),
                    const SizedBox(width: 10),
                    SocialButton(
                      icon: FontAwesomeIcons.facebookF,
                      onPressed: () async => await Future.delayed(_socialDelay),
                    ),
                    const SizedBox(width: 10),
                    SocialButton(
                      icon: FontAwesomeIcons.instagram,
                      onPressed: () async => await Future.delayed(_socialDelay),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(
                    _showRegister
                        ? '¿Ya tienes una cuenta? Iniciar sesión'
                        : '¿No tienes una cuenta? Crear cuenta',
                    style: const TextStyle(color: Palette.primary),
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
