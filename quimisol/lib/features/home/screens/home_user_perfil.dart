import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class HomeUserPerfil extends StatefulWidget {
  const HomeUserPerfil({super.key});

  @override
  State<HomeUserPerfil> createState() => _HomeUserPerfilState();
}

class _HomeUserPerfilState extends State<HomeUserPerfil> {
  String nombre = "";
  String correo = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final n = await AuthStorage.getNombre();
    final c = await AuthStorage.getCorreo();
    setState(() {
      nombre = n ?? "";
      correo = c ?? "";
    });
  }

  Future<void> _logout() async {
    await AuthStorage.clear();
    Provider.of<FavoritosProvider>(context, listen: false).clear();
    Modular.to.navigate('/home-guest');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.fieldBg,
      appBar: AppBar(
        backgroundColor: Palette.fieldBg,
        elevation: 0,
        title: const Text('Mi perfil', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Palette.primary,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Center(
            child: Text(
              correo,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 30),

          const Text("Perfil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildTile(Icons.location_on, "Direcciones", () {}),
          _buildTile(Icons.favorite, "Favoritos", () => Modular.to.pushNamed('/favoritos')),


          const SizedBox(height: 24),
          const Text("Configuración", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildTile(Icons.notifications, "Notificaciones", () {}),
          _buildTile(Icons.info_outline, "Información legal", () {}),
          _buildTile(Icons.logout, "Cerrar sesión", _logout),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Palette.primary),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
