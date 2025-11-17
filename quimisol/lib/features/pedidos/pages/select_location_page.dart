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

  double? _carritoTotal; // total base del carrito (Bs)

  // 🔒 Departamento “bloqueado” (el de la primera ubicación seleccionada)
  String? _departamentoSeleccionadoNorm;   // en minúsculas para comparar
  String? _departamentoSeleccionadoLabel;  // para mostrar en UI

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
      // ubicaciones + total del carrito en paralelo
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

  /// Llama a GET /carrito/:idUsuario para obtener el total del carrito
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

  /// Intenta obtener el “departamento” de la ubicación.
  /// Usa primero 'departamento', luego 'depto', y si no hay, cae a 'ciudad'.
  String _normalizarDepartamento(Map<String, dynamic> it) {
    final raw = (it['departamento'] ??
            it['depto'] ??
            it['ciudad'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    return raw;
  }

  /// Versión “bonita” para mostrar (usamos el valor tal cual haya venido).
  String _labelDepartamento(Map<String, dynamic> it) {
    final raw = (it['departamento'] ??
            it['depto'] ??
            it['ciudad'] ??
            '')
        .toString()
        .trim();
    return raw.isEmpty ? 'Departamento' : raw;
  }

  void _toggle(Map<String, dynamic> it) {
    final idUbicacion = (it['idubicacion'] as num).toInt();
    final depNorm = _normalizarDepartamento(it);
    final depLabel = _labelDepartamento(it);

    // Si ya está seleccionada → desmarcar
    if (_selected.contains(idUbicacion)) {
      setState(() {
        _selected.remove(idUbicacion);
        // Si ya no queda ninguna ubicación seleccionada, liberamos el filtro
        if (_selected.isEmpty) {
          _departamentoSeleccionadoNorm = null;
          _departamentoSeleccionadoLabel = null;
        }
      });
      return;
    }

    // Si ya hay un departamento "lockeado" y este es de otro departamento → bloquear
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

    // Si es la primera ubicación seleccionada, fijamos el departamento
    setState(() {
      if (_departamentoSeleccionadoNorm == null && depNorm.isNotEmpty) {
        _departamentoSeleccionadoNorm = depNorm;
        _departamentoSeleccionadoLabel = depLabel;
      }
      _selected.add(idUbicacion);
    });
  }

  /// 1) Crea el pedido desde el carrito.
  /// 2) Guarda las ubicaciones seleccionadas para ese pedido.
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

      // 1) Crear pedido desde carrito
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
              content: Text('No se pudo obtener el ID del pedido')),
        );
        return;
      }

      // 2) Guardar ubicaciones para ese pedido
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

      // Éxito total
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido #$idPedido creado y ubicaciones asociadas correctamente ✅',
          ),
        ),
      );

      Navigator.of(context).pop(true); // devolvemos "true" al CarritoPage
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear pedido / guardar ubicaciones: $e')),
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
    final bgColor = const Color(0xfff8f6fb);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Seleccionar ubicaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No tienes ubicaciones guardadas.\nAgrega una para continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selected.isEmpty
                                      ? 'Elige una o varias direcciones donde quieres recibir este pedido.'
                                      : '${_selected.length} ubicación(es) seleccionada(s).',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_departamentoSeleccionadoLabel != null)
                                  Text(
                                    'Solo se permiten ubicaciones del departamento: $_departamentoSeleccionadoLabel.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (_carritoTotal != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _totalConUbicaciones == null
                                        ? 'Total del carrito: Bs ${_carritoTotal!.toStringAsFixed(2)}'
                                        : 'Total estimado (${_selected.length} ubicación(es)): Bs ${_totalConUbicaciones!.toStringAsFixed(2)}',
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
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemBuilder: (_, i) {
                          final it = _items[i];
                          final id = (it['idubicacion'] as num).toInt();
                          final nombre = (it['nombre'] ?? '').toString().trim();
                          final direccion =
                              (it['direccion'] ?? '').toString().trim();
                          final ciudad =
                              (it['ciudad'] ?? '').toString().trim();
                          final checked = _selected.contains(id);

                          final depNorm = _normalizarDepartamento(it);
                          final bloqueado =
                              _departamentoSeleccionadoNorm != null &&
                                  depNorm.isNotEmpty &&
                                  depNorm != _departamentoSeleccionadoNorm;

                          return GestureDetector(
                            onTap: () {
                              if (bloqueado) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No puedes seleccionar esta dirección porque es de otro departamento.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _toggle(it);
                            },
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 160),
                              opacity: bloqueado ? 0.45 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? Palette.secondary.withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: checked
                                        ? Palette.secondary
                                        : Colors.black12,
                                    width: checked ? 1.4 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black12.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        onChanged: bloqueado
                                            ? null
                                            : (_) => _toggle(it),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        activeColor: Palette.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    nombre.isEmpty
                                                        ? 'Ubicación'
                                                        : nombre,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.place_outlined,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (ciudad.isNotEmpty)
                                              Text(
                                                ciudad,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
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
                                            if (bloqueado) ...[
                                              const SizedBox(height: 6),
                                              const Text(
                                                'Otra región / departamento',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ] else if (checked) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Palette.secondary
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'Seleccionada para este pedido',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Palette.secondary,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemCount: _items.length,
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
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
                          _totalConUbicaciones == null
                              ? 'Total del carrito: Bs ${_carritoTotal!.toStringAsFixed(2)}'
                              : 'Total estimado (${_selected.length} ubicación(es)): Bs ${_totalConUbicaciones!.toStringAsFixed(2)}',
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
                        backgroundColor: Palette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
