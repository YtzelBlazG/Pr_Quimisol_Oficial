import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/storage/auth_storage.dart';

class HomeRepartidorPage extends StatelessWidget {
  const HomeRepartidorPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthStorage.clear(); // 👈 usa tu método real
    Modular.to.pushReplacementNamed('/home-guest');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f6fb),
      appBar: AppBar(
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Panel de repartidor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Hola, repartidor 👋\n\nAquí pronto verás tus pedidos asignados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
