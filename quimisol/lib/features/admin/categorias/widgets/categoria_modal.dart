import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import '../controllers/categoria_controller.dart';
import '../data/categoria_model.dart';
import 'categoria_formulario.dart';

Future<void> showCategoriaModal({
  required BuildContext context,
  Categoria? categoria,
}) {
  final CategoriaController controller = Modular.get<CategoriaController>();

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
                  color: Colors.black54,
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
                  Center(
                    child:Text(
                    categoria == null
                          ? "Nueva categoría"
                          : "Editar categoría",
                      style: const TextStyle(
                        color: Palette.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 26, color: Palette.primary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // FORMULARIO
                CategoriaFormulario(
                  categoria: categoria,
                  onSubmit: (nuevaCategoria) async {
                    if (categoria == null) {
                      await controller.agregarCategoria(nuevaCategoria);
                    } else {
                      await controller.editarCategoria(
                        categoria.id,
                        nuevaCategoria,
                      );
                    }
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
