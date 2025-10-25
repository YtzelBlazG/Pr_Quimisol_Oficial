import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // RawKeyboardListener
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../shared/buttons/app_button.dart';

class AddLocationMapPage extends StatefulWidget {
  const AddLocationMapPage({super.key});

  @override
  State<AddLocationMapPage> createState() => _AddLocationMapPageState();
}

class _AddLocationMapPageState extends State<AddLocationMapPage> {
  // 🔐 Mapbox (usa .env en producción)
  static const String _mapboxToken =
      'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

  // 🌎 Centro inicial (Cochabamba)
  static const LatLng _initialTarget = LatLng(-17.3895, -66.1570);

  // 🗺️ Mapa
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  // 📍 Punto elegido
  double? _lat;
  double? _lng;

  // 📝 Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _submitting = false;
  bool _geocoding = false;

  // 📦 Panel deslizante
  final _dragCtrl = DraggableScrollableController();
  bool _expanded = false;

  // 🔎 Buscador combinado (Mapbox + Nominatim)
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _searchLoading = false;
  List<_PlaceSuggestion> _suggestions = [];
  final Map<String, List<_PlaceSuggestion>> _cache = {};
  int _selectedIndex = -1;
  int _reqCounter = 0;

  @override
  void initState() {
    super.initState();
    _dragCtrl.addListener(() {
      final exp = _dragCtrl.size >= 0.5;
      if (exp != _expanded) setState(() => _expanded = exp);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dirCtrl.dispose();
    _cityCtrl.dispose();
    _dragCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // =================== Mapa ===================

  void _onMapTap(TapPosition _, LatLng latLng) async {
    _setPoint(latLng);
    await _reverseFillMapbox(latLng.latitude, latLng.longitude);
    _softExpand();
  }

  Future<void> _useCenterAsPoint() async {
    final center = _mapController.camera.center;
    _setPoint(center);
    await _reverseFillMapbox(center.latitude, center.longitude);
    _softExpand();
  }

  void _setPoint(LatLng latLng) {
    _lat = latLng.latitude;
    _lng = latLng.longitude;
    _markers
      ..clear()
      ..add(
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: const Icon(Icons.place, size: 32, color: Colors.redAccent),
        ),
      );
    setState(() {});
  }

  Future<void> _reverseFillMapbox(double lat, double lng) async {
    setState(() => _geocoding = true);
    try {
      final info = await _reverseGeocodeMapbox(lat, lng);
      _dirCtrl.text = info['direccion'] ?? _dirCtrl.text;
      _cityCtrl.text = info['ciudad'] ?? _cityCtrl.text;
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<Map<String, String>> _reverseGeocodeMapbox(
    double lat,
    double lng,
  ) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
        '?access_token=$_mapboxToken&language=es&limit=1';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = (json['features'] as List?) ?? [];
      if (features.isNotEmpty) {
        final f = features.first as Map<String, dynamic>;
        final fullAddress = (f['place_name'] ?? '').toString();

        String city = '';
        final ctx = (f['context'] as List?) ?? [];
        for (final c in ctx) {
          final id = (c['id'] ?? '').toString();
          if (id.startsWith('place')) {
            city = (c['text'] ?? '').toString();
            break;
          }
        }
        if (city.isEmpty) city = (f['text'] ?? '').toString();

        return {'direccion': fullAddress, 'ciudad': city};
      }
    }
    return {'direccion': '', 'ciudad': ''};
  }

  // =================== Buscador combinado ===================

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _fetchSuggestionsCombined(q);
    });
  }

  Future<void> _fetchSuggestionsCombined(String raw) async {
    final query = raw.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
        _selectedIndex = -1;
      });
      return;
    }

    // cache
    final cacheKey = query.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null) {
      setState(() {
        _suggestions = cached;
        _searchLoading = false;
        _selectedIndex = -1;
      });
      return;
    }

    setState(() => _searchLoading = true);
    final int reqId = ++_reqCounter;

    // Proximidad: centro de cámara
    final bias = _mapController.camera.center;

    // Disparamos en paralelo
    final futures = await Future.wait<List<_PlaceSuggestion>>([
      _searchMapbox(query, bias),
      _searchNominatim(query, bias),
    ], eagerError: false);

    if (!mounted || reqId != _reqCounter) return;

    // Fusionar y rankear
    final merged = _mergeRank(futures.expand((x) => x).toList(), bias);

    // cachear
    _cache[cacheKey] = merged;

    setState(() {
      _suggestions = merged;
      _searchLoading = false;
      _selectedIndex = -1;
    });
  }

  Future<List<_PlaceSuggestion>> _searchMapbox(
      String query, LatLng bias) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?access_token=$_mapboxToken'
        '&autocomplete=true'
        '&language=es'
        '&limit=7'
        '&types=place,address,poi'
        '&proximity=${bias.longitude},${bias.latitude}'
        '&country=bo';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final feats = (data['features'] as List?) ?? [];
      return feats
          .map<_PlaceSuggestion>((f) {
            final m = (f as Map).cast<String, dynamic>();
            final coords = (m['geometry']?['coordinates'] as List?) ?? [];
            final lng =
                coords.length >= 2 ? (coords[0] as num).toDouble() : null;
            final lat =
                coords.length >= 2 ? (coords[1] as num).toDouble() : null;
            final title = (m['text'] ?? '').toString();
            final subtitle = (m['place_name'] ?? '').toString();
            return _PlaceSuggestion(
              id: (m['id'] ?? '').toString(),
              provider: 'mapbox',
              title: title,
              subtitle: subtitle,
              lat: lat,
              lng: lng,
            );
          })
          .where((p) => p.lat != null && p.lng != null)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_PlaceSuggestion>> _searchNominatim(
      String query, LatLng bias) async {
    // Nominatim pide User-Agent identificable
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=jsonv2&addressdetails=1&accept-language=es&limit=6'
        // Bias aproximado con viewbox y bounded=1 (opcional). Aquí lo dejamos sin recorte estricto.
        );
    try {
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'quimisol-app/1.0 (contact: soporte@quimisol.example)'
        },
      );
      if (resp.statusCode != 200) return [];
      final list = (jsonDecode(resp.body) as List?) ?? [];
      return list.map<_PlaceSuggestion>((e) {
        final m = (e as Map).cast<String, dynamic>();
        final lat = (num.tryParse((m['lat'] ?? '').toString()) ?? 0).toDouble();
        final lng = (num.tryParse((m['lon'] ?? '').toString()) ?? 0).toDouble();
        final disp = (m['display_name'] ?? '').toString();
        final addr = (m['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final city = (addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['state_district'] ??
                '')
            .toString();
        // título corto
        final title = city.isNotEmpty
            ? city
            : (addr['road'] ?? addr['neighbourhood'] ?? 'Lugar').toString();
        return _PlaceSuggestion(
          id: (m['osm_id'] ?? '').toString(),
          provider: 'nominatim',
          title: title,
          subtitle: disp,
          lat: lat,
          lng: lng,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<_PlaceSuggestion> _mergeRank(List<_PlaceSuggestion> items, LatLng bias) {
    // 1) dedupe por (título+lat+lng) aprox
    final seen = <String>{};
    final deduped = <_PlaceSuggestion>[];
    for (final p in items) {
      final key =
          '${p.title.toLowerCase()}|${(p.lat ?? 0).toStringAsFixed(4)},${(p.lng ?? 0).toStringAsFixed(4)}';
      if (seen.add(key)) deduped.add(p);
    }
    // 2) score por distancia + proveedor
    for (final p in deduped) {
      final d = _haversine(bias.latitude, bias.longitude, p.lat!, p.lng!);
      // Proveedor base: Mapbox un pelín preferido si empate
      final providerBonus = (p.provider == 'mapbox') ? -200.0 : 0.0;
      p.score = d + providerBonus; // menor = mejor
    }
    deduped.sort((a, b) => a.score.compareTo(b.score));
    return deduped;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // m
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    setState(() {
      _suggestions = [];
      _selectedIndex = -1;
    });
    FocusScope.of(context).unfocus();

    final lat = s.lat, lng = s.lng;
    if (lat == null || lng == null) return;

    final point = LatLng(lat, lng);
    _mapController.move(point, 15.0);
    _setPoint(point);

    // Completa campos
    _dirCtrl.text = s.subtitle;
    // Extract city rápido desde subtítulo si no vino en título
    String city = s.title;
    if (city.toLowerCase() == 'lugar' || city.isEmpty) {
      // intenta con coma
      final parts = s.subtitle.split(',');
      if (parts.length >= 2) city = parts[parts.length - 3].trim();
    }
    _cityCtrl.text = city;
    _softExpand();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _suggestions = [];
      _selectedIndex = -1;
    });
    FocusScope.of(context).requestFocus(_searchFocus);
  }

  // Navegación con teclado (↑/↓/Enter)
  void _handleSearchKey(RawKeyEvent event) {
    if (_suggestions.isEmpty) return;
    if (event is! RawKeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _suggestions.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1).clamp(-1, _suggestions.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _suggestions.length) {
        _selectSuggestion(_suggestions[_selectedIndex]);
      }
    }
  }

  // =================== Form ===================

  Future<void> _submit() async {
    if (_lat == null || _lng == null) {
      _snack(
          'Toca el mapa o usa el buscador / botón “Usar punto del centro” para seleccionar la ubicación');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final data = {
        'nombre': _nameCtrl.text.trim(),
        'direccion': _dirCtrl.text.trim(),
        'ciudad': _cityCtrl.text.trim(),
        'latitud': _lat,
        'longitud': _lng,
      };
      Modular.to.pop(data);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _softExpand() {
    if (!_expanded) {
      _dragCtrl
          .animateTo(
            0.35,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          )
          .catchError((_) {});
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    // Retícula central
    final centerReticle = IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Icon(
            Icons.add_location_alt,
            size: 28,
            color: (_lat == null) ? Colors.grey.shade400 : Colors.blueAccent,
          ),
        ),
      ),
    );

    // Tiles Mapbox (512px; zoomOffset:-1)
    final mapboxTileUrl =
        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$_mapboxToken';

    return Scaffold(
      appBar: AppBar(title: const Text("Agregar ubicación")),
      body: Stack(
        children: [
          // MAPA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialTarget,
              initialZoom: 12.5,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: mapboxTileUrl,
                tileSize: 512,
                zoomOffset: -1,
                userAgentPackageName: 'com.example.pr_quimisol_srl',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Retícula
          centerReticle,

          // BUSCADOR FLOTANTE
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Material(
              elevation: 10,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: RawKeyboardListener(
                  focusNode: _searchFocus,
                  onKey: _handleSearchKey,
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Buscar dirección o lugar...',
                            border: InputBorder.none,
                          ),
                          onChanged: _onSearchChanged,
                          onTap: () {
                            if (_searchCtrl.text.trim().length >= 2) {
                              _fetchSuggestionsCombined(_searchCtrl.text);
                            }
                          },
                        ),
                      ),
                      if (_searchLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (_searchCtrl.text.isNotEmpty && !_searchLoading)
                        IconButton(
                          tooltip: 'Limpiar',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close, color: Colors.black45),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SUGERENCIAS (overlay)
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 74,
              left: 14,
              right: 14,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (_, i) {
                      final p = _suggestions[i];
                      final selected = i == _selectedIndex;
                      return InkWell(
                        onTap: () => _selectSuggestion(p),
                        child: Container(
                          color:
                              selected ? const Color(0xFFF1F5F9) : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                p.provider == 'mapbox'
                                    ? Icons.map
                                    : Icons.public,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Botón “Usar punto del centro”
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton.extended(
              heroTag: 'useCenter',
              onPressed: _useCenterAsPoint,
              icon: const Icon(Icons.my_location),
              label: Row(
                children: [
                  const Text('Usar punto del centro'),
                  if (_geocoding) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  ],
                ],
              ),
            ),
          ),

          // Bottom sheet con formulario
          DraggableScrollableSheet(
            controller: _dragCtrl,
            initialChildSize: 0.22,
            minChildSize: 0.18,
            maxChildSize: 0.70,
            snap: true,
            snapSizes: const [0.22, 0.7],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Ubicación de sucursal",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: "Nombre ubicación",
                            hintText: "Ej: Sucursal Centro",
                            prefixIcon: Icon(Icons.flag),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Requerido"
                              : null,
                        ),
                        AnimatedCrossFade(
                          crossFadeState: _expanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 200),
                          firstChild: Column(
                            children: [
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _dirCtrl,
                                decoration: InputDecoration(
                                  labelText: "Dirección",
                                  hintText:
                                      "Se completa al elegir el punto o una sugerencia",
                                  prefixIcon: const Icon(Icons.place),
                                  suffixIcon: _geocoding
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? "Requerido"
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cityCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Ciudad",
                                  hintText:
                                      "Se completa al elegir el punto o una sugerencia",
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? "Requerido"
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  (_lat == null || _lng == null)
                                      ? "Toca el mapa o usa el buscador para fijar el punto"
                                      : "Lat: ${_lat!.toStringAsFixed(6)}  •  Lng: ${_lng!.toStringAsFixed(6)}",
                                  style: TextStyle(
                                    color: (_lat == null)
                                        ? Colors.red
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: "Agregar",
                                icon: Icons.check,
                                isLoading: _submitting,
                                onPressed: _submitting ? null : _submit,
                              ),
                            ],
                          ),
                          secondChild: const SizedBox(height: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ======= Modelo interno de sugerencia =======
class _PlaceSuggestion {
  _PlaceSuggestion({
    required this.id,
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String provider; // 'mapbox' | 'nominatim'
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;

  double score = 0; // para ranking (menor = mejor)
}
