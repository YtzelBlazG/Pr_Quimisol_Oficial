import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

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

  final estados = ['pendiente', 'aceptado', 'en camino', 'entregado'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: estados.length, vsync: this);
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    try {
      final idUsuario = await AuthStorage.getIdPersona();
      if (idUsuario == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
        setState(() => _loading = false);
        return;
      }

      final url = Uri.parse('http://localhost:3005/pedidos/usuario/$idUsuario');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        setState(() {
          _pedidos = jsonDecode(resp.body) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar pedidos')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<List<dynamic>> _cargarDetalles(int idPedido) async {
    final url = Uri.parse('http://localhost:3005/pedidos/$idPedido');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      return json['detalles'] as List<dynamic>;
    }
    return [];
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptado':
        return Palette.primary;
      case 'en camino':
        return Colors.blue;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPedidoCard(dynamic p) {
    final id = p['idpedido'];
    final total = (p['total'] ?? 0).toString();
    final fechaRaw = (p['fecha'] ?? '').toString();
    final estado = (p['estado'] ?? '').toString();

    // Formatear fecha
    String fechaFormateada = '';
    try {
      final parsed = DateTime.parse(fechaRaw);
      fechaFormateada = DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      fechaFormateada = fechaRaw;
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
            Text(
              'Pedido #$id',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _estadoColor(estado).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                estado.toUpperCase(),
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
          child: Text(
            'Fecha: $fechaFormateada',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: Text(
          'Bs $total',
          style: TextStyle(
            color: Palette.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          FutureBuilder<List<dynamic>>(
            future: _cargarDetalles(id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }
              final det = snap.data ?? [];
              if (det.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Sin detalles'),
                );
              }
              return Column(
                children: det.map((d) {
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
                        backgroundColor: Palette.primary.withOpacity(0.12),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Palette.secButton,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          indicatorColor: Palette.primary,
          labelColor: Palette.primary,
          unselectedLabelColor: Colors.grey,
          tabs: estados.map((e) => Tab(text: e.toUpperCase())).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: estados.map((estado) {
                final filtrados = _pedidos
                    .where(
                      (p) =>
                          (p['estado'] ?? '').toString().toLowerCase() ==
                          estado,
                    )
                    .toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay pedidos $estado',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _cargarPedidos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) => _buildPedidoCard(filtrados[i]),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
