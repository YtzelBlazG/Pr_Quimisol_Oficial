import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_card.dart';
import 'package:quimisol/core/theme/palette.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<FavoritosProvider>(
      context,
      listen: false,
    ).checkAndUpdateUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final favoritos = Provider.of<FavoritosProvider>(context);

    if (favoritos.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (favoritos.idUsuario == null) {
      return const Scaffold(
        body: Center(
          child: Text("Debes iniciar sesión para ver tus favoritos."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Favoritos"),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: favoritos.cargarFavoritos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: favoritos.favoritos.isEmpty
            ? const Center(child: Text("No tienes productos en favoritos."))
            : GridView.builder(
                itemCount: favoritos.favoritos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final producto = favoritos.favoritos[index];
                  return ProductoCard(producto: producto); // ✅ solo esto
                },
              ),
      ),
    );
  }
}
