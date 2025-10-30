import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/services/postgresql/user_admin/user_admin_service.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/user_glass_title.dart';

import 'package:quimisol/features/admin/presentation/utils/users_filtering.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/skeleton_list.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/error_view.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/empty_view.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/header_summary.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/search_filters_bar.dart';

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  // Servicio via DI
  late final UserAdminService _svc = Modular.get<UserAdminService>();

  final _searchCtrl = TextEditingController();
  final _role = ValueNotifier<String?>(null); // null|admin|cliente
  final _activo = ValueNotifier<bool?>(null); // null|true|false
  String _sort = 'nombre'; // nombre|correo|rol

  bool _loading = true;
  String? _error;

  List<UserAdminView> _all = [];
  List<UserAdminView> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
    _role.addListener(_applyFilters);
    _activo.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _role.dispose();
    _activo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _svc.fetchAll();
      if (!mounted) return;
      setState(() => _all = data);
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar los usuarios.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    _filtered = filterAndSortUsers(
      _all,
      query: _searchCtrl.text,
      role: _role.value,
      activo: _activo.value,
      sort: _sort,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Palette.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text('Gestión de usuarios'),
          foregroundColor: Palette.primary,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          color: Palette.white,
          child: _loading
              ? const SkeletonList()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        HeaderSummary(
                          total: _all.length,
                          activos:
                              _all.where((v) => v.usuario.activo == true).length,
                        ),
                        const SizedBox(height: 12),
                        SearchFiltersBar(
                          searchCtrl: _searchCtrl,
                          role: _role,
                          activo: _activo,
                          sort: _sort,
                          onSortChanged: (v) {
                            setState(() => _sort = v);
                            _applyFilters();
                          },
                          shown: _filtered.length,
                          total: _all.length,
                        ),
                        const SizedBox(height: 12),
                        if (_filtered.isEmpty)
                          const EmptyView(
                            title: 'Sin resultados',
                            subtitle:
                                'Prueba limpiar filtros o cambiar los términos de búsqueda.',
                          )
                        else
                          ..._filtered.map(
                            (v) => UserGlassTile(
                              view: v,
                              onChanged: _load,
                            ),
                          ),
                      ],
                    ),
        ),
      );
  }
}
