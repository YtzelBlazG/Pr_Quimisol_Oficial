import 'package:flutter/material.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onViewMore;

  const ProductCard({
    super.key,
    required this.producto,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor == Colors.white
            ? Colors.white
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Image.network(
            producto.imagen ?? '',
            height: 100,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 48),
          ),
          const SizedBox(height: 10),
          Text(
            producto.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Palette.primary,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onViewMore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Ver más', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
