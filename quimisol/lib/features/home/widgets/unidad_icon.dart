import 'package:flutter/material.dart';

class UnidadIcon extends StatelessWidget {
  final IconData icon;

  const UnidadIcon({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.deepPurple, size: 32),
    );
  }
}
