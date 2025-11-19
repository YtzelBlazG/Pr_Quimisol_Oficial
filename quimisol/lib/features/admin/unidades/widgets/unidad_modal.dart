import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import '../data/models/unidad_model.dart';
import '../controllers/unidad_controller.dart';
import 'unidad_formulario.dart';
import 'package:flutter_modular/flutter_modular.dart';

Future<void> showUnidadModal({
  required BuildContext context,
  Unit? unidad,
}) {
  final UnidadController controlador = Modular.get<UnidadController>();

  return showDialog(
    context: context,
    barrierDismissible: true, 
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      unidad == null ? "Nueva Unidad" : "Editar Unidad",
                      style: const TextStyle(
                        color: Palette.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 26, color: Palette.primary),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                // FORMULARIO REUTILIZADO
                UnidadFormulario(
                  unidad: unidad,
                  onSubmit: (nuevaUnidad) async {
                    if (unidad == null) {
                      await controlador.agregarUnidad(nuevaUnidad);
                    } else {
                      await controlador.editarUnidad(unidad.id, nuevaUnidad);
                    }

                    Navigator.pop(context); // cerrar modal
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
