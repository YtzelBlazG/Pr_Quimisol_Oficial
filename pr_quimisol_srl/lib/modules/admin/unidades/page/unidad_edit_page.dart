import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../controllers/unidad_controller.dart';
import '../widgets/unidad_formulario.dart';
import '../../../../models/unidad_model.dart';

class UnidadEditPage extends StatelessWidget {
  final Unit unidad;

  const UnidadEditPage({super.key, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final controlador = Modular.get<UnidadController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Unidad")),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar unidad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  UnidadFormulario(
                    unidad: unidad,
                    onSubmit: (nuevaUnidad) async {
                      await controlador.editarUnidad(unidad.id, nuevaUnidad);

                      // ✅ Mostrar mensaje de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unidad actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Modular.to.pop(); // volver a la lista
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
