import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';

class BeneficioItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const BeneficioItem({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Palette.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
