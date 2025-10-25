import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/palette.dart';

class HomeGuestPage extends StatelessWidget {
  const HomeGuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.gradientStart, Palette.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.shopping_bag, size: 100, color: Palette.primary),
            const SizedBox(height: 20),
            const Text(
              "Bienvenido a Quimisol SRL",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Palette.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tu tienda de confianza para productos de limpieza e industria.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Modular.to.navigate('/auth/login'); // ✅ Ruta corregida
                },
                child: const Text("Iniciar sesión", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Modular.to.navigate('/auth/register'); // ⚠️ asegúrate de tener esta ruta
              },
              child: const Text("¿No tienes cuenta? Regístrate"),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
