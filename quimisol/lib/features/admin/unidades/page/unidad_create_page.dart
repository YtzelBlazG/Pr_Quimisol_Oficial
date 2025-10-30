import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import '../controllers/unidad_controller.dart';
import '../widgets/unidad_formulario.dart';

class UnidadCreatePage extends StatelessWidget {
  const UnidadCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = Modular.get<UnidadController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Unidad")),
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
                    'Registrar nueva unidad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  UnidadFormulario(
                    onSubmit: (unidad) async {
                      await controlador.agregarUnidad(unidad);

                      // ✅ Mostramos mensaje
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unidad creada exitosamente'),
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
