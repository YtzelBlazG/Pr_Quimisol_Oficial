// lib/features/locations/screens/add_location_map_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';

/// ==============================
/// CONFIG MAPBOX
/// ==============================
const String MAPBOX_TOKEN =
    'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

/// Forzar búsqueda y reverse a Bolivia
const String _MB_COUNTRY = 'bo';

/// BBox aproximado de Bolivia [minLon, minLat, maxLon, maxLat]
const List<double> _BOLIVIA_BBOX = [-69.645, -22.9, -57.45, -9.68];

/// Tweaks para consumo
const _reverseDebounceMs = 600; // menos llamadas al mover mapa
const _minMoveMetersToReverse = 25.0; // umbral por distancia

/// ==============================
/// PAGE
/// ==============================
class AddLocationMapPage extends StatefulWidget {
  final String baseUrl;
  const AddLocationMapPage({super.key, required this.baseUrl});

  @override
  State<AddLocationMapPage> createState() => _AddLocationMapPageState();
}

class _AddLocationMapPageState extends State<AddLocationMapPage> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController(); // ← Nombre de ubicación

  // Estado UI
  LatLng _center = const LatLng(-17.3895, -66.1568); // Cochabamba por defecto
  bool _loadingAddr = false;
  String _direccion = '';
  String _ciudad = ''; // ← aquí guardaremos el DEPARTAMENTO

  // Sugerencias
  Timer? _searchDebouncer;
  List<_PlaceSug> _sugs = [];
  bool _showSug = false;

  // Cache de sugerencias (30s)
  final _searchCache = <String, _CacheEntry<List<_PlaceSug>>>{};
  static const _searchCacheTtl = Duration(seconds: 30);

  // Mi ubicación actual
  LatLng? _myPos;
  bool _locating = false;

  // Guardado
  bool _saving = false;

  // Reverse geocode
  Timer? _moveDebouncer;
  LatLng? _lastReversePoint;
  final _dist = const Distance();

  @override
  void initState() {
    super.initState();
    // Centrar desde MI ubicación al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToMyLocation();
    });
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _moveDebouncer?.cancel();
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
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
      // Silencioso: mantenemos la vista por defecto
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _animateTo(LatLng p, {double zoom = 15}) {
    _mapController.move(p, zoom);
    setState(() => _center = p);
  }

  // ==========================
  // MAPBOX GEOCODING (solo Bolivia)
  // ==========================
  Future<List<_PlaceSug>> _forwardGeocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // Cache 30s (clave incluye texto)
    final cacheKey = 'bo|$q';
    final hit = _searchCache[cacheKey];
    if (hit != null && DateTime.now().difference(hit.ts) < _searchCacheTtl) {
      return hit.data;
    }

    final params = <String, String>{
      'access_token': MAPBOX_TOKEN,
      'autocomplete': 'true',
      'language': 'es',
      'limit': '5',
      'country': _MB_COUNTRY, // ← SIEMPRE Bolivia
      'bbox': _BOLIVIA_BBOX.join(','), // ← recortar a Bolivia
    };

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/${Uri.encodeComponent(q)}.json',
      params,
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final feats = (data['features'] as List?) ?? [];
    final out = feats
        .map<_PlaceSug>((f) {
          final coords = f['center'] as List?;
          final text = f['place_name']?.toString() ?? '';
          // AHORA: obtenemos el DEPARTAMENTO
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

    _searchCache[cacheKey] = _CacheEntry(out);
    return out;
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
        {
          'access_token': MAPBOX_TOKEN,
          'language': 'es',
          'limit': '1',
          'country': _MB_COUNTRY, // ← también forzamos a Bolivia
          'bbox': _BOLIVIA_BBOX.join(','), // ← y recortamos
        },
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
            _ciudad = depto; // aquí guardas SOLO el departamento
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

  // ==========================
  // GUARDAR
  // ==========================
  Future<void> _onSave() async {
    if (_saving) return;
    final idPersona = await AuthStorage.getIdPersona();
    if (idPersona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para guardar ubicaciones.'),
        ),
      );
      return;
    }
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para la ubicación.')),
      );
      return;
    }
    if (_direccion.trim().isEmpty || _ciudad.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección válida.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final svc = LocationsService(baseUrl: widget.baseUrl);
      await svc.create(
        idPersona: idPersona,
        nombre: _nombreCtrl.text.trim(), // ← nombre personalizado
        ciudad: _ciudad, // ← aquí va el DEPARTAMENTO
        direccion: _direccion,
        latitud: _center.latitude,
        longitud: _center.longitude,
      );

      await AuthStorage.refreshFromDatabase(
        idPersona: idPersona,
        baseUrl: widget.baseUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación guardada ✅')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.fieldBg,
      appBar: AppBar(
        title: const Text('Agregar ubicación'),
        backgroundColor: const Color.fromARGB(255, 248, 156, 254),
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onPositionChanged: (camera, hasGesture) {
                final c = camera.center;
                if (c != null) {
                  setState(() => _center = c);
                  _moveDebouncer?.cancel();
                  _moveDebouncer = Timer(
                    const Duration(milliseconds: _reverseDebounceMs),
                    () => _reverseGeocode(_center),
                  );
                }
              },
              onTap: (tapPos, latLng) async {
                _animateTo(latLng, zoom: _mapController.camera.zoom);
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
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Buscador (bonito, siempre Bolivia)
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Builder(
              builder: (context) {
                const accent = Color(0xFFF48FB1); // rosa suave

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(28),
                      shadowColor: Colors.black26,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                                onSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Buscar dirección, zona o lugar en Bolivia…',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchCtrl.text.isNotEmpty)
                              IconButton(
                                tooltip: 'Limpiar búsqueda',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchCtrl.clear();
                                    _sugs = [];
                                    _showSug = false;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_showSug)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black26,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _sugs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = _sugs[i];
                              return ListTile(
                                leading: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: s.city != null && s.city!.isNotEmpty
                                    ? Text(
                                        s.city!, // aquí ya es el departamento
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      )
                                    : const Text(
                                        'Bolivia',
                                        style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                        ),
                                      ),
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
                      ),
                  ],
                );
              },
            ),
          ),

          // FAB mi ubicación
          Positioned(
            right: 16,
            bottom: 260,
            child: FloatingActionButton(
              heroTag: 'geo',
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

          // Modal inferior (incluye Nombre de ubicación)
          _BottomCard(
            nombreCtrl: _nombreCtrl,
            direccion: _direccion,
            ciudad: _ciudad,
            loading: _loadingAddr,
            saving: _saving,
            onSave: _onSave,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta inferior con datos y botón Guardar
class _BottomCard extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final String direccion;
  final String ciudad; // departamento
  final bool loading;
  final bool saving;
  final VoidCallback onSave;

  const _BottomCard({
    required this.nombreCtrl,
    required this.direccion,
    required this.ciudad,
    required this.loading,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
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

            // Nombre de ubicación
            TextField(
              controller: nombreCtrl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Nombre de la ubicación',
                hintText: 'Ej: Sucursal La Paz, Sucursal 1',
                prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: loading
                      ? const LinearProgressIndicator(minHeight: 6)
                      : Text(
                          direccion.isEmpty
                              ? 'Toca el mapa o busca una dirección'
                              : direccion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.apartment_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ciudad.isEmpty ? 'Departamento' : ciudad,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Guardando…' : 'Guardar ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 244, 144, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo simple para sugerencias
class _PlaceSug {
  final String name;
  final String? city; // aquí guardamos el DEPARTAMENTO
  final LatLng? coord;
  _PlaceSug({required this.name, this.city, this.coord});
}

/// Cache entry genérico
class _CacheEntry<T> {
  final T data;
  final DateTime ts;
  _CacheEntry(this.data) : ts = DateTime.now();
}
