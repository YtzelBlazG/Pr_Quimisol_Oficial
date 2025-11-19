// lib/features/locations/screens/locations_list_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';

// IMPORTANTE: LocationViewerPage
import 'package:quimisol/features/locations/screens/location_edit_page.dart';

class LocationsListPage extends StatefulWidget {
  const LocationsListPage({super.key});

  @override
  State<LocationsListPage> createState() => _LocationsListPageState();
}

class _LocationsListPageState extends State<LocationsListPage> {
  late final LocationsService _svc;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int? _idPersona;

  // Polling “tiempo real” (cliente)
  static const Duration _pollEvery = Duration(seconds: 8);
  Timer? _poller;
  bool _pollingNow = false;

  @override
  void initState() {
    super.initState();
    _svc = LocationsService(baseUrl: Env.apiBaseUrl);
    _init();
  }

  Future<void> _init() async {
    await _load(initial: true);
    _startPolling();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(_pollEvery, (_) async {
      if (!mounted || _pollingNow) return;
      _pollingNow = true;
      try {
        await _load(silent: true);
      } finally {
        _pollingNow = false;
      }
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  // =========================
  // Carga y helpers
  // =========================
  Future<void> _load({bool initial = false, bool silent = false}) async {
    if (initial && mounted) setState(() => _loading = true);

    _idPersona ??= await AuthStorage.getIdPersona();
    if (_idPersona == null) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
      return;
    }

    try {
      final fresh = await _svc.listByPersona(_idPersona!);

      final oldJson = jsonEncode(_items);
      final newJson = jsonEncode(fresh);
      if (oldJson != newJson) {
        if (mounted) setState(() => _items = fresh);
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e')),
        );
      }
    } finally {
      if (initial && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final backup = List<Map<String, dynamic>>.from(_items);
    setState(() {
      _items = _items.where((e) => (e['idubicacion'] as int) != id).toList();
    });
    try {
      await _svc.delete(id);
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = backup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return double.nan;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? double.nan;
    return double.nan;
  }

  void _openOnMap(Map<String, dynamic> it) {
    final lat = _toDouble(it['latitud']);
    final lng = _toDouble(it['longitud']);
    if (lat.isNaN || lng.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas inválidas')),
      );
      return;
    }

    Modular.to
        .push(
          MaterialPageRoute(
            builder: (_) => LocationViewerPage(
              idubicacion: it['idubicacion'] as int,
              nombre: (it['nombre'] ?? '').toString(),
              direccion: (it['direccion'] ?? '').toString(),
              ciudad: (it['ciudad'] ?? '').toString(),
              latitud: lat,
              longitud: lng,
            ),
          ),
        )
        .then((_) {
      _load(silent: true);
    });
  }

  Future<void> _goToAdd() async {
    await Modular.to.pushNamed('/locations/add');
    await _load(silent: true);
  }

  // =========================
  // Agrupar por ciudad
  // =========================

  String _cityKeyOf(Map<String, dynamic> it) {
    final raw = (it['ciudad'] ?? '').toString().trim();
    return raw.isEmpty ? '_sin_ciudad' : raw.toLowerCase();
  }

  Map<String, _CityGroup> _groupByCity(List<Map<String, dynamic>> items) {
    final map = <String, _CityGroup>{};

    for (final it in items) {
      final key = _cityKeyOf(it);
      final displayName = (() {
        final raw = (it['ciudad'] ?? '').toString().trim();
        return raw.isEmpty ? 'Sin ciudad' : raw;
      })();

      map.putIfAbsent(key, () => _CityGroup(displayName, []));
      map[key]!.items.add(it);
    }

    for (final g in map.values) {
      g.items.sort((a, b) {
        final an = (a['nombre'] ?? '').toString();
        final bn = (b['nombre'] ?? '').toString();
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });
    }

    return map;
  }

  List<Widget> _buildGroupedList(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = const Color(0xFFF48FB1); // 🌸 Rosa suave

    final groups = _groupByCity(_items);

    final orderedKeys = groups.keys.toList()
      ..sort(
        (a, b) => groups[a]!.display
            .toLowerCase()
            .compareTo(groups[b]!.display.toLowerCase()),
      );

    final widgets = <Widget>[];

    for (final key in orderedKeys) {
      final g = groups[key]!;
      final count = g.items.length;
      final title =
          '${g.display} (${count == 1 ? '1 sucursal' : '$count sucursales'})';

      // Encabezado de sección
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Tarjetas de la ciudad
      for (final it in g.items) {
        final nombre = (it['nombre'] ?? '').toString();
        final direccion = (it['direccion'] ?? '').toString();

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              elevation: 1.5,
              shadowColor: Colors.black.withOpacity(0.08),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openOnMap(it),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.place_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre.isEmpty ? 'Ubicación sin nombre' : nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (direccion.isNotEmpty)
                              Text(
                                direccion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.error.withOpacity(0.9),
                        ),
                        tooltip: 'Eliminar ubicación',
                        onPressed: () => _delete(it['idubicacion'] as int),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    widgets.add(const SizedBox(height: 96));
    return widgets;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = const Color(0xFFF48FB1); // 🌸 Rosa suave

    return Scaffold(
      backgroundColor: colors.surfaceVariant.withOpacity(0.25),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Mis ubicaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF48FB1), // rosa suave
                Color.fromARGB(255, 253, 156, 189), // rosa un poco más fuerte
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(silent: true),
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: ListEmpty(onAddPressed: _goToAdd),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth =
                            constraints.maxWidth > 720 ? 720.0 : null;
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxWidth ?? double.infinity,
                            ),
                            child: ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              children: [
                                _HeaderSummary(
                                  total: _items.length,
                                ),
                                const SizedBox(height: 8),
                                ..._buildGroupedList(context),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Agregar ubicación'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        onPressed: _goToAdd,
      ),
    );
  }
}

class ListEmpty extends StatelessWidget {
  final VoidCallback onAddPressed;

  const ListEmpty({
    super.key,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = const Color(0xFFF48FB1); // 🌸 Rosa suave

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 72,
              color: accent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes ubicaciones guardadas',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade tus sucursales o direcciones frecuentes para encontrarlas rápidamente en el mapa y usarlas en tus pedidos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Agregar primera ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final int total;

  const _HeaderSummary({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = const Color(0xFFF48FB1); // 🌸 Rosa suave

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus ubicaciones guardadas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Aún no has agregado ninguna ubicación'
                      : '$total ${total == 1 ? 'ubicación' : 'ubicaciones'} registradas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
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

class _CityGroup {
  final String display;
  final List<Map<String, dynamic>> items;
  _CityGroup(this.display, this.items);
}
