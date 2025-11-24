import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_formulario.dart';

Future<void> showProductoModal({
  required BuildContext context,
  Producto? producto,
}) {
  final bool isEdit = producto != null;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.of(dialogContext).size;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,  // margen lateral
          vertical: 32,    // margen arriba / abajo
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            // un poco menos que el alto total para que no toque bordes
            maxHeight: size.height - 96,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Editar producto' : 'Nuevo producto',
                      style: const TextStyle(
                        color: Palette.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 26,
                        color: Palette.primary,
                      ),
                    ),
                  ],
                ),
                //const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // FORM SCROLLEABLE
                Expanded(
                  child: SingleChildScrollView(
                    child: ProductoFormulario(
                      producto: producto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
