// IMPORTS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/theme/palette.dart';
import '../../../../../shared/widgets/gradient_background.dart';
import '../../../../../shared/widgets/rounded_card.dart';
import '../../../../../shared/widgets/social_button.dart';
import '../../../../../shared/buttons/app_button.dart';
import 'request_code_screen.dart';
import '../widgets/login_header.dart';
import '../services/user_service.dart';
import '../../../../../core/storage/auth_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _telefonoController = TextEditingController();

  final _service = UserService();

  bool _isLoading = false;
  bool _showRegister = false;
  bool _hidePassword = true;
  String _passwordStrength = '';

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _passController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final nombre = _showRegister ? _nameController.text.trim() : null;
    final correo = _userController.text.trim();
    final pass = _passController.text;
    final telefono = _showRegister ? _telefonoController.text.trim() : '';

    if (_showRegister) {
      if (nombre == null || nombre.isEmpty) {
        return _toast('Ingrese su nombre completo');
      }
      if (telefono.isEmpty) {
        return _toast('Ingrese su número de teléfono');
      }
      if (!_isValidPhone(telefono)) {
        return _toast('Teléfono inválido (solo números de 7 a 12 dígitos)');
      }
      if (!_isValidEmail(correo)) {
        return _toast('Correo inválido (debe contener @ y dominio válido)');
      }
      if (!_isStrongPassword(pass)) {
        return _toast(
          'Contraseña débil. Debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos.',
        );
      }

      setState(() => _isLoading = true);
      try {
        final res = await _service.register(nombre, correo, pass, telefono);
        final idPersona = res is Map && res['idpersona'] is int
            ? res['idpersona'] as int
            : null;

        await AuthStorage.saveUser(
          nombre: nombre,
          correo: correo,
          idPersona: idPersona,
          telefono: telefono,
          rol: 'cliente',
        );

        _toast('Registro exitoso');
        if (!mounted) return;
        Modular.to.pushReplacementNamed(
          '/home-user',
          arguments: {'nombre': nombre, 'correo': correo},
        );
      } catch (e) {
        final msg = e.toString().contains('correo')
            ? 'Este correo ya está registrado'
            : 'Error al registrarse: $e';
        _toast(msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (!_isValidEmail(correo)) {
        return _toast('Correo inválido');
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
        Modular.to.pushReplacementNamed(
          rol == 'admin' ? '/admin' : '/home-user',
          arguments: {'nombre': nombreOk, 'correo': correoOk},
        );
      } catch (e) {
        _toast('Error al iniciar sesión: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ===== VALIDACIONES =====
  bool _isValidEmail(String v) {
    final r = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    return r.hasMatch(v);
  }

  bool _isValidPhone(String v) {
    final r = RegExp(r'^[0-9]{7,12}$');
    return r.hasMatch(v);
  }

  bool _isStrongPassword(String v) {
    final hasMinLength = v.length >= 8;
    final hasUpper = v.contains(RegExp(r'[A-Z]'));
    final hasLower = v.contains(RegExp(r'[a-z]'));
    final hasNumber = v.contains(RegExp(r'[0-9]'));
    final hasSymbol = v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    return hasMinLength && hasUpper && hasLower && hasNumber && hasSymbol;
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'Fuerte':
        return Colors.green;
      case 'Media':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _updatePasswordStrength(String value) {
    final score = [
      value.length >= 8,
      value.contains(RegExp(r'[A-Z]')),
      value.contains(RegExp(r'[a-z]')),
      value.contains(RegExp(r'[0-9]')),
      value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    ].where((x) => x).length;

    setState(() {
      if (score >= 4) {
        _passwordStrength = 'Fuerte';
      } else if (score >= 3) {
        _passwordStrength = 'Media';
      } else {
        _passwordStrength = 'Débil';
      }
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _toggleMode() => setState(() => _showRegister = !_showRegister);

  // ===== UI =====
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

                // ===== Nombre =====
                if (_showRegister)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Nombre completo',
                        prefixIcon:
                            Icon(Icons.person, color: Palette.primary),
                      ),
                    ),
                  ),

                // ===== Teléfono =====
                if (_showRegister)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Teléfono',
                        prefixIcon:
                            Icon(Icons.phone, color: Palette.primary),
                      ),
                    ),
                  ),

                // ===== Correo =====
                TextField(
                  controller: _userController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon:
                        Icon(Icons.email, color: Palette.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // ===== Contraseña =====
                TextField(
                  controller: _passController,
                  obscureText: _hidePassword,
                  onChanged: _updatePasswordStrength,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon:
                        const Icon(Icons.lock, color: Palette.primary),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),

                // ===== Indicador de fuerza de contraseña =====
                if (_showRegister && _passController.text.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 6.0, bottom: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Text(
                          'Seguridad: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _passwordStrength,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getPasswordStrengthColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ===== Olvidaste tu contraseña =====
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RequestCodeScreen()),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Palette.primary),
                      ),
                    ),
                  ],
                ),

                // ===== Botón principal =====
                AppButton(
                  label:
                      _showRegister ? 'REGISTRARSE' : 'INICIAR SESIÓN',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),

                const SizedBox(height: 18),

                // ===== Redes Sociales =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                        icon: FontAwesomeIcons.google,
                        onPressed: () {}),
                    const SizedBox(width: 10),
                    SocialButton(
                        icon: FontAwesomeIcons.facebookF,
                        onPressed: () {}),
                    const SizedBox(width: 10),
                    SocialButton(
                        icon: FontAwesomeIcons.instagram,
                        onPressed: () {}),
                  ],
                ),

                const SizedBox(height: 10),

                // ===== Cambiar modo =====
                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(
                    _showRegister
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate',
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
