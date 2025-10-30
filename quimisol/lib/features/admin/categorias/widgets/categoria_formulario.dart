import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';

class CategoriaFormulario extends StatefulWidget {
  final Categoria? categoria;
  final Function(Categoria) onSubmit;

  const CategoriaFormulario({
    super.key,
    this.categoria,
    required this.onSubmit,
  });

  @override
  State<CategoriaFormulario> createState() => _CategoriaFormularioState();
}

class _CategoriaFormularioState extends State<CategoriaFormulario> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.categoria?.nombre ?? '');
    descripcionCtrl = TextEditingController(text: widget.categoria?.descripcion ?? '');
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevaCategoria = Categoria(
        id: widget.categoria?.id ?? 0,
        nombre: nombreCtrl.text,
        descripcion: descripcionCtrl.text,
      );
      widget.onSubmit(nuevaCategoria);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Campo: Nombre
          TextFormField(
            controller: nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              filled: true,
              fillColor: Color(0xFFF9F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
          ),

          const SizedBox(height: 24),

          /// Campo: Descripción (multilínea)
          TextFormField(
            controller: descripcionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Color(0xFFF9F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),

          const SizedBox(height: 32),

          /// Botón: Guardar
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.button,
              foregroundColor: Palette.fieldBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            onPressed: _guardar,
          ),
        ],
      ),
    );
  }
}
