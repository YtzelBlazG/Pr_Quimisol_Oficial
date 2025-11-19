// lib/features/admin/productos/presentation/pages/producto_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import '../widgets/producto_formulario.dart';

class ProductoEditPage extends StatelessWidget {
  final Producto producto;

  const ProductoEditPage({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth * 0.9 : 900.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          onPressed: () => Modular.to.pop(),
        ),
        title: const Text(
          "Editar Producto",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, minWidth: 400),
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            color: const Color(0xFFF8F0FF), // Fondo rosa claro
            child: SizedBox(
              width: cardWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 28 : 56,
                  vertical: isMobile ? 36 : 44,
                ),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Palette.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 40, color: Palette.primary),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Editar producto',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Palette.primary,
                            ),
                          ),
                         /* const SizedBox(height: 8),
                          Text(
                            'Modifica los datos del producto',
                            style: TextStyle(
                              fontSize: 15,
                              color: Palette.primary.withOpacity(0.75),
                            ),
                            textAlign: TextAlign.center,
                          ),*/
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // FORMULARIO CON SCROLL
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ProductoFormulario(
                          producto: producto,
                          onSuccess: () {
                            Modular.to.pop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}