import 'package:flutter/material.dart';
import 'unidad_icon.dart';

class UnitsSection extends StatelessWidget {
  const UnitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8D2FA),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: const Column(
        children: [
          Text(
            'Unidades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF432667),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UnidadIcon(icon: Icons.science),
              UnidadIcon(icon: Icons.local_hospital),
              UnidadIcon(icon: Icons.local_drink),
            ],
          ),
        ],
      ),
    );
  }
}
