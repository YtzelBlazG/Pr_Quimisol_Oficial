// lib/features/admin/roles/presentation/widgets/rol_formulario.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';

class RolFormulario extends StatefulWidget {
  const RolFormulario({super.key});

  @override
  State<RolFormulario> createState() => _RolFormularioState();
}

class _RolFormularioState extends State<RolFormulario> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();

  bool _guardando = false;

  Future<void> _guardarRol() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      // Aquí luego se conectará al backend
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rol creado correctamente'),
          backgroundColor: Palette.statsSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Modular.to.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al crear el rol'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildField(
            _nombreController,
            'Nombre del rol',
            Icons.badge_outlined,
            hint: 'Ejemplo: Administrador',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Por favor ingrese el nombre del rol';
              if (v.trim().length < 3) return 'Debe tener al menos 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 36),

          // BOTÓN
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarRol,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: Palette.primary.withOpacity(0.4),
              ),
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.save, size: 22),
              label: Text(
                _guardando ? 'Guardando...' : 'Guardar Rol',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
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
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      ),
      style: const TextStyle(fontSize: 15.5),
      validator: validator,
    );
  }
}