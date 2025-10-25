import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_detalle_modal.dart';
import 'package:quimisol/shared/widgets/boton_anadir_carrito.dart';


class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final favoritos = Provider.of<FavoritosProvider>(context);
    final idProducto = producto['idproducto'];
    final esFavorito = favoritos.esFavorito(idProducto);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ProductoDetalleModal(producto: producto),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.network(
                producto['imagen'] ?? '',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
              ),
              Text(
                producto['nombre'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              Text('${producto['precio']} Bs'),

              // ✅ Botón funcional de añadir al carrito
              BotonAnadirCarrito(idProducto: idProducto),

              // ❤️ Botón de favoritos
              IconButton(
                icon: Icon(
                  esFavorito ? Icons.favorite : Icons.favorite_border,
                  color: esFavorito ? Colors.red : Colors.black,
                ),
                onPressed: () => favoritos.toggleFavorito(producto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
