import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import '../controllers/categoria_controller.dart';
import '../widgets/categoria_formulario.dart';

class CategoriaCreatePage extends StatelessWidget {
  const CategoriaCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = Modular.get<CategoriaController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Categoría")),
      body: Center(
        child: SingleChildScrollView( // ✅ permite scroll en pantallas chicas
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registrar nueva categoría',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Palette.gradientStart,
                      ),
                    ),
                    const SizedBox(height: 32), // ✅ más espacio
                    CategoriaFormulario(
                      onSubmit: (categoria) async {
                        await controlador.agregarCategoria(categoria);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Categoría creada exitosamente'),
                            backgroundColor: Colors.green,
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
