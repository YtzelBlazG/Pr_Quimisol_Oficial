import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../../shared/modals/incomplete_data_message.dart';
import '../../../../core/storage/auth_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Simulados por ahora hasta integrar backend real:
  final String? telefono = null;
  final String? contrasena = "123456";
  final List<String> ubicaciones = const [];

  @override
  void initState() {
    super.initState();
    // Sincroniza el estado inicial de sesión (no hace daño si ya se llamó en main)
    AuthStorage.init();
  }

  Future<void> _comprar(BuildContext context) async {
    // Consulta estado de sesión REACTIVO
    final bool loggedIn = AuthStorage.loginStatus.value;

    if (!loggedIn) {
      // No logueado → proponemos iniciar sesión
      await showIncompleteDataDialog(
        context,
        icon: Icons.lock_outline_rounded,
        title: 'Necesitas iniciar sesión',
        subtitle: 'Para completar la compra primero inicia sesión.',
        color: Colors.deepPurple,
        primaryText: 'Iniciar sesión',
        onPrimaryPressed: () => Modular.to.pushNamed('/auth/login'),
      );
      return;
    }

    // Logueado → verificamos datos faltantes
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();

    final List<String> faltantes = [];
    if (nombre == null || nombre.trim().isEmpty) faltantes.add('Nombre');
    if (telefono == null || (telefono?.trim().isEmpty ?? true))
      faltantes.add('Teléfono');
    if (correo == null || correo.trim().isEmpty) faltantes.add('Correo');
    if (contrasena == null || (contrasena?.isEmpty ?? true))
      faltantes.add('Contraseña');
    if (ubicaciones.isEmpty) faltantes.add('Ubicación');

    if (faltantes.isEmpty) {
      await showIncompleteDataDialog(
        context,
        icon: Icons.check_circle_rounded,
        title: '✅ Comprado con éxito',
        color: Colors.green,
        primaryText: 'Listo',
        onPrimaryPressed: () {},
      );
    } else {
      await showIncompleteDataDialog(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Información incompleta',
        subtitle: 'Por favor complete la siguiente información:',
        lines: faltantes,
        color: Colors.redAccent,
        primaryText: 'Registrar',
        onPrimaryPressed: () => Modular.to.pushNamed('/auth/profile'),
      );
    }
  }

  Future<void> _logout() async {
    await AuthStorage.clear(); // limpia solo la sesión local
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sesión cerrada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthStorage.loginStatus, // escucha cambios de sesión
      builder: (context, loggedIn, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio'),
            backgroundColor: Colors.deepPurple,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                ),
                const SizedBox(height: 32),

                // Comprar
                ElevatedButton(
                  onPressed: () => _comprar(context),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Comprar'),
                ),
                const SizedBox(height: 16),

                // Cerrar sesión SOLO si está logueado
                if (loggedIn)
                  ElevatedButton(
                    onPressed: _logout,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cerrar sesión'),
                  ),
              ],
            ),
          ),

          // FAB "Iniciar sesión" SOLO si NO está logueado
          floatingActionButton: (!loggedIn)
              ? FloatingActionButton.extended(
                  onPressed: () => Modular.to.pushNamed('/auth/login'),
                  label: const Text('Iniciar sesión'),
                  icon: const Icon(Icons.login),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
