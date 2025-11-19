// lib/features/admin/pedidos/page/pedidos_list_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/theme/palette.dart';

class PedidosListPage extends StatefulWidget {
  const PedidosListPage({super.key});

  @override
  State<PedidosListPage> createState() => _PedidosListPageState();
}

class _PedidosListPageState extends State<PedidosListPage> {
  bool _loading = true;
  bool _error = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _pedidos = [];

  // filtros UI
  String _search = '';
  String? _estadoFiltro; // null => todos

  String get _baseUrl => Env.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    try {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = '';
      });

      final uri = Uri.parse('$_baseUrl/pedidos');
      final resp = await http.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode}: ${resp.body}');
      }

      final data = jsonDecode(resp.body);

      if (data is List) {
        _pedidos = data
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      } else {
        _pedidos = [];
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  // ============= Helpers de formato / filtros ===================

  Color _estadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
      case 'pedido':
        return Colors.orange;
      case 'en_proceso':
      case 'procesando':
      case 'en_camino':
        return Colors.blue;
      case 'completado':
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEstadoChip(String? estado) {
    final raw = (estado ?? 'Desconocido').toString();
    final text = raw.isEmpty
        ? 'Desconocido'
        : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _estadoColor(estado).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _estadoColor(estado),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatFecha(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    // si viene en ISO: 2025-11-17T01:23:45.000Z
    if (s.contains('T')) {
      final parts = s.split('T');
      final date = parts[0];
      // opcional: podrías formatear dd/MM/yyyy, por ahora dejamos YYYY-MM-DD
      return date;
    }
    return s;
  }

  String _formatTotal(dynamic raw) {
    if (raw == null) return '—';
    final n = double.tryParse(raw.toString());
    if (n == null) return raw.toString();
    return 'Bs ${n.toStringAsFixed(2)}';
  }

  double _toDouble(dynamic raw) {
    if (raw == null) return 0;
    return double.tryParse(raw.toString()) ?? 0;
  }

  // Lista de estados presentes en los datos (para chips)
  List<String> get _estadosDisponibles {
    final set = <String>{};
    for (final p in _pedidos) {
      final e = (p['estado'] ?? '').toString();
      if (e.isNotEmpty) set.add(e);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Pedidos filtrados por estado y search
  List<Map<String, dynamic>> get _pedidosFiltrados {
    return _pedidos.where((p) {
      final estado = (p['estado'] ?? '').toString();
      final idPedido = (p['idpedido'] ?? p['id'] ?? '').toString();
      final idUsuario = (p['idusuario'] ?? '').toString();
      final total = (p['total_final'] ?? p['total'] ?? '').toString();
      final codigo = (p['codigo_publico'] ?? p['codigo'] ?? '').toString();
      final clienteNombre = (p['cliente_nombre'] ?? 'Usuario #$idUsuario')
          .toString();

      // filtro por estado
      if (_estadoFiltro != null && _estadoFiltro!.isNotEmpty) {
        if (estado.toLowerCase() != _estadoFiltro!.toLowerCase()) {
          return false;
        }
      }

      // filtro por texto
      if (_search.trim().isEmpty) return true;
      final q = _search.toLowerCase();
      return idPedido.toLowerCase().contains(q) ||
          estado.toLowerCase().contains(q) ||
          idUsuario.toLowerCase().contains(q) ||
          total.toLowerCase().contains(q) ||
          codigo.toLowerCase().contains(q) ||
          clienteNombre.toLowerCase().contains(q);
    }).toList();
  }

  // ================== UI ========================

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedidos',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Palette.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Listado general de pedidos registrados en la plataforma.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Recargar',
                            onPressed: _cargarPedidos,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Resumen (cards)
                      if (!_loading && !_error) _buildResumenRow(),

                      const SizedBox(height: 12),

                      // Filtros (search + estado)
                      if (!_loading && !_error) _buildFiltros(),

                      const SizedBox(height: 16),

                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error)
                        _buildError()
                      else if (_pedidos.isEmpty)
                        _buildEmpty()
                      else
                        _buildTable(constraints),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumenRow() {
    final totalPedidos = _pedidos.length;
    final pendientes = _pedidos
        .where(
          (p) => (p['estado'] ?? '').toString().toLowerCase() == 'pendiente',
        )
        .length;
    final completados = _pedidos.where((p) {
      final e = (p['estado'] ?? '').toString().toLowerCase();
      return e == 'completado' || e == 'entregado';
    }).length;
    final montoTotal = _pedidos.fold<double>(
      0,
      (acc, p) => acc + _toDouble(p['total_final'] ?? p['total']),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        final children = [
          _ResumenCard(
            label: 'Total pedidos',
            value: '$totalPedidos',
            icon: Icons.receipt_long,
            color: Palette.primary,
          ),
          _ResumenCard(
            label: 'Pendientes',
            value: '$pendientes',
            icon: Icons.watch_later_outlined,
            color: Colors.orange,
          ),
          _ResumenCard(
            label: 'Completados/Entregados',
            value: '$completados',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          _ResumenCard(
            label: 'Monto total final',
            value: 'Bs ${montoTotal.toStringAsFixed(2)}',
            icon: Icons.payments_outlined,
            color: Palette.secButton,
          ),
        ];

        if (isSmall) {
          return Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: children
                    .map((w) => SizedBox(width: 260, child: w))
                    .toList(),
              ),
            ],
          );
        }

        return Row(
          children:
              children
                  .map(
                    (w) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: w,
                      ),
                    ),
                  )
                  .toList()
                ..last = Expanded(child: children.last),
        );
      },
    );
  }

  Widget _buildFiltros() {
    final estados = _estadosDisponibles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // search
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar por código, cliente, estado, ID o monto...',
                  isDense: true,
                  filled: true,
                  fillColor: Palette.fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _search = value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // chips estado
        if (estados.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _estadoFiltro == null,
                  onSelected: (_) {
                    setState(() => _estadoFiltro = null);
                  },
                ),
                const SizedBox(width: 6),
                ...estados.map((e) {
                  final selected =
                      _estadoFiltro != null &&
                      _estadoFiltro!.toLowerCase() == e.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(e),
                      selected: selected,
                      selectedColor: _estadoColor(e).withOpacity(0.16),
                      onSelected: (_) {
                        setState(() => _estadoFiltro = e);
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ocurrió un error al cargar los pedidos.\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _cargarPedidos,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: Palette.primary),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No hay pedidos registrados todavía.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BoxConstraints constraints) {
    final pedidos = _pedidosFiltrados;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          Palette.primary.withOpacity(0.06),
        ),
        columnSpacing: 28,
        dataRowHeight: 60,
        columns: const [
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Fecha pedido')),
          DataColumn(label: Text('Fecha ciclo entrega')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Total final')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: pedidos.map((pedido) {
          final id =
              pedido['idpedido']?.toString() ?? pedido['id']?.toString() ?? '';
          final idUsuario = pedido['idusuario']?.toString() ?? '—';
          final codigo =
              (pedido['codigo_publico'] ??
                      pedido['codigo'] ??
                      (id.isNotEmpty ? 'QMS-${id.padLeft(6, '0')}' : ''))
                  .toString();

          final clienteNombre =
              (pedido['cliente_nombre'] ?? 'Usuario #$idUsuario').toString();

          final fechaPedido = _formatFecha(
            pedido['fecha'] ?? pedido['createdon'],
          );
          final fechaCiclo = _formatFecha(
            pedido['fecha_ciclo_entrega'] ?? pedido['fecha_ciclo'],
          );

          final estado = pedido['estado']?.toString();
          final totalFinal = _formatTotal(
            pedido['total_final'] ?? pedido['total'],
          );

          return DataRow(
            cells: [
              DataCell(Text(codigo)),
              DataCell(
                Text(
                  clienteNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              DataCell(Text(fechaPedido)),
              DataCell(Text(fechaCiclo)),
              DataCell(_buildEstadoChip(estado)),
              DataCell(Text(totalFinal)),
              DataCell(
                IconButton(
                  tooltip: 'Ver detalle',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () {
                    // después armamos bien el detalle
                    _showPedidoDetalle(pedido);
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showPedidoDetalle(Map<String, dynamic> pedido) {
    // sólo un modal sencillo por ahora; luego lo mejoramos
    final codigo = (pedido['codigo_publico'] ?? pedido['codigo'] ?? '')
        .toString();
    final idUsuario = pedido['idusuario']?.toString() ?? '—';
    final clienteNombre = (pedido['cliente_nombre'] ?? 'Usuario #$idUsuario')
        .toString();
    final fechaPedido = _formatFecha(pedido['fecha'] ?? pedido['createdon']);
    final fechaCiclo = _formatFecha(
      pedido['fecha_ciclo_entrega'] ?? pedido['fecha_ciclo'],
    );
    final estado = pedido['estado']?.toString();
    final totalFinal = _formatTotal(pedido['total_final'] ?? pedido['total']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Palette.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Palette.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pedido $codigo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Cliente', clienteNombre),
              const SizedBox(height: 4),
              _detailRow('ID usuario', idUsuario),
              const SizedBox(height: 4),
              _detailRow('Fecha pedido', fechaPedido),
              const SizedBox(height: 4),
              _detailRow('Fecha ciclo', fechaCiclo),
              const SizedBox(height: 4),
              _detailRow('Estado', '', trailing: _buildEstadoChip(estado)),
              const SizedBox(height: 4),
              _detailRow('Total final', totalFinal),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

// ================== Widgets auxiliares ========================

class _ResumenCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResumenCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
