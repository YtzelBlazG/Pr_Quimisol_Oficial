import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/theme/palette.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/rounded_card.dart';
import '../../../../shared/buttons/app_button.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/services/postgresql/locations/locations_service.dart';
import '../../../../core/services/postgresql/person/person_service.dart';
import '../../../../core/services/postgresql/user/user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = true;
  int? _idPersona;

  // Lista local para mostrar en UI
  final List<Map<String, String>> _ubicaciones = [];

  // 🔧 API base
  static const String _baseUrl = "http://10.192.87.85:3005";
  late final LocationsService _locationsService = LocationsService(
    baseUrl: _baseUrl,
  );
  late final PersonService _personaService = PersonService(
    baseUrl: _baseUrl,
  ); // 👈 corregido
  late final UserService _userService = UserService(baseUrl: _baseUrl);

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();
    final idPersona = await AuthStorage.getIdPersona();

    _nameController.text = nombre ?? '';
    _emailController.text = correo ?? '';
    _idPersona = idPersona;

    // ✅ cargar teléfono y ubicaciones de BD
    if (_idPersona != null) {
      try {
        final person = await _personaService.getPerson(_idPersona!);
        if (person != null) {
          _phoneController.text = person.phone ?? '';
        }
      } catch (e) {
        print("❌ Error cargando persona: $e");
      }

      await _fetchUbicaciones(_idPersona!);
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _fetchUbicaciones(int idPersona) async {
    try {
      final ubicaciones = await _locationsService.listLocations(idPersona);

      setState(() {
        _ubicaciones
          ..clear()
          ..addAll(
            ubicaciones.map((u) {
              final nombre = (u['nombre'] ?? '').toString();
              final direccion = (u['direccion'] ?? '').toString();
              final ciudad = (u['ciudad'] ?? '').toString();
              final lat = u['latitud']?.toString();
              final lng = u['longitud']?.toString();

              return {
                'titulo': nombre.isNotEmpty ? nombre : 'Ubicación',
                'detalle': [
                  if (direccion.isNotEmpty) direccion,
                  if (ciudad.isNotEmpty) '• $ciudad',
                  if (lat != null && lng != null) '• ($lat, $lng)',
                ].join(' '),
              };
            }),
          );
      });
    } catch (e) {
      print("❌ Error al cargar ubicaciones: $e");
      setState(() {
        _ubicaciones.clear();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _missingNombre => _nameController.text.trim().isEmpty;
  bool get _missingCorreo => _emailController.text.trim().isEmpty;
  bool get _missingTelefono => _phoneController.text.trim().isEmpty;
  bool get _missingUbicaciones => _ubicaciones.isEmpty;

  OutlineInputBorder _border({required bool missing}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: missing ? Colors.redAccent : Colors.grey.shade300,
        width: 1,
      ),
    );
  }

  Future<void> _save() async {
    if (_idPersona == null) return;

    try {
      // 🔹 actualizar persona (nombre y teléfono)
      final updatedPerson = await _personaService.updatePerson(
        id: _idPersona!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // 🔹 actualizar usuario (correo)
      await _userService.updateUserByPersona(
        _idPersona!,
        correo: _emailController.text.trim(),
      );

      // 🔹 guardar también en storage (con teléfono incluido ✅)
      await AuthStorage.saveUser(
        nombre: _nameController.text.trim(),
        correo: _emailController.text.trim(),
        telefono: _phoneController.text.trim(), // 👈 agrega esto
        idPersona: _idPersona,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos guardados ✅')));
      Modular.to.pop(true);
    } catch (e) {
      print("❌ Error actualizando perfil: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en servidor: $e')));
    }
  }

  Future<void> _addUbicacion() async {
    final result = await Modular.to.pushNamed<Map>('/locations/add');
    if (result == null) return;

    final nombre = (result['nombre'] ?? '').toString();
    final direccion = (result['direccion'] ?? '').toString();
    final ciudad = (result['ciudad'] ?? '').toString();
    final lat = (result['latitud'] as num?)?.toDouble();
    final lng = (result['longitud'] as num?)?.toDouble();

    if (_idPersona != null) {
      try {
        await _locationsService.createLocation(
          idPersona: _idPersona!,
          nombre: nombre,
          ciudad: ciudad,
          direccion: direccion,
          latitud: lat,
          longitud: lng,
        );

        await _fetchUbicaciones(_idPersona!);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ubicación creada ✅')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar en servidor: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se agregó localmente. Inicia sesión de nuevo para guardar en el servidor.',
          ),
        ),
      );
    }
  }

  void _removeUbicacion(int index) {
    setState(() {
      _ubicaciones.removeAt(index);
    });
  }

  Widget _ubicacionItem(int index, Map<String, String> u) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u['titulo'] ?? 'Ubicación',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  u['detalle'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeUbicacion(index),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Palette.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.pop(),
        ),
      ),
      body: GradientBackground(
        child: Center(
          child: RoundedCard(
            child: _loading
                ? const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nombre
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Nombre completo',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Palette.primary,
                            ),
                            enabledBorder: _border(missing: _missingNombre),
                            focusedBorder: _border(missing: _missingNombre),
                            helperText: _missingNombre
                                ? 'Completa tu nombre'
                                : null,
                            helperStyle: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Correo
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Correo',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Palette.primary,
                            ),
                            enabledBorder: _border(missing: _missingCorreo),
                            focusedBorder: _border(missing: _missingCorreo),
                            helperText: _missingCorreo
                                ? 'Completa tu correo'
                                : null,
                            helperStyle: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Teléfono
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Teléfono',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Palette.primary,
                            ),
                            enabledBorder: _border(missing: _missingTelefono),
                            focusedBorder: _border(missing: _missingTelefono),
                            helperText: _missingTelefono
                                ? 'Completa tu teléfono'
                                : null,
                            helperStyle: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Ubicaciones
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _missingUbicaciones
                                  ? Colors.redAccent.withOpacity(0.35)
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Palette.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ubicaciones',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              if (_missingUbicaciones)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    'No tienes ubicaciones registradas. Agrega al menos una.',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ..._ubicaciones.asMap().entries.map(
                                (e) => _ubicacionItem(e.key, e.value),
                              ),
                              OutlinedButton.icon(
                                onPressed: _addUbicacion,
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                  color: Palette.primary,
                                ),
                                label: const Text(
                                  'AGREGAR UBICACIÓN',
                                  style: TextStyle(
                                    color: Palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Palette.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        AppButton(
                          label: 'GUARDAR CAMBIOS',
                          onPressed: _save,
                          isLoading: false,
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
