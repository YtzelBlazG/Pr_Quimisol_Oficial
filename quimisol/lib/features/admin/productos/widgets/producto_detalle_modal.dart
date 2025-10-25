import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/core/storage/auth_storage.dart';

class ProductoDetalleModal extends StatefulWidget {
  final Map<String, dynamic> producto;

  const ProductoDetalleModal({super.key, required this.producto});

  @override
  State<ProductoDetalleModal> createState() => _ProductoDetalleModalState();
}

class _ProductoDetalleModalState extends State<ProductoDetalleModal> {
  int cantidad = 1;

  Future<void> _agregarAlCarrito() async {
    final idUsuario = await AuthStorage.getIdPersona();
    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para añadir al carrito')),
      );
      return;
    }

    final stockDisponible = widget.producto['stock_disponible'] ?? 0;
    if (cantidad > stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solo hay $stockDisponible unidades disponibles')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3005/carrito'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idusuario': idUsuario,
          'idproducto': widget.producto['idproducto'],
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto añadido al carrito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con el backend')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favoritos = Provider.of<FavoritosProvider>(context);
    final bool esFavorito = favoritos.esFavorito(p['idproducto']);
    final int stock = p['stock_disponible'] ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        height: 460,
        child: Row(
          children: [
            // 🖼️ Imagen
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: (p['imagen'] != null && p['imagen'].isNotEmpty)
                    ? Image.network(p['imagen'], fit: BoxFit.contain)
                    : const Icon(Icons.image_not_supported, size: 100),
              ),
            ),

            // 📄 Detalles
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['descripcion'] ?? 'Sin descripción',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${p['precio'] ?? 0} Bs",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    Text(
                      "Stock disponible: $stock",
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 20),

                    // 🔢 Selector de cantidad
                    Row(
                      children: [
                        const Text("Cantidad:"),
                        IconButton(
                          onPressed: () {
                            if (cantidad > 1) {
                              setState(() {
                                cantidad--;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(cantidad.toString()),
                        IconButton(
                          onPressed: cantidad < stock
                              ? () => setState(() {
                                    cantidad++;
                                  })
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🛒 Añadir a la cesta
                    ElevatedButton.icon(
                      onPressed: stock == 0 ? null : _agregarAlCarrito,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text("Añadir a la cesta"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[300],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ❤️ Favoritos
                    TextButton.icon(
                      onPressed: () {
                        if (favoritos.idUsuario == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Debes iniciar sesión para gestionar favoritos')),
                          );
                          return;
                        }
                        favoritos.toggleFavorito(p);
                      },
                      icon: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito ? Colors.red : Colors.black,
                      ),
                      label: Text(
                        esFavorito ? "Quitar de favoritos" : "Añadir a favoritos",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
