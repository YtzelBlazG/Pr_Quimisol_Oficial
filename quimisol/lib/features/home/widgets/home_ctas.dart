import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';

class HomeCTAs extends StatelessWidget {
  final VoidCallback onViewProducts;
  final VoidCallback onComprar;

  const HomeCTAs({
    super.key,
    required this.onViewProducts,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onViewProducts,
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'Ver productos',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onComprar,
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Comprar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.secButton,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}
