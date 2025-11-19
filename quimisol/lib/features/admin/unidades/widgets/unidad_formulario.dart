import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';

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
        nombre: nombreCtrl.text.trim(),
        descripcion: descripcionCtrl.text.trim(),
      );
      widget.onSubmit(nuevaUnidad);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(nombreCtrl, 'Nombre', Icons.label, validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null),
          const SizedBox(height: 18),
          _buildField(descripcionCtrl, 'Descripción', Icons.description, maxLines: 3, validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null),
          const SizedBox(height: 36),

          // BOTÓN
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 22),
              label: const Text(
                'Guardar unidad',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.button,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: Palette.primary.withOpacity(0.4),
              ),
              onPressed: _guardar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _fieldDecoration(label, icon),
      style: const TextStyle(fontSize: 15.5),
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Palette.primary, size: 24),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Palette.card, width: 1.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Palette.primary, width: 2.8),
      ),
    );
  }
}