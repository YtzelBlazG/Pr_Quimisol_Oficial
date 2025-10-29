import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // RawKeyboardListener
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:quimisol/features/locations/models/place_suggestions.dart';

import '../services/geocoding_service.dart';
import '../services/place_search_service.dart';
import '../widgets/map_center_reticle.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/place_suggestions_overlay.dart';
import '../widgets/location_bottom_sheet_form.dart';

class AddLocationMapPage extends StatefulWidget {
  const AddLocationMapPage({super.key});

  @override
  State<AddLocationMapPage> createState() => _AddLocationMapPageState();
}

class _AddLocationMapPageState extends State<AddLocationMapPage> {
  // 🔐 Mapbox (en producción: pásalo por constructor o dotenv)
  static const String _defaultMapboxToken =
      'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

  // 🌎 Centro inicial (Cochabamba)
  static const LatLng _initialTarget = LatLng(-17.3895, -66.1570);

  // Servicios
  late final GeocodingService _geocoding = GeocodingService(
    mapboxToken: _defaultMapboxToken,
  );
  late final PlaceSearchService _search = PlaceSearchService(
    mapboxToken: _defaultMapboxToken,
  );

  // Mapa
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  // Punto elegido
  double? _lat;
  double? _lng;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _submitting = false;
  bool _geocodingBusy = false;

  // Bottom sheet controller
  final _dragCtrl = DraggableScrollableController();
  bool _expanded = false;

  // Buscador
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _searchLoading = false;
  List<PlaceSuggestion> _suggestions = [];
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
    await _reverseFill(latLng.latitude, latLng.longitude);
    _softExpand();
  }

  Future<void> _useCenterAsPoint() async {
    final center = _mapController.camera.center;
    _setPoint(center);
    await _reverseFill(center.latitude, center.longitude);
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

  Future<void> _reverseFill(double lat, double lng) async {
    setState(() => _geocodingBusy = true);
    try {
      final info = await _geocoding.reverseGeocodeMapbox(lat: lat, lng: lng);
      _dirCtrl.text = info['direccion'] ?? _dirCtrl.text;
      _cityCtrl.text = info['ciudad'] ?? _cityCtrl.text;
    } finally {
      if (mounted) setState(() => _geocodingBusy = false);
    }
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

    setState(() => _searchLoading = true);
    final int reqId = ++_reqCounter;

    final bias = _mapController.camera.center;
    final list = await _search.fetchCombined(query, bias);

    if (!mounted || reqId != _reqCounter) return;

    setState(() {
      _suggestions = list;
      _searchLoading = false;
      _selectedIndex = -1;
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
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

    _dirCtrl.text = s.subtitle;
    String city = s.title;
    if (city.toLowerCase() == 'lugar' || city.isEmpty) {
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
        _selectedIndex = (_selectedIndex - 1).clamp(
          -1,
          _suggestions.length - 1,
        );
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
        'Toca el mapa o usa el buscador / botón “Usar punto del centro” para seleccionar la ubicación',
      );
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
    final centerReticle = MapCenterReticle(active: _lat != null);

    // Tiles Mapbox (512px; zoomOffset:-1)
    final mapboxTileUrl =
        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$_defaultMapboxToken';

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
            child: LocationSearchBar(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              searchLoading: _searchLoading,
              onChanged: (v) {
                if (v.trim().length >= 2) {
                  _onSearchChanged(v);
                } else {
                  _clearSearch();
                }
              },
              onKey: _handleSearchKey,
              onClear: _clearSearch,
            ),
          ),

          // SUGERENCIAS (overlay)
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 74,
              left: 14,
              right: 14,
              child: PlaceSuggestionsOverlay(
                suggestions: _suggestions,
                selectedIndex: _selectedIndex,
                onTapItem: _selectSuggestion,
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
                  if (_geocodingBusy) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: LocationBottomSheetForm(
                    formKey: _formKey,
                    nameCtrl: _nameCtrl,
                    dirCtrl: _dirCtrl,
                    cityCtrl: _cityCtrl,
                    lat: _lat,
                    lng: _lng,
                    expanded: _expanded,
                    isSubmitting: _submitting,
                    isGeocoding: _geocodingBusy,
                    onSubmit: _submit,
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
