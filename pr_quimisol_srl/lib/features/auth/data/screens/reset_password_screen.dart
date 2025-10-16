import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _match =>
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _passCtrl.text == _confirmCtrl.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear nueva contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para el correo ${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                
                const SizedBox(height: 24),

                // Nueva contraseña
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure1,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Palette.primary),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(
                        _obscure1 ? Icons.visibility : Icons.visibility_off,
                        color: Palette.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirmar contraseña
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: Palette.primary),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(
                        _obscure2 ? Icons.visibility : Icons.visibility_off,
                        color: Palette.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_passCtrl.text.isNotEmpty || _confirmCtrl.text.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        _match ? Icons.check_circle : Icons.error_outline,
                        color: _match ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _match ? 'Las contraseñas coinciden' : 'Las contraseñas no coinciden',
                        style: TextStyle(
                          color: _match ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _match
                      ? () {                        
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contraseña actualizada')),
                          );
                        } : null,
                  child: const Text('GUARDAR CONTRASEÑA'),
                ),

                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Palette.primary),
                  ),
                  child: const Text('Volver', style: 
                    TextStyle(color: Palette.primary, fontWeight: FontWeight.w600),
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
