import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await AuthStorage.init();
    final logged = await AuthStorage.isLoggedIn();
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();
    final telefono = await AuthStorage.getTelefono();
    final idPersona = await AuthStorage.getIdPersona();
    final rol = await AuthStorage.getRol();

    debugPrint("======= AUTH STORAGE DATA (Splash) =======");
    debugPrint("isLogged  : $logged");
    debugPrint("Nombre    : $nombre");
    debugPrint("Correo    : $correo");
    debugPrint("Teléfono  : $telefono");
    debugPrint("IdPersona : $idPersona");
    debugPrint("Rol       : $rol");
    debugPrint("==========================================");

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (logged) {
      if (rol == 'admin') {
        Modular.to.pushReplacementNamed('/admin');
      } else {
        Modular.to.pushReplacementNamed('/home-user'); // cliente logueado
      }
    } else {
      Modular.to.pushReplacementNamed('/home-guest'); // cliente sin login
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Palette.primary,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
