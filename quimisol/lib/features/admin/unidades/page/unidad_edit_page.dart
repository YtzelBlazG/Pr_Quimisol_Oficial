// lib/features/admin/unidades/presentation/pages/unidad_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';
import '../controllers/unidad_controller.dart';
import '../widgets/unidad_formulario.dart';

class UnidadEditPage extends StatelessWidget {
  final Unit unidad;

  const UnidadEditPage({super.key, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final controlador = Modular.get<UnidadController>();
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
          "Editar Unidad",
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
                  mainAxisSize: MainAxisSize.min,
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
                            'Editar unidad',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Palette.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modifica los datos de la unidad',
                            style: TextStyle(
                              fontSize: 15,
                              color: Palette.primary.withOpacity(0.75),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    UnidadFormulario(
                      unidad: unidad,
                      onSubmit: (nuevaUnidad) async {
                        await controlador.editarUnidad(unidad.id, nuevaUnidad);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Unidad actualizada exitosamente'),
                            backgroundColor: Palette.statsSuccess,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        Modular.to.pop();
                      },
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