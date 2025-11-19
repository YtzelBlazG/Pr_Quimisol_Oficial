// lib/features/distributor/distributor_map/screens/location_route_page.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

/// MISMO TOKEN QUE USAS EN AddLocationMapPage
const String MAPBOX_TOKEN =
    'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

class LocationRoutePage extends StatefulWidget {
  final int idPedido;
  final int idubicacion;
  final String nombre;
  final double latitud;
  final double longitud;
  final bool autoStartTracking;

  const LocationRoutePage({
    super.key,
    required this.idPedido,
    required this.idubicacion,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.autoStartTracking = false,
  });

  @override
  State<LocationRoutePage> createState() => _LocationRoutePageState();
}

class _LocationRoutePageState extends State<LocationRoutePage> {
  final MapController _mapController = MapController();

  LatLng? _myPos;
  late LatLng _dest;

  bool _loading = true;
  String? _error;

  List<LatLng> _routePoints = [];
  double? _distanceKm;
  double? _durationMin;

  bool _mapFitted = false; // para no llamar fitBounds antes de tiempo

  // 🔹 tracking
  bool _enCamino = false;
  Timer? _trackingTimer;

  String get _baseUrl => Env.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _dest = LatLng(widget.latitud, widget.longitud);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _init();

      // si quisieras que arranque solo al entrar, puedes activar esto:
      if (widget.autoStartTracking && mounted) {
        _marcarUbicacionEnCaminoYEmpezarTracking();
      }
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final ok = await _ensureLocationReady();
      if (!ok) {
        setState(() {
          _error = 'Activa el GPS y otorga permisos de ubicación.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _myPos = LatLng(pos.latitude, pos.longitude);

      await _fetchRoute(); // primera ruta
    } catch (e) {
      setState(() {
        _error = 'No se pudo obtener tu ubicación: $e';
        _loading = false;
      });
    }
  }

  Future<bool> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el GPS para mostrar la ruta.')),
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

  /// Llama a Mapbox Directions y arma la ruta.
  Future<void> _fetchRoute({bool silent = false}) async {
    if (_myPos == null) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _mapFitted = false;
      });
    } else {
      _error = null;
      _mapFitted = false;
    }

    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${_myPos!.longitude},${_myPos!.latitude};'
      '${_dest.longitude},${_dest.latitude}'
      '?geometries=polyline&overview=full&language=es&access_token=$MAPBOX_TOKEN',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _error = 'Error al obtener la ruta (${res.statusCode}).';
          if (!silent) _loading = false;
        });
        return;
      }

      final data = jsonDecode(res.body);
      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'No se encontró una ruta disponible.';
          if (!silent) _loading = false;
        });
        return;
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as String;
      final distanceMeters = (route['distance'] ?? 0) as num;
      final durationSeconds = (route['duration'] ?? 0) as num;

      final points = _decodePolyline(geometry);

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _distanceKm = distanceMeters / 1000.0;
        _durationMin = durationSeconds / 60.0;
        if (!silent) _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al obtener la ruta: $e';
        if (!silent) _loading = false;
      });
    }
  }

  /// Decodificador de polyline (precision 1e-5)
  List<LatLng> _decodePolyline(String polyline) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // =========================================================
  //   TRACKING EN TIEMPO REAL (cada 8 segundos)
  // =========================================================

  void _startTracking() {
    _trackingTimer?.cancel();
    setState(() => _enCamino = true);

    // primer update inmediato
    _actualizarPosicionYRuta();

    // luego cada 8 segundos
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _actualizarPosicionYRuta(),
    );
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    setState(() => _enCamino = false);
  }

  void _toggleEnCamino() {
    if (_enCamino) {
      _stopTracking();
    } else {
      _marcarUbicacionEnCaminoYEmpezarTracking();
    }
  }

  Future<void> _actualizarPosicionYRuta() async {
    try {
      final ok = await _ensureLocationReady();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      // actualizar marker de mi posición
      setState(() {
        _myPos = LatLng(pos.latitude, pos.longitude);
      });

      // 🔹 NO movemos la cámara para no perder la posición que eligió el usuario
      // _mapController.move(_myPos!, _mapController.camera.zoom);

      // guardar en backend
      await _guardarPosicionEnBackend(pos);

      // recalcular ruta, pero sin mostrar loading spinner
      await _fetchRoute(silent: true);
    } catch (e) {
      // opcional: log / snack
    }
  }

  Future<void> _guardarPosicionEnBackend(Position pos) async {
    try {
      final idPersona = await AuthStorage.getIdPersona();
      if (idPersona == null) return;

      final uri = Uri.parse(
        '$_baseUrl/pedidos/repartidores/$idPersona/posicion',
      );

      await http.patch(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitud': pos.latitude,
          'longitud': pos.longitude,
        }),
      );
    } catch (e) {
      // silencioso por ahora
    }
  }

  /// 🔹 Llama al backend para:
  ///  - asignar esta ubicación al repartidor actual
  ///  - poner estado_entrega = 'en_camino'
  ///  - luego inicia el tracking en la app
  Future<void> _marcarUbicacionEnCaminoYEmpezarTracking() async {
    try {
      final idPersona = await AuthStorage.getIdPersona();
      if (idPersona == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu persona (sesión).'),
          ),
        );
        return;
      }

      final uri = Uri.parse(
        '$_baseUrl/pedidos/repartidores/$idPersona/pedidos/${widget.idPedido}'
        '/ubicaciones/${widget.idubicacion}/en-camino',
      );

      final res = await http.patch(uri);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación marcada como en camino.')),
        );
        _startTracking();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al marcar en camino (${res.statusCode}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar en camino: $e')),
      );
    }
  }

  // =========================================================

  @override
  Widget build(BuildContext context) {
    // Ajustar bounds solo una vez cuando ya tenemos puntos y el mapa está montado.
    if (!_mapFitted && _routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(32)),
          );
          _mapFitted = true;
        } catch (_) {
          // si aún no está listo, lo intenta en el siguiente frame
        }
      });
    }

    return Scaffold(
      backgroundColor: Palette.fieldBg,
      appBar: AppBar(
        title: Text('Ruta a ${widget.nombre}'),
        backgroundColor: Palette.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _myPos ?? _dest,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=$MAPBOX_TOKEN',
                          tileProvider: CancellableNetworkTileProvider(),
                          userAgentPackageName: 'quimisol.app',
                          minZoom: 3,
                          maxZoom: 18,
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // 🚚 Ubicación actual → camión pintudo
                            if (_myPos != null)
                              Marker(
                                point: _myPos!,
                                width: 46,
                                height: 46,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    size: 22,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),

                            // 🏠 Ubicación de entrega → casa
                            Marker(
                              point: _dest,
                              width: 46,
                              height: 46,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.home_rounded,
                                  size: 22,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tarjeta inferior con info de distancia / tiempo + botón en camino
                    if (_distanceKm != null && _durationMin != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          minimum: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Card info
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 10,
                                      color: Colors.black26,
                                      offset: Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.straighten,
                                            size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_distanceKm!.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_durationMin!.round()} min',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      tooltip: 'Recalcular ruta',
                                      onPressed: () =>
                                          _fetchRoute(silent: false),
                                      icon: const Icon(Icons.refresh),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Botón en camino
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _toggleEnCamino,
                                  icon: Icon(
                                    _enCamino
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_fill,
                                  ),
                                  label: Text(
                                    _enCamino
                                        ? 'Detener seguimiento'
                                        : 'Marcar como en camino',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Palette.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
