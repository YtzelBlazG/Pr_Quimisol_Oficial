// lib/shared/widgets/main_layout.dart
import 'package:flutter/material.dart';
import 'package:quimisol/features/admin/widgets/footer.dart';
import 'package:quimisol/features/admin/widgets/top_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child; // aquí irá el contenido de cada página

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(), // Siempre visible arriba
          Expanded(
            child: SingleChildScrollView(
              child: child, // Aquí inyectamos la vista
            ),
          ),
          const Footer(), // Siempre visible abajo
        ],
      ),
    );
  }
}
