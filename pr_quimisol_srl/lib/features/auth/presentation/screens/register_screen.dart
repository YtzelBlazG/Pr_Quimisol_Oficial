import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToMap() {
   /* Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>()),
    );*/
  }

  void _finishRegister() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro completo ✅')),
    );
    Navigator.pop(context); // volver al login o al dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Completa tu registro',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Palette.primary,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline, color: Palette.primary),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    hintText: 'Apellido',
                    prefixIcon: Icon(Icons.person, color: Palette.primary),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone, color: Palette.primary),
                  ),
                ),

                const SizedBox(height: 24),

                 // Botón finalizar (principal)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finishRegister,
                    child: const Text(
                      'FINALIZAR REGISTRO',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                 // Botón para ir al mapa (secundario)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goToMap,
                    icon: const Icon(Icons.map_outlined, color: Palette.primary),
                    label: const Text(
                      'AGREGAR ZONA EN EL MAPA',
                      style: TextStyle(
                        color: Palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Palette.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
