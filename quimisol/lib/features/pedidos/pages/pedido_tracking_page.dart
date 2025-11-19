import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/theme/palette.dart';

const String MAPBOX_TOKEN =
    'pk.eyJ1Ijoic2ViYXMxMjciLCJhIjoiY21mMGhhdDRiMG5mbTJscHlnMGUweGlicSJ9.SVeyu-4RTAybmgRxhPxSWw';

class PedidoTrackingPage extends StatefulWidget {
  final int idPedido;
  final int idUbicacion;
  final String nombreUbicacion;
  final double latitud;
  final double longitud;
  final String? repartidorNombre;

  const PedidoTrackingPage({
    super.key,
    required this.idPedido,
    required this.idUbicacion,
    required this.nombreUbicacion,
    required this.latitud,
    required this.longitud,
    this.repartidorNombre,
  });

  @override
  State<PedidoTrackingPage> createState() => _PedidoTrackingPageState();
}

class _PedidoTrackingPageState extends State<PedidoTrackingPage> {
  final MapController _mapController = MapController();

  LatLng? _repPos;
  late LatLng _dest;

  bool _loading = true;
  String? _error;

  List<LatLng> _routePoints = [];
  double? _distanceKm;
  double? _durationMin;

  bool _mapFitted = false;
  Timer? _timer;

  String get _baseUrl => Env.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _dest = LatLng(widget.latitud, widget.longitud);
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _refresh(initial: true);

    // actualizamos cada 8 segundos
    _timer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refresh(initial: false),
    );
  }

  Future<void> _refresh({required bool initial}) async {
    try {
      final okPos = await _fetchPosicionRepartidor(silent: !initial);
      if (okPos && _repPos != null) {
        await _fetchRoute(silent: !initial);
      }

      if (initial && mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al actualizar seguimiento: $e';
        _loading = false;
      });
    }
  }

  /// Obtiene la última posición del repartidor asignado a esta ubicación
  Future<bool> _fetchPosicionRepartidor({bool silent = false}) async {
    final uri = Uri.parse(
      '$_baseUrl/pedidos/${widget.idPedido}/ubicaciones/'
      '${widget.idUbicacion}/posicion-repartidor',
    );

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final lat = (data['latitud'] as num?)?.toDouble();
      final lng = (data['longitud'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        if (!silent && mounted) {
          setState(() {
            _error = 'Aún no hay posición registrada del repartidor.';
          });
        }
        return false;
      }

      if (!mounted) return true;
      setState(() {
        _repPos = LatLng(lat, lng);
        if (!silent) _error = null;
      });
      return true;
    } else {
      if (!silent && mounted) {
        String msg = 'No hay posición disponible del repartidor.';
        try {
          final json = jsonDecode(res.body);
          if (json is Map && json['message'] is String) {
            msg = json['message'] as String;
          }
        } catch (_) {}
        setState(() => _error = msg);
      }
      return false;
    }
  }

  /// Llama a Mapbox Directions y arma la ruta desde el repartidor hasta la ubicación.
  Future<void> _fetchRoute({bool silent = false}) async {
    if (_repPos == null) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _mapFitted = false;
      });
    } else {
      _mapFitted = false;
    }

    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${_repPos!.longitude},${_repPos!.latitude};'
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

  @override
  Widget build(BuildContext context) {
    if (!_mapFitted && _routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(32)),
          );
          _mapFitted = true;
        } catch (_) {}
      });
    }

    return Scaffold(
      backgroundColor: Palette.fieldBg,
      appBar: AppBar(
        title: Text('Seguimiento de pedido'),
        backgroundColor: Palette.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.nombreUbicacion,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _repPos ?? _dest,
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
                        // Repartidor
                        if (_repPos != null)
                          Marker(
                            point: _repPos!,
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
                                Icons.local_shipping,
                                size: 22,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        // Destino
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

                // Tarjeta inferior con info
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.straighten, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _distanceKm != null
                                        ? '${_distanceKm!.toStringAsFixed(1)} km'
                                        : '-- km',
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
                                    _durationMin != null
                                        ? '${_durationMin!.round()} min'
                                        : '-- min',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                tooltip: 'Actualizar ahora',
                                onPressed: () =>
                                    _refresh(initial: false),
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.repartidorNombre != null &&
                            widget.repartidorNombre!.isNotEmpty)
                          Text(
                            'Repartidor: ${widget.repartidorNombre}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
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
