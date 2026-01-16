import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class SelectLocationsPage extends StatefulWidget {
  const SelectLocationsPage({super.key});

  @override
  State<SelectLocationsPage> createState() => _SelectLocationsPageState();
}

class _SelectLocationsPageState extends State<SelectLocationsPage> {
  late final LocationsService _svc;
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _items = [];
  final Set<int> _selected = {};

  double? _carritoTotal;

  String? _departamentoSeleccionadoNorm;
  String? _departamentoSeleccionadoLabel;

  @override
  void initState() {
    super.initState();
    _svc = LocationsService(baseUrl: Env.apiBaseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final idPersona = await AuthStorage.getIdPersona();
    if (idPersona == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      setState(() => _loading = false);
      return;
    }
    try {
      final ubicFuture = _svc.listByPersona(idPersona);
      final totalFuture = _fetchCarritoTotal(idPersona);

      final data = await ubicFuture;
      final total = await totalFuture;

      setState(() {
        _items = data;
        _carritoTotal = total;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ubicaciones: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<double?> _fetchCarritoTotal(int idUsuario) async {
    try {
      final uri = Uri.parse('${Env.apiBaseUrl}/carrito/$idUsuario');
      final res = await http.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data is! List) return null;

      double total = 0;
      for (final item in data) {
        final precio =
            double.tryParse(item['precio']?.toString() ?? '0') ?? 0;
        final cantidad =
            double.tryParse(item['cantidad']?.toString() ?? '0') ?? 0;
        total += precio * cantidad;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  // ================== Helpers de departamento ==================

  String _normalizarDepartamento(Map<String, dynamic> it) {
    final raw =
        (it['departamento'] ?? it['depto'] ?? it['ciudad'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return raw;
  }

  String _labelDepartamento(Map<String, dynamic> it) {
    final raw =
        (it['departamento'] ?? it['depto'] ?? it['ciudad'] ?? '')
            .toString()
            .trim();
    return raw.isEmpty ? 'Departamento' : raw;
  }

  void _toggle(Map<String, dynamic> it) {
    final idUbicacion = (it['idubicacion'] as num).toInt();
    final depNorm = _normalizarDepartamento(it);
    final depLabel = _labelDepartamento(it);

    if (_selected.contains(idUbicacion)) {
      setState(() {
        _selected.remove(idUbicacion);
        if (_selected.isEmpty) {
          _departamentoSeleccionadoNorm = null;
          _departamentoSeleccionadoLabel = null;
        }
      });
      return;
    }

    if (_departamentoSeleccionadoNorm != null &&
        depNorm.isNotEmpty &&
        depNorm != _departamentoSeleccionadoNorm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solo puedes seleccionar ubicaciones del departamento $_departamentoSeleccionadoLabel.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (_departamentoSeleccionadoNorm == null && depNorm.isNotEmpty) {
        _departamentoSeleccionadoNorm = depNorm;
        _departamentoSeleccionadoLabel = depLabel;
      }
      _selected.add(idUbicacion);
    });
  }

  Future<void> _crearPedidoYGuardarUbicaciones() async {
    if (_selected.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final idUsuario = await AuthStorage.getIdPersona();
      if (idUsuario == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        return;
      }

      final postUri = Uri.parse(
        '${Env.apiBaseUrl}/pedidos/crear-desde-carrito/$idUsuario',
      );

      final postRes = await http.post(
        postUri,
        headers: {'Content-Type': 'application/json'},
      );

      if (postRes.statusCode != 201) {
        String msg = 'Error al crear el pedido';
        try {
          final body = jsonDecode(postRes.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final json = jsonDecode(postRes.body);
      final idPedido = json['pedido']?['idpedido'] as int?;
      if (idPedido == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el ID del pedido'),
          ),
        );
        return;
      }

      final putUri = Uri.parse(
        '${Env.apiBaseUrl}/pedidos/$idPedido/ubicaciones',
      );

      final putBody = jsonEncode({
        'ubicaciones_ids': _selected.toList(),
      });

      final putRes = await http.put(
        putUri,
        headers: {'Content-Type': 'application/json'},
        body: putBody,
      );

      if (!mounted) return;

      if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido #$idPedido creado, pero error al guardar ubicaciones (código ${putRes.statusCode}).',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido #$idPedido creado y ubicaciones asociadas correctamente ✅',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear pedido / guardar ubicaciones: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? get _totalConUbicaciones {
    if (_carritoTotal == null || _selected.isEmpty) return null;
    return _carritoTotal! * _selected.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEstimado = _totalConUbicaciones;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.gradientStart, Palette.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // espacio para el header global / status bar
            const SizedBox(height: 60),

            // sheet blanco
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header interno
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(8, 12, 16, 4),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Modular.to.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 18, color: Palette.ink),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seleccionar ubicaciones',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Palette.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selected.isEmpty
                                          ? 'Elige una o varias direcciones donde quieres recibir este pedido.'
                                          : '${_selected.length} ubicación(es) seleccionada(s) para este pedido.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    if (_departamentoSeleccionadoLabel !=
                                        null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Solo se permiten ubicaciones del departamento: $_departamentoSeleccionadoLabel.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (_carritoTotal != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        totalEstimado == null
                                            ? 'Total del carrito: Bs ${_carritoTotal!.toStringAsFixed(2)}'
                                            : 'Total estimado (${_selected.length} ubicación(es)): Bs ${totalEstimado.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Color(0xFFECE3F4),
                    ),

                    // LISTA
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Palette.primary,
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: Palette.primary,
                              child: _items.isEmpty
                                  ? const _EmptyLocations()
                                  : ListView.separated(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              16, 12, 16, 110),
                                      itemCount: _items.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (_, i) {
                                        final it = _items[i];
                                        final id = (it['idubicacion'] as num)
                                            .toInt();
                                        final nombre =
                                            (it['nombre'] ?? '')
                                                .toString()
                                                .trim();
                                        final direccion =
                                            (it['direccion'] ?? '')
                                                .toString()
                                                .trim();
                                        final ciudad =
                                            (it['ciudad'] ?? '')
                                                .toString()
                                                .trim();

                                        final checked =
                                            _selected.contains(id);

                                        final depNorm =
                                            _normalizarDepartamento(it);
                                        final bloqueado =
                                            _departamentoSeleccionadoNorm !=
                                                    null &&
                                                depNorm.isNotEmpty &&
                                                depNorm !=
                                                    _departamentoSeleccionadoNorm;

                                        return _LocationCard(
                                          nombre: nombre.isEmpty
                                              ? 'Ubicación'
                                              : nombre,
                                          ciudad: ciudad,
                                          direccion: direccion,
                                          checked: checked,
                                          bloqueado: bloqueado,
                                          onTap: () {
                                            if (bloqueado) {
                                              ScaffoldMessenger.of(
                                                      context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No puedes seleccionar esta dirección porque es de otro departamento.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            _toggle(it);
                                          },
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_carritoTotal != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          totalEstimado == null
                              ? 'Total del carrito: Bs ${_carritoTotal!.toStringAsFixed(2)}'
                              : 'Total estimado (${_selected.length} ubicación(es)): Bs ${totalEstimado.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _selected.isEmpty || _saving
                          ? null
                          : _crearPedidoYGuardarUbicaciones,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _saving
                            ? 'Procesando…'
                            : (_selected.isEmpty
                                ? 'Elige al menos una ubicación'
                                : 'Crear pedido (${_selected.length})'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.button,
                        foregroundColor: Palette.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------- CARD DE UBICACIÓN ----------

class _LocationCard extends StatelessWidget {
  final String nombre;
  final String ciudad;
  final String direccion;
  final bool checked;
  final bool bloqueado;
  final VoidCallback onTap;

  const _LocationCard({
    required this.nombre,
    required this.ciudad,
    required this.direccion,
    required this.checked,
    required this.bloqueado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: bloqueado ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: bloqueado ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: checked
                ? Palette.secondary.withOpacity(0.07)
                : Palette.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: checked ? Palette.secondary : Colors.black12,
              width: checked ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: bloqueado ? null : (_) => onTap(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                activeColor: Palette.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (ciudad.isNotEmpty)
                      Text(
                        ciudad,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    Text(
                      direccion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (bloqueado)
                      const Text(
                        'Otra región / departamento',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (checked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Seleccionada para este pedido',
                          style: TextStyle(
                            fontSize: 11,
                            color: Palette.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- ESTADO SIN UBICACIONES ----------

class _EmptyLocations extends StatelessWidget {
  const _EmptyLocations();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.card,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 48,
                color: Palette.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No tienes ubicaciones guardadas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega una nueva dirección desde tu perfil o sección de ubicaciones para poder asociarla a tu pedido.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Palette.ink.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
