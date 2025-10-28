import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_card.dart';
import 'package:quimisol/core/theme/palette.dart';

class ProductosPublicList extends StatefulWidget {
  const ProductosPublicList({super.key});

  @override
  State<ProductosPublicList> createState() => _ProductosPublicListState();
}

class _ProductosPublicListState extends State<ProductosPublicList> {
  List<dynamic> productos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  /// 🔁 Detecta si cambió de usuario
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final favoritosProvider = Provider.of<FavoritosProvider>(
      context,
      listen: false,
    );
    favoritosProvider
        .checkAndUpdateUsuario(); // 👈 Asegura que esté usando el usuario correcto
  }

  Future<void> cargarProductos() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3005/productos'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          productos = data;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      print('Excepción cargando productos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productos.isEmpty) {
      return const Center(child: Text('No hay productos disponibles.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: productos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2 / 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final producto = productos[index];
          return ProductoCard(producto: producto);
        },
      ),
    );
  }
}