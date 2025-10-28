import 'package:flutter/material.dart';
import 'package:quimisol/core/services/postgresql/carrito/carrito_service.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class BotonAnadirCarrito extends StatelessWidget {
  final int idProducto;
  final int cantidad;

  const BotonAnadirCarrito({
    super.key,
    required this.idProducto,
    this.cantidad = 1,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: () async {
        final idUsuario = await AuthStorage.getIdPersona();

        if (idUsuario == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
          return;
        }

        try {
          final ok = await CarritoService.agregarProductoAlCarrito(
            idUsuario: idUsuario,
            idProducto: idProducto,
            cantidad: cantidad,
          );
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto añadido a la cesta')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      icon: const Icon(Icons.shopping_cart_outlined),
      style: IconButton.styleFrom(
        backgroundColor: Palette.button,
        foregroundColor: Colors.white,
      ),
    );
  }
}
