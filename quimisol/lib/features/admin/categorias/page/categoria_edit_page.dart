import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';
import '../controllers/categoria_controller.dart';
import '../widgets/categoria_formulario.dart';

class CategoriaEditPage extends StatelessWidget {
  final Categoria categoria;

  const CategoriaEditPage({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final controlador = Modular.get<CategoriaController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Categoría")),
      body: Center(
        child: SingleChildScrollView(
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
                      'Editar categoría',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Palette.gradientEnd,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CategoriaFormulario(
                      categoria: categoria,
                      onSubmit: (nuevaCategoria) async {
                        await controlador.editarCategoria(categoria.id, nuevaCategoria);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Categoría actualizada exitosamente'),
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
