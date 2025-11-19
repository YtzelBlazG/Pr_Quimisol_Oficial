// lib/features/pedidos/pages/pedidos_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

import 'pedido_tracking_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _pedidos = [];

  String get _baseUrl => Env.apiBaseUrl;

  // Tabs que mostramos
  // (En el tab "pedido" incluiremos también los que estén "pendiente")
  final List<String> estados = const ['pedido', 'en_camino', 'entregado'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: estados.length, vsync: this);
    _cargarPedidos();
  }

  // ================== HELPERS ==================

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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
      case 'pendiente': // mismo color que "pedido"
        return Colors.orange;
      case 'en_camino':
        return Colors.blue;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ================== API ======================

  Future<void> _cargarPedidos() async {
    try {
      setState(() => _loading = true);

      // ⚠️ Aquí usas idPersona guardada; si tienes getIdUsuario cámbialo:
      final idUsuario = await AuthStorage.getIdPersona();
      if (idUsuario == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
        setState(() => _loading = false);
        return;
      }

      final url = Uri.parse('$_baseUrl/pedidos/usuario/$idUsuario');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        setState(() {
          _pedidos = jsonDecode(resp.body) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar pedidos')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Devuelve {detalles: List, ubicaciones: List}
  Future<Map<String, dynamic>> _cargarDetalleYUbicaciones(int idPedido) async {
    final url = Uri.parse('$_baseUrl/pedidos/$idPedido');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      return {
        'detalles': (json['detalles'] as List<dynamic>? ?? []),
        'ubicaciones': (json['ubicaciones'] as List<dynamic>? ?? []),
      };
    }
    return {'detalles': [], 'ubicaciones': []};
  }

  // ================== UI =======================

  Widget _buildPedidoCard(dynamic p, String estadoTab) {
    final id = p['idpedido'] is int
        ? p['idpedido'] as int
        : int.tryParse(p['idpedido']?.toString() ?? '0') ?? 0;

    // Código público
    final String codigoPedido =
        (p['codigo_publico'] ??
                p['codigo'] ??
                (id != 0 ? 'QMS-${id.toString().padLeft(6, '0')}' : 'Pedido'))
            .toString();

    // base y total final
    final double baseTotal = double.tryParse((p['total'] ?? 0).toString()) ?? 0;
    final double totalConUbicaciones =
        double.tryParse(
          (p['total_con_ubicaciones'] ?? p['total'] ?? 0).toString(),
        ) ??
        baseTotal;

    final int ubicacionesCount =
        int.tryParse((p['ubicaciones_count'] ?? 0).toString()) ?? 0;

    // Fechas: pedido + ciclo de entrega
    final fechaRaw = (p['fecha'] ?? '').toString();
    final fechaCicloRaw = (p['fecha_ciclo_entrega'] ?? '').toString();
    final estadoPedido = _normEstado(p['estado']);

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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            // Izquierda: info pedido + ubicaciones
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
            // Derecha: pill de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _estadoColor(estadoPedido).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _labelEstado(estadoPedido),
                style: TextStyle(
                  color: _estadoColor(estadoPedido),
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
        // total FINAL ya multiplicado por ubicaciones
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

              // Si estamos en el tab "en_camino", solo mostramos ubicaciones en ese estado
              final List<dynamic> ubisFiltradas = estadoTab == 'en_camino'
                  ? ubis
                      .where(
                        (u) =>
                            _normEstado(u['estado_entrega']) == 'en_camino',
                      )
                      .toList()
                  : ubis;

              final children = <Widget>[];

              // Productos
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
                  }),
                );
              } else {
                children.add(
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Sin detalles'),
                  ),
                );
              }

              // Separador
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

              // Ubicaciones
              if (ubisFiltradas.isNotEmpty) {
                children.addAll(
                  ubisFiltradas.map((u) {
                    final nombre = (u['nombre'] ?? '').toString().trim();
                    final direccion = (u['direccion'] ?? '').toString().trim();
                    final ciudad = (u['ciudad'] ?? '').toString().trim();

                    final int? idUbicacion = u['idubicacion'] is int
                        ? u['idubicacion'] as int
                        : int.tryParse(
                            u['idubicacion']?.toString() ?? '',
                          );

                    final double? lat = _toDouble(u['latitud']);
                    final double? lng = _toDouble(u['longitud']);

                    final String repartidorNombre =
                        (u['repartidor_nombre'] ?? '').toString().trim();

                    final String estadoUbicacion =
                        _normEstado(u['estado_entrega'] ?? 'pedido');

                    Color chipColor;
                    Color chipText;
                    String chipTextLabel;

                    if (estadoUbicacion == 'pedido') {
                      chipColor = Colors.grey.shade100;
                      chipText = Colors.grey.shade800;
                      chipTextLabel = 'Pendiente';
                    } else if (estadoUbicacion == 'en_camino') {
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
                        leading: const CircleAvatar(
                          child: Icon(Icons.place_outlined),
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
                            ),
                            if (repartidorNombre.isNotEmpty)
                              Text(
                                'Repartidor: $repartidorNombre',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (lat != null && lng != null)
                              Text(
                                'Lat: ${lat.toStringAsFixed(6)}  •  Lng: ${lng.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                        trailing: (idUbicacion != null &&
                                lat != null &&
                                lng != null &&
                                estadoUbicacion == 'en_camino')
                            ? TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PedidoTrackingPage(
                                        idPedido: id,
                                        idUbicacion: idUbicacion,
                                        nombreUbicacion: nombre.isEmpty
                                            ? 'Ubicación'
                                            : nombre,
                                        latitud: lat,
                                        longitud: lng,
                                        repartidorNombre:
                                            repartidorNombre.isEmpty
                                                ? null
                                                : repartidorNombre,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Ver pedido'),
                              )
                            : null,
                      ),
                    );
                  }),
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

  // ================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f6fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Palette.primary,
        title: const Text(
          'Mis pedidos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Palette.secondary,
          labelColor: Palette.secondary,
          unselectedLabelColor: Colors.grey,
          tabs: estados.map((e) => Tab(text: _labelEstado(e))).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: estados.map((estadoTab) {
                // Aquí metemos también los "pendiente" en el tab "pedido"
                final filtrados = _pedidos.where((p) {
                  final est = _normEstado(p['estado']);
                  if (estadoTab == 'pedido') {
                    return est == 'pedido' || est == 'pendiente';
                  }
                  return est == estadoTab;
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay pedidos ${_labelEstado(estadoTab).toLowerCase()}',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _cargarPedidos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) =>
                        _buildPedidoCard(filtrados[i], estadoTab),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
