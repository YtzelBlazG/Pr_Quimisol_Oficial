import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';
import '../../../../shared/buttons/app_button.dart';
import '../widgets/login_header.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/services/postgresql/person/person_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _nombre;
  String? _correo;
  String? _telefono; // ✅ teléfono ahora sí viene de PersonService
  int? _idPersona;

  bool _loading = true;
  bool _loadingUbicaciones = true;

  List<Map<String, dynamic>> _ubicaciones = [];

  static const String _baseUrl = "http://localhost:3005";
  late final PersonService _personService = PersonService(baseUrl: _baseUrl);

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();
    final idPersona = await AuthStorage.getIdPersona();

    setState(() {
      _nombre = nombre;
      _correo = correo;
      _idPersona = idPersona;
      _loading = false;
    });

    if (idPersona != null) {
      await _fetchTelefono(idPersona);
      await _fetchUbicaciones(idPersona);
    } else {
      setState(() => _loadingUbicaciones = false);
    }
  }

  Future<void> _fetchTelefono(int idPersona) async {
    try {
      final person = await _personService.getPerson(idPersona);
      if (mounted) {
        setState(() {
          _telefono = person?.phone ?? '';
        });
      }
    } catch (e) {
      print("❌ Error fetch teléfono: $e");
    }
  }

  Future<void> _fetchUbicaciones(int idPersona) async {
    setState(() => _loadingUbicaciones = true);
    try {
      final uri = Uri.parse("$_baseUrl/ubicaciones/$idPersona");
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);

        setState(() {
          _ubicaciones = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() => _ubicaciones = []);
      }
    } catch (e) {
      print("❌ Error fetch ubicaciones: $e");
      setState(() => _ubicaciones = []);
    } finally {
      if (mounted) setState(() => _loadingUbicaciones = false);
    }
  }

  Future<void> _relogin() async {
    await AuthStorage.clear();
    if (!mounted) return;
    Modular.to.pushReplacementNamed('/auth/login');
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

  Widget _ubicacionItem(Map<String, dynamic> u) {
    final nombre = (u['nombre'] ?? '').toString().trim();
    final ciudad = (u['ciudad'] ?? '').toString().trim();
    final direccion = (u['direccion'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (nombre.isNotEmpty
                      ? nombre
                      : (direccion.isEmpty ? '(sin nombre)' : direccion)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                if (direccion.isNotEmpty)
                  Text(
                    direccion,
                    style: const TextStyle(color: Colors.black87),
                  ),
                Text(
                  ciudad.isEmpty ? 'Ciudad: (completar)' : 'Ciudad: $ciudad',
                  style: TextStyle(
                    color: ciudad.isEmpty ? Colors.redAccent : Colors.black54,
                    fontWeight: ciudad.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ubicacionesSection() {
    if (_loadingUbicaciones) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_idPersona == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'No se pudo determinar tu usuario para cargar ubicaciones.',
              style: TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: "Volver a iniciar sesión",
              icon: Icons.logout,
              onPressed: _relogin,
            ),
          ],
        ),
      );
    }

    if (_ubicaciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Sin ubicaciones registradas.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _ubicaciones.map(_ubicacionItem).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Palette.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Mis ubicaciones',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ubicacionesSection(),
                        const SizedBox(height: 8),
                        const Text(
                          'Los campos en rojo deben completarse.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: "Editar",
                          icon: Icons.edit,
                          onPressed: () {
                            Modular.to.pushNamed('/auth/register').then((
                              value,
                            ) {
                              if (value == true) {
                                _loadSessionData(); // 🔄 recarga datos
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: "Refrescar ubicaciones",
                          icon: Icons.refresh,
                          onPressed: _idPersona == null
                              ? null
                              : () => _fetchUbicaciones(_idPersona!),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
