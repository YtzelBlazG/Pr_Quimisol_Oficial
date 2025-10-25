import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/user_admin/user_admin_service.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/quick_action.dart';

class UserGlassTile extends StatefulWidget {
  final UserAdminView view;
  final VoidCallback? onChanged;
  const UserGlassTile({
    super.key,
    required this.view,
    this.onChanged,
  });

  @override
  State<UserGlassTile> createState() => _UserGlassTileState();
}

class _UserGlassTileState extends State<UserGlassTile> {
  // Servicio via DI
  late final UserAdminService _svc = Modular.get<UserAdminService>();
  bool _expanded = false;

  String _displayName(UserAdminView v) {
    final u = v.usuario;
    final p = v.persona;
    return (p?.nombreCompleto.isNotEmpty == true)
        ? p!.nombreCompleto
        : (u.username ?? u.email);
  }

  String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final u = v.usuario;
    final p = v.persona;
    final ubic = v.ubicaciones;
    final name = _displayName(v);

    return Glass(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Palette.primary.withOpacity(.12),
                    child: Text(
                      _initials(name),
                      style: TextStyle(
                        color: Palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // nombre + chips
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _RoleChip(rol: u.rol),
                            const SizedBox(width: 6),
                            _ActivoChip(activo: u.activo),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // correo (sin ID)
                        Text(
                          u.email,
                          style: const TextStyle(color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar usuario',
                        icon: const Icon(Icons.edit, color: Colors.black54),
                        onPressed: _openEditSheet,
                      ),
                      IconButton(
                        tooltip: 'Eliminar usuario',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: _confirmDelete,
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ],
              ),

              // acciones rápidas (solo copiar correo)
              const SizedBox(height: 10),
              Row(
                children: [
                  QuickAction(
                    icon: Icons.copy_rounded,
                    label: 'Copiar correo',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: u.email));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Correo copiado')),
                      );
                    },
                  ),
                ],
              ),

              // contenido expandible
              if (_expanded) ...[
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 10),
                _kv('Usuario', u.username ?? '—'),
                _kv('Rol', _rolLabel(u.rol)),
                _kv(
                  'Estado',
                  u.activo == null ? '—' : (u.activo! ? 'Activo' : 'Inactivo'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Persona',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (p == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 2),
                    child: Text(
                      '— sin persona asociada —',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else ...[
                  _kv('Nombre',
                      p.nombreCompleto.isNotEmpty ? p.nombreCompleto : '—'),
                  _kv('Teléfono', p.telefono ?? '—'),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ubicaciones (${ubic.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (ubic.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 2),
                    child: Text(
                      '— sin ubicaciones —',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  ...ubic.map(
                    (u) => Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place,
                              size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.nombre ?? u.direccion ?? '(sin nombre)',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((u.direccion ?? '').isNotEmpty)
                                  Text(
                                    u.direccion!,
                                    style:
                                        const TextStyle(color: Colors.black87),
                                  ),
                                Text(
                                  'Ciudad: ${(u.ciudad ?? "—")}',
                                  style:
                                      const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- Editar ----
  void _openEditSheet() {
    final u = widget.view.usuario;

    final emailCtrl = TextEditingController(text: u.email);
    final usernameCtrl = TextEditingController(text: u.username ?? '');
    String rol = (u.rol ?? '').toLowerCase().trim();
    if (rol != 'admin' && rol != 'cliente') rol = 'cliente';
    bool activo = u.activo ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'Editar usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _editDeco('Correo'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameCtrl,
                    decoration: _editDeco('Username'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: _editDeco('Rol'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: rol,
                              items: const [
                                DropdownMenuItem(
                                    value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(
                                    value: 'cliente', child: Text('Cliente')),
                              ],
                              onChanged: (v) => setM(() => rol = v ?? 'cliente'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Activo'),
                          value: activo,
                          onChanged: (v) => setM(() => activo = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          onPressed: () async {
                            try {
                              await _svc.updateUsuario(
                                u.idUsuario,
                                email: emailCtrl.text.trim(),
                                username: usernameCtrl.text.trim().isEmpty
                                    ? null
                                    : usernameCtrl.text.trim(),
                                rol: rol,
                                activo: activo,
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Usuario actualizado')),
                              );
                              widget.onChanged?.call();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error al actualizar: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _editDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFDDE2E7)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFDDE2E7)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.primary),
        ),
      );

  // ---- Eliminar ----
  void _confirmDelete() async {
    final u = widget.view.usuario;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Seguro que deseas eliminar a "${u.email}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _svc.deleteUsuario(u.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _rolLabel(String? r) {
    final rr = (r ?? '').toLowerCase().trim();
    if (rr == 'admin') return 'Admin';
    if (rr == 'cliente') return 'Cliente';
    return r ?? '—';
  }
}

class _RoleChip extends StatelessWidget {
  final String? rol;
  const _RoleChip({this.rol});
  @override
  Widget build(BuildContext context) {
    final r = (rol ?? '').toLowerCase().trim();
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (r) {
      case 'admin':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = 'Admin';
        break;
      case 'cliente':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        label = 'Cliente';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = Colors.black87;
        label = (rol ?? '—');
    }

    return Chip(
      backgroundColor: bg,
      label:
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}

class _ActivoChip extends StatelessWidget {
  final bool? activo;
  const _ActivoChip({this.activo});

  @override
  Widget build(BuildContext context) {
    if (activo == null) {
      return const Chip(
        backgroundColor: Color(0xFFF3F4F6),
        label: Text('—'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    final isOk = activo!;
    return Chip(
      avatar: Icon(isOk ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
      label: Text(isOk ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: isOk ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
            fontWeight: FontWeight.w600,
          )),
      backgroundColor: isOk ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
