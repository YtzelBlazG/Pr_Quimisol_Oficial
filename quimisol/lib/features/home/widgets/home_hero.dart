import 'package:flutter/material.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.home, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 16),
        Text(
          '¡Bienvenido a Quimisol SRL!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explora productos de limpieza de calidad.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF432667),
              ),
        ),
      ],
    );
  }
}
