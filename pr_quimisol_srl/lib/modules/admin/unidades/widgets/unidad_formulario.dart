import 'package:flutter/material.dart';
import '../../../../models/unidad_model.dart';

class UnidadFormulario extends StatefulWidget {
  final Unit? unidad;
  final Function(Unit) onSubmit;

  const UnidadFormulario({super.key, this.unidad, required this.onSubmit});

  @override
  State<UnidadFormulario> createState() => _UnidadFormularioState();
}

class _UnidadFormularioState extends State<UnidadFormulario> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.unidad?.nombre ?? '');
    descripcionCtrl = TextEditingController(text: widget.unidad?.descripcion ?? '');
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevaUnidad = Unit(
        id: widget.unidad?.id ?? 0,
        nombre: nombreCtrl.text,
        descripcion: descripcionCtrl.text,
      );
      widget.onSubmit(nuevaUnidad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          TextFormField(
            controller: descripcionCtrl,
            decoration: const InputDecoration(labelText: 'Descripción'),
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _guardar,
          )
        ],
      ),
    );
  }
}
