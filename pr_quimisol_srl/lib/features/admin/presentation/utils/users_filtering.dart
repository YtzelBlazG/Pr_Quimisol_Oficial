import 'package:quimisol/core/services/postgresql/user_admin/user_admin_service.dart';

List<UserAdminView> filterAndSortUsers(
  List<UserAdminView> all, {
  required String query,
  required String? role,
  required bool? activo,
  required String sort, // nombre|correo|rol
}) {
  final q = query.trim().toLowerCase();

  bool matches(UserAdminView v) {
    final u = v.usuario;
    final p = v.persona;
    final ubic = v.ubicaciones;

    final displayName = (p?.nombreCompleto.isNotEmpty == true)
        ? p!.nombreCompleto
        : (u.username ?? u.email);

    final textOk = q.isEmpty ||
        displayName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        (u.username ?? '').toLowerCase().contains(q) ||
        (u.rol ?? '').toLowerCase().contains(q) ||
        ((p?.telefono ?? '').toLowerCase().contains(q)) ||
        ubic.any((ub) =>
            (ub.nombre ?? '').toLowerCase().contains(q) ||
            (ub.ciudad ?? '').toLowerCase().contains(q) ||
            (ub.direccion ?? '').toLowerCase().contains(q));

    final roleOk = role == null || (u.rol ?? '').toLowerCase() == role;
    final actOk = activo == null || u.activo == activo;

    return textOk && roleOk && actOk;
  }

  int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  final out = all.where(matches).toList();
  out.sort((a, b) {
    final ua = a.usuario, ub = b.usuario;
    final pa = a.persona, pb = b.persona;
    switch (sort) {
      case 'correo':
        return cmp(ua.email, ub.email);
      case 'rol':
        return cmp(ua.rol ?? '', ub.rol ?? '');
      case 'nombre':
      default:
        final na = (pa?.nombreCompleto.isNotEmpty ?? false)
            ? pa!.nombreCompleto
            : (ua.username ?? ua.email);
        final nb = (pb?.nombreCompleto.isNotEmpty ?? false)
            ? pb!.nombreCompleto
            : (ub.username ?? ub.email);
        return cmp(na, nb);
    }
  });

  return out;
}
