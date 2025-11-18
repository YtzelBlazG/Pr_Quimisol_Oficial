import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/shared/widgets/gradient_background.dart';
import 'package:quimisol/shared/widgets/rounded_card.dart';
import '../services/mail_recovery_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code; // <-- nuevo: recibe el código verificado

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  // 🔧 AJUSTA el baseUrl según tu entorno
  final _svc = MailRecoveryService(baseUrl: 'http://192.168.213.85:3005');

  bool _saving = false;

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (!_match) return;
    setState(() => _saving = true);
    try {
      await _svc.resetPassword(
        widget.email,
        widget.code,
        _passCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context); // volver a la pantalla anterior (login o request)
      _snack('Contraseña actualizada');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
                  enabled: !_saving,
                ),

                const SizedBox(height: 16),

                // Confirmar contraseña
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Confirmar contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Palette.primary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(
                        _obscure2 ? Icons.visibility : Icons.visibility_off,
                        color: Palette.primary,
                      ),
                    ),
                  ),
                  enabled: !_saving,
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
                        _match
                            ? 'Las contraseñas coinciden'
                            : 'Las contraseñas no coinciden',
                        style: TextStyle(
                          color: _match ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _match && !_saving ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('GUARDAR CONTRASEÑA'),
                ),

                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Palette.primary),
                  ),
                  child: const Text(
                    'Volver',
                    style: TextStyle(
                      color: Palette.primary,
                      fontWeight: FontWeight.w600,
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
