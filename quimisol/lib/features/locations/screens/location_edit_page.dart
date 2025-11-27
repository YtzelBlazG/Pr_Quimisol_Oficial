// lib/features/locations/screens/location_viewer_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';

/// Usa tu token real (o llámalo desde una constante compartida)
const String MAPBOX_TOKEN =
    'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

class LocationViewerPage extends StatefulWidget {
  final int idubicacion;
  final String nombre;
  final String direccion;
  final String ciudad; // aquí viene el DEPARTAMENTO
  final double latitud;
  final double longitud;

  const LocationViewerPage({
    super.key,
    required this.idubicacion,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.latitud,
    required this.longitud,
  });

  /// Creador seguro desde argumentos de ruta (los parsea aquí, como pediste)
  static Widget fromArgs() {
    final data = Modular.args.data;
    if (data is! Map) {
      return const _BadArgsPage(reason: 'No se recibieron argumentos.');
    }

    // ---- parse seguro ----
    int? idubicacion;
    final rawId = data['idubicacion'];
    if (rawId is int) idubicacion = rawId;
    if (rawId is String) idubicacion = int.tryParse(rawId);

    String nombre = (data['nombre'] ?? '').toString().trim();
    String direccion = (data['direccion'] ?? '').toString().trim();
    String ciudad = (data['ciudad'] ?? '').toString().trim();

    double? lat;
    double? lng;
    final rawLat = data['latitud'];
    final rawLng = data['longitud'];
    if (rawLat is num) lat = rawLat.toDouble();
    if (rawLat is String) lat = double.tryParse(rawLat);
    if (rawLng is num) lng = rawLng.toDouble();
    if (rawLng is String) lng = double.tryParse(rawLng);

    if (idubicacion == null) {
      return const _BadArgsPage(reason: 'Falta idubicacion.');
    }
    if (lat == null || lng == null) {
      return const _BadArgsPage(reason: 'Coordenadas inválidas.');
    }

    return LocationViewerPage(
      idubicacion: idubicacion,
      nombre: nombre.isEmpty ? 'Ubicación' : nombre,
      direccion: direccion.isEmpty ? 'Sin dirección' : direccion,
      ciudad: ciudad,
      latitud: lat,
      longitud: lng,
    );
  }

  @override
  State<LocationViewerPage> createState() => _LocationViewerPageState();
}

class _LocationViewerPageState extends State<LocationViewerPage> {
  final _mapController = MapController();

  // Edit mode
  bool _editing = false;
  bool _saving = false;
  bool _loadingAddr = false;

  // Campos
  late LatLng _center;
  late String _direccion;
  late String _ciudad; // DEPARTAMENTO
  late TextEditingController _nombreCtrl;

  // Search
  final _searchCtrl = TextEditingController();
  Timer? _searchDebouncer;
  List<_PlaceSug> _sugs = [];
  bool _showSug = false;

  // Reverse geocode control
  final _dist = const Distance();
  Timer? _moveDebouncer;
  static const _reverseDebounceMs = 600;
  static const _minMoveMetersToReverse = 25.0;
  LatLng? _lastReversePoint;

  // Mi ubicación actual
  LatLng? _myPos;
  bool _locating = false;

