// lib/features/repartidor/screens/home_repartidor_page.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class HomeRepartidorPage extends StatefulWidget {
  const HomeRepartidorPage({super.key});

  @override
  State<HomeRepartidorPage> createState() => _HomeRepartidorPageState();
}

class _HomeRepartidorPageState extends State<HomeRepartidorPage> {
  bool _loading = true;
  bool _error = false;
  String _errorMsg = '';
  List<Map<String, dynamic>> _pedidos = [];

  double? _myLat;
  double? _myLng;
  String? _locationError;

  String get _baseUrl => Env.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _logout() async {
    await AuthStorage.clear();
    if (mounted) {
      Modular.to.pushReplacementNamed('/home-guest');
    }
  }

  Future<void> _cargarPedidos() async {
    try {
      setState(() {
        _loading = true;
        _error = false;
        _errorMsg = '';
      });

      final idPersona = await AuthStorage.getIdPersona();
      if (idPersona == null) {
        throw Exception('No se encontró idpersona en sesión.');
      }

      // Ruta: /pedidos/repartidores/:idPersona/pedidos
      final uri = Uri.parse(
        '$_baseUrl/pedidos/repartidores/$idPersona/pedidos',
      );

      final resp = await http.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (resp.statusCode != 200) {
        throw Exception(
          'Error al cargar pedidos (${resp.statusCode}): ${resp.body}',
        );
      }

      final data = jsonDecode(resp.body);
      if (data is! List) {
        throw Exception('Respuesta inválida del servidor.');
      }

      _pedidos = data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _loading = false;
      if (mounted) setState(() {});

      // Luego de cargar pedidos, obtenemos ubicación y ordenamos
      await _obtenerUbicacionYOrdenar();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _obtenerUbicacionYOrdenar() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Servicios de ubicación desactivados.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Permiso de ubicación denegado.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _myLat = pos.latitude;
      _myLng = pos.longitude;
      _locationError = null;

      // Calcular distancia para cada pedido (a su ubicación principal)
      for (final p in _pedidos) {
        final latRaw = p['ubicacion_latitud'];
        final lngRaw = p['ubicacion_longitud'];

        if (latRaw == null || lngRaw == null) {
          p['_distancia_km'] = null;
          continue;
        }

        final lat = double.tryParse(latRaw.toString());
        final lng = double.tryParse(lngRaw.toString());
        if (lat == null || lng == null) {
          p['_distancia_km'] = null;
          continue;
        }

        p['_distancia_km'] = _distanceInKm(_myLat!, _myLng!, lat, lng);
      }

      // Ordenar: primero los más cercanos
      _pedidos.sort((a, b) {
        final da = a['_distancia_km'] as double?;
        final db = b['_distancia_km'] as double?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _locationError = 'No se pudo obtener tu ubicación: $e';
      });
    }
  }

