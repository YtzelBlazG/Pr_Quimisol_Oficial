import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';
import '../widgets/login_header.dart';
import '../../../../core/storage/auth_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _nombre;
  String? _correo;

  // Simulados por ahora hasta integrar backend/servicios:
  final String? _telefono = null;
  final List<String> _ubicaciones = const [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();
    if (!mounted) return;
    setState(() {
      _nombre = nombre;
      _correo = correo;
      _loading = false;
    });
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    final bool missing = value == null || value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: missing
              ? Colors.redAccent.withOpacity(.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: missing ? Colors.redAccent : Palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(
                  missing ? 'No registrado' : value!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: missing ? Colors.redAccent : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowCount({
    required IconData icon,
    required String label,
    required int count,
  }) {
    final bool missing = count <= 0;
    final String value = missing ? 'No registrado' : '$count registrado(s)';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: missing
              ? Colors.redAccent.withOpacity(.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: missing ? Colors.redAccent : Palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: missing ? Colors.redAccent : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // 👈 retrocede
        ),
      ),
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: _loading
                ? const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoginHeader(),

                        _infoRow(
                          icon: Icons.person,
                          label: 'Nombre completo',
                          value: _nombre,
                        ),
                        _infoRow(
                          icon: Icons.email,
                          label: 'Correo',
                          value: _correo,
                        ),
                        _infoRow(
                          icon: Icons.phone,
                          label: 'Teléfono',
                          value: _telefono,
                        ),
                        _infoRowCount(
                          icon: Icons.location_on,
                          label: 'Ubicaciones',
                          count: _ubicaciones.length,
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Los campos en rojo deben completarse.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