  // Servicios
  late final LocationsService _svc;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.latitud, widget.longitud);
    _direccion = widget.direccion;
    _ciudad = widget.ciudad; // ya viene como depto desde BD
    _nombreCtrl = TextEditingController(text: widget.nombre);
    _svc = LocationsService(baseUrl: Env.apiBaseUrl);
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _moveDebouncer?.cancel();
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _editing = !_editing);
    if (_editing) {
      // Nada extra; el usuario puede mover el mapa y buscar
    } else {
      // Si cancela edición, restaurar a valores originales
      _center = LatLng(widget.latitud, widget.longitud);
      _direccion = widget.direccion;
      _ciudad = widget.ciudad;
      _nombreCtrl.text = widget.nombre;
      _mapController.move(_center, _mapController.camera.zoom);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para la ubicación.')),
      );
      return;
    }
    if (_direccion.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección válida.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _svc.update(
        idUbicacion: widget.idubicacion,
        nombre: _nombreCtrl.text.trim(),
        ciudad: _ciudad, // aquí estamos guardando el DEPARTAMENTO
        direccion: _direccion,
        latitud: _center.latitude,
        longitud: _center.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación actualizada ✅')));

      setState(() {
        _editing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================
  // Permisos + ubicación actual
  // ==========================
  Future<bool> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el GPS para ubicarte.')),
      );
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final ok = await _ensureLocationReady();
      if (!ok) return;

      // Espera intencional de 2s para permitir fijar una ubicación más precisa
      await Future.delayed(const Duration(seconds: 2));

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      final here = LatLng(pos.latitude, pos.longitude);

      _myPos = here;
      _animateTo(here, zoom: 15.5);
      await _reverseGeocode(here);
    } catch (_) {
      // Silencioso
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ==========================
  // GEOCODING
  // ==========================
  Future<List<_PlaceSug>> _forwardGeocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/${Uri.encodeComponent(q)}.json',
      {
        'access_token': MAPBOX_TOKEN,
        'autocomplete': 'true',
        'language': 'es',
        'limit': '6',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final feats = (data['features'] as List?) ?? [];
    return feats
        .map<_PlaceSug>((f) {
          final coords = f['center'] as List?;
          final text = f['place_name']?.toString() ?? '';
          // Aquí tomamos el DEPARTAMENTO
          final depto = _getDepartamentoFromContext(f);
          return _PlaceSug(
            name: text,
            city: depto, // city = departamento
            coord: (coords != null && coords.length == 2)
                ? LatLng(
                    (coords[1] as num).toDouble(),
                    (coords[0] as num).toDouble(),
                  )
                : null,
          );
        })
        .where((s) => s.coord != null)
        .toList();
  }

  Future<void> _reverseGeocode(LatLng p) async {
    // Si no nos movimos lo suficiente, evita llamada
    if (_lastReversePoint != null) {
      final d = _dist(p, _lastReversePoint!);
      if (d < _minMoveMetersToReverse) return;
    }
    _lastReversePoint = p;

    setState(() => _loadingAddr = true);
    try {
      final uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/${p.longitude},${p.latitude}.json',
        {'access_token': MAPBOX_TOKEN, 'language': 'es', 'limit': '1'},
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final feats = (data['features'] as List?) ?? [];
        if (feats.isNotEmpty) {
          final f = feats.first;
          final placeName = f['place_name']?.toString() ?? '';
          // DEPARTAMENTO desde el contexto
          final depto = _getDepartamentoFromContext(f) ?? '';
          setState(() {
            _direccion = placeName;
            _ciudad = depto; // solo departamento
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  /// Extrae el **departamento** desde el contexto de Mapbox.
  /// - Prioriza `region.*` (departamento).
  /// - Si no hay `region.*`, usa `place.*` como fallback.
  /// - Si nada, usa el `text` del feature.
  String? _getDepartamentoFromContext(Map f) {
    final ctx = (f['context'] as List?) ?? [];
    String? depto;

    // 1) Primero: region.* (departamento)
    for (final c in ctx) {
      final id = (c['id'] ?? '').toString();
      if (id.startsWith('region.')) {
        depto = c['text']?.toString();
        break;
      }
    }

    // 2) Si no hay region, intenta con place.* (ciudad/gran área)
    if (depto == null) {
      for (final c in ctx) {
        final id = (c['id'] ?? '').toString();
        if (id.startsWith('place.')) {
          depto = c['text']?.toString();
          break;
        }
      }
    }

    // 3) Último fallback: el texto principal del feature
    depto ??= f['text']?.toString();

    return depto;
  }

  void _animateTo(LatLng p, {double? zoom}) {
    _mapController.move(p, zoom ?? _mapController.camera.zoom);
    setState(() => _center = p);
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar ubicación' : widget.nombre),
        backgroundColor: const Color.fromARGB(255, 250, 150, 235),
        actions: [
          if (!_editing)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: _toggleEdit,
            ),
          if (_editing)
            IconButton(
              tooltip: 'Guardar',
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _saving ? null : _save,
            ),
          if (_editing)
            IconButton(
              tooltip: 'Cancelar',
              icon: const Icon(Icons.close),
              onPressed: _saving ? null : _toggleEdit,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) {
                if (!_editing) return;
                final c = camera.center;
                if (c != null) {
                  _moveDebouncer?.cancel();
                  _moveDebouncer = Timer(
                    const Duration(milliseconds: _reverseDebounceMs),
                    () => _reverseGeocode(c),
                  );
                  setState(() => _center = c);
                }
              },
              onTap: (tapPos, latLng) async {
                if (!_editing) return;
                _animateTo(latLng);
                await _reverseGeocode(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}?access_token=$MAPBOX_TOKEN',
                tileProvider: CancellableNetworkTileProvider(),
                userAgentPackageName: 'quimisol.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 42,
                    height: 42,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Buscador (solo en modo edición)
          if (_editing)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Column(
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(28),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onChanged: (txt) {
                        _searchDebouncer?.cancel();
                        _searchDebouncer = Timer(
                          const Duration(milliseconds: 320),
                          () async {
                            final sugs = await _forwardGeocode(txt);
                            if (!mounted) return;
                            setState(() {
                              _sugs = sugs;
                              _showSug = sugs.isNotEmpty;
                            });
                          },
                        );
                      },
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar dirección…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_showSug)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 8, color: Colors.black12),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _sugs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _sugs[i];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: s.city != null ? Text(s.city!) : null,
                            onTap: () async {
                              setState(() {
                                _showSug = false;
                                _searchCtrl.text = s.name;
                              });
                              _animateTo(s.coord!, zoom: 16);
                              await _reverseGeocode(s.coord!);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // FAB mi ubicación -> SOLO cuando estás editando
          if (_editing)
            Positioned(
              right: 16,
              bottom: 260,
              child: FloatingActionButton(
                heroTag: 'geo_view',
                backgroundColor: Colors.white,
                foregroundColor: Palette.primary,
                onPressed: _goToMyLocation,
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

          // Tarjeta inferior con info / inputs
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_mall_directory_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _editing
                            ? TextField(
                                controller: _nombreCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Nombre de la ubicación',
                                  hintText: 'Ej: Sucursal La Paz',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              )
                            : Text(
                                _nombreCtrl.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Dirección
                  Row(
                    children: [
                      const Icon(Icons.map_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _loadingAddr
                            ? const LinearProgressIndicator(minHeight: 6)
                            : Text(
                                _direccion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Departamento + coords
                  Row(
                    children: [
                      const Icon(Icons.apartment_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ciudad.isEmpty ? 'Departamento' : _ciudad,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  

                  const SizedBox(height: 12),

                  // Botones inferiores cuando NO estás editando
                  if (!_editing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleEdit,
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: const Text('Editar ubicación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 245, 135, 221),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.primary,
                          side: BorderSide(color: Palette.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo simple para sugerencias
class _PlaceSug {
  final String name;
  final String? city; // aquí usamos el DEPARTAMENTO
  final LatLng? coord;
  _PlaceSug({required this.name, this.city, this.coord});
}

/// Página mínima para errores de argumentos
class _BadArgsPage extends StatelessWidget {
  final String reason;
  const _BadArgsPage({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación')),
      body: Center(
        child: Text(
          'No se pudo abrir la ubicación.\n$reason',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