  /// Distancia aproximada en KM (Haversine)
  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  /// Distancia desde mi posición a una lat/lng cualquiera (para cada sucursal)
  double? _distanceFromMe(dynamic latRaw, dynamic lngRaw) {
    if (_myLat == null || _myLng == null) return null;
    final lat = double.tryParse(latRaw?.toString() ?? '');
    final lng = double.tryParse(lngRaw?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return _distanceInKm(_myLat!, _myLng!, lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f6fb),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Panel de repartidor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Ocurrió un error al cargar tus pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 260,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _cargarPedidos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primary,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }

    if (_pedidos.isEmpty) {
      return const Center(
        child: Text(
          'No tienes pedidos asignados en tus ciclos actuales.\n\nVuelve más tarde.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Agrupar por ciclo (anio-mes)
    final Map<String, List<Map<String, dynamic>>> porCiclo = {};
    for (final p in _pedidos) {
      final anio = p['anio']?.toString() ?? '';
      final mes = p['mes']?.toString() ?? '';
      final key = '$anio-$mes';
      porCiclo.putIfAbsent(key, () => []).add(p);
    }

    final ciclosOrdenados = porCiclo.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // más recientes primero

    return Column(
      children: [
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.location_off, size: 18, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: ciclosOrdenados.length,
            itemBuilder: (context, index) {
              final key = ciclosOrdenados[index];
              final partes = key.split('-');
              final anio = partes[0];
              final mesNum =
                  int.tryParse(partes.length > 1 ? partes[1] : '1') ?? 1;
              final nombreMes = _nombreMes(mesNum);
              final pedidosCiclo = porCiclo[key]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: Text(
                      '$nombreMes $anio',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  ...pedidosCiclo.map(_buildPedidoCard).toList(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _nombreMes(int mes) {
    const nombres = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (mes < 1 || mes > 12) return 'Mes $mes';
    return nombres[mes];
  }

  String _normEstado(dynamic v) =>
      (v ?? '').toString().trim().toLowerCase().replaceAll(' ', '_');

  String _labelEstado(String e) {
    final pretty = e.replaceAll('_', ' ');
    return pretty.isEmpty ? '' : pretty[0].toUpperCase() + pretty.substring(1);
  }

  Color _estadoColor(String estado) {
    switch (_normEstado(estado)) {
      case 'pedido':
        return Colors.orange;
      case 'en_camino':
        return Colors.blue;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Devuelve {detalles: List, ubicaciones: List}
  Future<Map<String, dynamic>> _cargarDetalleYUbicaciones(int idPedido) async {
    final uri = Uri.parse('$_baseUrl/pedidos/$idPedido');
    final resp = await http.get(
      uri,
      headers: const {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      return {
        'detalles': (json['detalles'] as List<dynamic>? ?? []),
        'ubicaciones': (json['ubicaciones'] as List<dynamic>? ?? []),
      };
    }
    return {'detalles': [], 'ubicaciones': []};
  }

  Widget _buildPedidoCard(Map<String, dynamic> p) {
    final idRaw = p['idpedido'] ?? p['id'] ?? p['iddetalle'] ?? p['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final String codigoPedido =
        (p['codigo_publico'] ??
                p['codigo'] ??
                (id != 0 ? 'QMS-${id.toString().padLeft(6, '0')}' : 'Pedido'))
            .toString();

    final double baseTotal = double.tryParse((p['total'] ?? 0).toString()) ?? 0;
    final double totalConUbicaciones =
        double.tryParse(
          (p['total_con_ubicaciones'] ?? p['total'] ?? 0).toString(),
        ) ??
        baseTotal;

    final int ubicacionesCount =
        int.tryParse((p['ubicaciones_count'] ?? 0).toString()) ?? 0;

    final fechaRaw = (p['fecha'] ?? p['createdon'] ?? '').toString();
    final fechaCicloRaw = (p['fecha_ciclo_entrega'] ?? '').toString();
    final estado = _normEstado(p['estado']);

    final double? distKm = (p['_distancia_km'] is num)
        ? (p['_distancia_km'] as num).toDouble()
        : null;

    String fechaFormateada = '';
    try {
      final parsed = DateTime.parse(fechaRaw);
      fechaFormateada = DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      fechaFormateada = fechaRaw;
    }

    String fechaCicloFormateada = '';
    if (fechaCicloRaw.isNotEmpty) {
      try {
        final parsed = DateTime.parse(fechaCicloRaw);
        fechaCicloFormateada = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {
        fechaCicloFormateada = fechaCicloRaw;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        iconColor: Palette.primary,
        collapsedIconColor: Palette.primary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido $codigoPedido',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (ubicacionesCount > 0)
                  Text(
                    '$ubicacionesCount ubicación(es)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _estadoColor(estado).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _labelEstado(estado),
                style: TextStyle(
                  color: _estadoColor(estado),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (distKm != null) ...[
                Row(
                  children: [
                    Icon(Icons.place, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${distKm.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              Text(
                'Fecha pedido: $fechaFormateada',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (fechaCicloFormateada.isNotEmpty)
                Text(
                  'Entrega estimada: $fechaCicloFormateada',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        trailing: Text(
          'Bs ${totalConUbicaciones.toStringAsFixed(2)}',
          style: TextStyle(
            color: Palette.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _cargarDetalleYUbicaciones(id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              final det = (snap.data?['detalles'] as List?) ?? [];
              final ubis = (snap.data?['ubicaciones'] as List?) ?? [];

              final children = <Widget>[];

              // DETALLES
              if (det.isNotEmpty) {
                children.addAll(
                  det.map((d) {
                    final nombre = d['nombre'] ?? 'Producto';
                    final cant = d['cantidad'] ?? 0;
                    final precio = d['preciounitario'] ?? 0;
                    final sub = d['subtotal'] ?? 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Palette.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Palette.primary,
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Cantidad: $cant • Precio: $precio Bs',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Text(
                          '$sub Bs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else {
                children.add(
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Sin detalles'),
                  ),
                );
              }

              // UBICACIONES
              children.add(const SizedBox(height: 10));
              children.add(
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Entregar en',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (ubis.isNotEmpty) {
                children.addAll(
                  ubis.map((u) {
                    final nombre = (u['nombre'] ?? '').toString().trim();
                    final direccion = (u['direccion'] ?? '').toString().trim();
                    final ciudad = (u['ciudad'] ?? '').toString().trim();
                    final lat = u['latitud'];
                    final lng = u['longitud'];
                    final estadoEntrega =
                        (u['estado_entrega'] ?? 'pedido').toString();
                    final esEntregada = estadoEntrega == 'entregado';

                    final distanciaKm = _distanceFromMe(lat, lng);

                    Future<void> _abrirUbicacion() async {
                      final idUbicacion = u['idubicacion'] ?? u['id'];
                      if (idUbicacion == null) return;

                      // Navega a la pantalla de ruta
                      await Modular.to.pushNamed(
                        '/location-route',
                        arguments: {
                          'idubicacion': idUbicacion,
                          'idPedido': id,
                          'nombre': nombre,
                          'latitud':
                              double.tryParse(lat?.toString() ?? '0') ?? 0.0,
                          'longitud':
                              double.tryParse(lng?.toString() ?? '0') ?? 0.0,
                        },
                      );

                      // Al volver, recargamos pedidos para refrescar estados
                      if (mounted) {
                        _cargarPedidos();
                      }
                    }

                    Color chipColor;
                    Color chipText;
                    String chipTextLabel;

                    if (estadoEntrega == 'pedido') {
                      chipColor = Colors.grey.shade100;
                      chipText = Colors.grey.shade800;
                      chipTextLabel = 'Pendiente';
                    } else if (estadoEntrega == 'en_camino') {
                      chipColor = Colors.blue.shade50;
                      chipText = Colors.blue.shade700;
                      chipTextLabel = 'En camino';
                    } else {
                      chipColor = Colors.green.shade50;
                      chipText = Colors.green.shade700;
                      chipTextLabel = 'Entregado';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        onTap: esEntregada ? null : () => _abrirUbicacion(),
                        leading: const CircleAvatar(
                          child: Icon(Icons.place, color: Colors.white),
                          backgroundColor: Colors.blue,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombre.isEmpty ? 'Ubicación' : nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chipTextLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: chipText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ciudad.isNotEmpty)
                              Text(
                                ciudad,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            Text(
                              direccion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (distanciaKm != null)
                              Text(
                                '${distanciaKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (esEntregada)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Completado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => _abrirUbicacion(),
                                icon: const Icon(Icons.map_outlined, size: 14),
                                label: const Text(
                                  'Ver',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else {
                children.add(
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Sin ubicaciones seleccionadas'),
                  ),
                );
              }

              children.add(const SizedBox(height: 12));
              return Column(children: children);
            },
          ),
        ],
      ),
    );
  }
}
