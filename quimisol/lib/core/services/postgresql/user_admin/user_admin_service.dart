// core/services/postgresql/user_admin/user_admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/* =======================
 * DTOs / View
 * ======================= */

class UsuarioDto {
  final int idUsuario;
  final int? idPersona;
  final String email;
  final String? username;
  final String? rol;
  final bool? activo; // ← lo exponemos como bool para la UI

  UsuarioDto({
    required this.idUsuario,
    required this.idPersona,
    required this.email,
    this.username,
    this.rol,
    this.activo,
  });

  factory UsuarioDto.fromJson(Map<String, dynamic> j) => UsuarioDto(
        idUsuario: (j['idusuario'] ?? 0) as int,
        idPersona: j['idpersona'] as int?,
        email: (j['correo'] ?? '').toString(),
        username: j['username']?.toString(),
        rol: j['rol']?.toString(),
        // 👇 tu API manda `estado`
        activo: _toBoolEstado(j['estado']),
      );

  static bool? _toBoolEstado(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (['1', 'true', 't', 'activo', 'act', 'on', 'yes', 'si', 'sí'].contains(s)) return true;
    if (['0', 'false', 'f', 'inactivo', 'inact', 'off', 'no'].contains(s)) return false;
    return null;
  }
}

class PersonaDto {
  final int idPersona;
  final String? nombre;
  final String? telefono;

  PersonaDto({
    required this.idPersona,
    this.nombre,
    this.telefono,
  });

  factory PersonaDto.fromJson(Map<String, dynamic> j) => PersonaDto(
        idPersona: (j['idpersona'] ?? 0) as int,
        nombre: j['nombre']?.toString(),
        telefono: j['telefono']?.toString(),
      );

  String get nombreCompleto => (nombre ?? '').trim();
}

class UbicacionDto {
  final int? id; // idubicacion
  final String? nombre;
  final String? ciudad;
  final String? direccion;
  final double? latitud;
  final double? longitud;

  UbicacionDto({
    this.id,
    this.nombre,
    this.ciudad,
    this.direccion,
    this.latitud,
    this.longitud,
  });

  factory UbicacionDto.fromJson(Map<String, dynamic> j) => UbicacionDto(
        id: j['idubicacion'] as int?,
        nombre: j['nombre']?.toString(),
        ciudad: j['ciudad']?.toString(),
        direccion: j['direccion']?.toString(),
        latitud: (j['latitud'] is num) ? (j['latitud'] as num).toDouble() : null,
        longitud: (j['longitud'] is num) ? (j['longitud'] as num).toDouble() : null,
      );
}

class UserAdminView {
  final UsuarioDto usuario;
  final PersonaDto? persona;
  final List<UbicacionDto> ubicaciones;

  UserAdminView({
    required this.usuario,
    required this.persona,
    required this.ubicaciones,
  });
}

/* =======================
 * Service (real, sin mocks)
 * ======================= */

class UserAdminService {
  final String baseUrl;
  const UserAdminService({required this.baseUrl});

  Future<List<UserAdminView>> fetchAll() async {
    // 1) Usuarios
    final uRes = await http
        .get(Uri.parse('$baseUrl/usuarios'))
        .timeout(const Duration(seconds: 15));
    _ensure200(uRes, 'GET /usuarios');

    final decoded = jsonDecode(uRes.body);

    // ✅ Tolerante: acepta array directo o { items: [...] }
    final List rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map && decoded['items'] is List) {
      rawList = decoded['items'] as List;
    } else {
      throw Exception('GET /usuarios: respuesta no es lista');
    }

    final usuarios = rawList
        .map<UsuarioDto>((e) => UsuarioDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // 2) Para cada usuario, pedir persona + ubicaciones si tiene idPersona
    final views = await Future.wait(usuarios.map((u) async {
      PersonaDto? persona;
      List<UbicacionDto> ubicaciones = const [];

      if (u.idPersona != null) {
        final pF = http
            .get(Uri.parse('$baseUrl/personas/${u.idPersona}'))
            .timeout(const Duration(seconds: 12));
        final ubF = http
            .get(Uri.parse('$baseUrl/ubicaciones/${u.idPersona}'))
            .timeout(const Duration(seconds: 12));

        final resp = await Future.wait([pF, ubF]);

        // persona
        final pRes = resp[0];
        if (pRes.statusCode == 200) {
          final pj = jsonDecode(pRes.body);
          if (pj is Map) {
            persona = PersonaDto.fromJson(Map<String, dynamic>.from(pj));
          }
        }

        // ubicaciones
        final ubRes = resp[1];
        if (ubRes.statusCode == 200) {
          final body = jsonDecode(ubRes.body);
          final list = (body is List) ? body : [];
          ubicaciones = list
              .map((e) => UbicacionDto.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }

      return UserAdminView(usuario: u, persona: persona, ubicaciones: ubicaciones);
    }));

    return views;
  }

  // Helpers por ID
  Future<UsuarioDto?> getUsuario(int id) async {
    final res = await http
        .get(Uri.parse('$baseUrl/usuarios/$id'))
        .timeout(const Duration(seconds: 12));
    _ensure200(res, 'GET /usuarios/$id');
    final j = jsonDecode(res.body);
    if (j is! Map) throw Exception('GET /usuarios/$id: formato inválido');
    return UsuarioDto.fromJson(Map<String, dynamic>.from(j));
  }

  Future<PersonaDto?> getPersona(int idPersona) async {
    final res = await http
        .get(Uri.parse('$baseUrl/personas/$idPersona'))
        .timeout(const Duration(seconds: 12));
    _ensure200(res, 'GET /personas/$idPersona');
    final j = jsonDecode(res.body);
    if (j is! Map) throw Exception('GET /personas/$idPersona: formato inválido');
    return PersonaDto.fromJson(Map<String, dynamic>.from(j));
  }

  // === UPDATE /usuarios/:id ===
  Future<UsuarioDto> updateUsuario(
    int id, {
    String? email,
    String? username,
    String? rol,
    bool? activo,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['correo'] = email;
    if (username != null) body['username'] = username;
    if (rol != null) body['rol'] = rol;
    if (activo != null) {
      // tu API usa 'estado' (activo/inactivo). Enviamos string.
      body['estado'] = activo ? 'activo' : 'inactivo';
    }

    final res = await http
        .put(
          Uri.parse('$baseUrl/usuarios/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    _ensure200(res, 'PUT /usuarios/$id');
    final j = jsonDecode(res.body);
    if (j is! Map) throw Exception('PUT /usuarios/$id: formato inválido');
    return UsuarioDto.fromJson(Map<String, dynamic>.from(j));
  }

  // === DELETE /usuarios/:id ===
  Future<void> deleteUsuario(int id) async {
    final res = await http
        .delete(Uri.parse('$baseUrl/usuarios/$id'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('DELETE /usuarios/$id → HTTP ${res.statusCode}: ${res.body}');
    }
  }

  Future<List<UbicacionDto>> getUbicaciones(int idPersona) async {
    final res = await http
        .get(Uri.parse('$baseUrl/ubicaciones/$idPersona'))
        .timeout(const Duration(seconds: 12));
    _ensure200(res, 'GET /ubicaciones/$idPersona');
    final body = jsonDecode(res.body);
    final list = (body is List) ? body : [];
    return list
        .map((e) => UbicacionDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _ensure200(http.Response r, String where) {
    if (r.statusCode != 200) {
      throw Exception('$where → HTTP ${r.statusCode}: ${r.body}');
    }
  }
}
