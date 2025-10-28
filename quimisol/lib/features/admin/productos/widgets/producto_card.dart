import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_detalle_modal.dart';


class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final favoritos = Provider.of<FavoritosProvider>(context);
    final idProducto = producto['idproducto'];
    final esFavorito = favoritos.esFavorito(idProducto);

    // Usamos el campo correcto del backend
    final bool agotado = (producto['stock_disponible'] ?? 0) == 0;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ProductoDetalleModal(producto: producto),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + AGOTADO + botones
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      producto['imagen'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 80),
                    ),
                  ),

                  // Overlay AGOTADO
                  if (agotado)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        alignment: Alignment.center,
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 2)],
                          ),
                        ),
                      ),
                    ),

                  // Favoritos
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(
                          esFavorito ? Icons.favorite : Icons.favorite_border,
                          color: esFavorito ? Colors.red : Colors.grey[800],
                          size: 18,
                        ),
                        onPressed: () => favoritos.toggleFavorito(producto),
                      ),
                    ),
                  ),

                  // Detalle
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.purple),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                ProductoDetalleModal(producto: producto),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Texto: nombre y precio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bs ${producto['precio']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3B59),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
