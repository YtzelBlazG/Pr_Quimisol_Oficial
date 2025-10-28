import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_detalle_modal.dart';
import 'package:quimisol/shared/buttons/boton_anadir_carrito.dart';
import 'package:quimisol/shared/buttons/fav_button.dart';

class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final favoritos = Provider.of<FavoritosProvider>(context);
    final idProducto = producto['idproducto'];
    favoritos.esFavorito(idProducto);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ProductoDetalleModal(producto: producto),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // === Imagen + Botón favorito ===
              SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Center(
                      child: Image.network(
                        producto['imagen'] ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                   Positioned(
                        top: 0, right: 0,
                        child: FavButton(producto: producto),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // === Nombre: alineado a la izquierda, más grande y negrilla ===
              Text(
                producto['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // === Precio + Botón carrito ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Precio
                  Text(
                    '${producto['precio'] ?? 0} Bs',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  // Botón carrito
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: BotonAnadirCarrito(idProducto: idProducto),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}