import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';

import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';

import 'package:quimisol/features/admin/productos/page/productos_public_list.dart';
import 'package:quimisol/features/public/favoritos/favoritos_page.dart';
import 'package:quimisol/features/public/pages/carrito_page.dart'; // ✅ nuevo import

class HomeUserPage extends StatefulWidget {
  const HomeUserPage({super.key});

  @override
  State<HomeUserPage> createState() => _HomeUserPageState();
}

class _HomeUserPageState extends State<HomeUserPage> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const Center(child: Text("Home Page"));
      case 1:
        return const ProductosPublicList();
      case 2:
        return const FavoritosPage();
      case 3:
        return const CarritoPage(); // ✅ cambio aplicado
      default:
        return const Center(child: Text("Página no encontrada"));
    }
  }

  /// 🔒 Logout completo: limpia sesión y favoritos
  Future<void> _onLogout() async {
    await AuthStorage.clear(); // 1. Limpia SharedPreferences

    // 2. Limpia favoritos del estado global
    final favProvider = Provider.of<FavoritosProvider>(context, listen: false);
    favProvider.clear();

    // 3. Redirigir a pantalla guest
    Modular.to.navigate('/home-guest');
  }

  /// 👤 Mostrar menú de cuenta
  void _showUserDrawer() async {
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 48, color: Palette.primary),
            const SizedBox(height: 10),
            Text(
              nombre ?? "Invitado",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              correo ?? "",
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () {
                Navigator.pop(context);
                _onLogout(); // ✅ logout completo
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.fieldBg,
      body: _buildPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Palette.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Productos'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUserDrawer,
        backgroundColor: Palette.primary,
        child: const Icon(Icons.menu),
      ),
    );
  }
}
