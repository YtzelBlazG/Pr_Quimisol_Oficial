import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';
import 'package:quimisol/core/services/postgresql/person/person_service.dart';
import 'package:quimisol/core/services/postgresql/user/user_service.dart';

class AuthStorage {
  static const _kLoggedIn    = 'logged_in';
  static const _kNombre      = 'user_nombre';
  static const _kCorreo      = 'user_correo';
  static const _kTelefono    = 'user_telefono';
  static const _kIdPersona   = 'user_idpersona';
  static const _kRol         = 'user_rol';
  static const _kUbicaciones = 'user_ubicaciones';

  static final ValueNotifier<bool> loginStatus = ValueNotifier<bool>(false);

  /// Inicializa el estado de sesión
  static Future<void> init() async {
    loginStatus.value = await isLoggedIn();
  }

  /// Guardar datos del usuario
  static Future<void> saveUser({
    required String nombre,
    required String correo,
    int? idPersona,
    String? telefono,
    String rol = 'cliente',
    List<Map<String, dynamic>> ubicaciones = const [],
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, true);
    await p.setString(_kNombre, nombre);
    await p.setString(_kCorreo, correo);
    await p.setString(_kRol, rol);
    if (telefono != null) await p.setString(_kTelefono, telefono);
    if (idPersona != null) await p.setInt(_kIdPersona, idPersona);
    await p.setString(_kUbicaciones, jsonEncode(ubicaciones));
    loginStatus.value = true;
  }

  /// Borrar todo al cerrar sesión
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    loginStatus.value = false;
  }

  /// ¿Está logueado?
  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<String?> getNombre() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kNombre);
  }

  static Future<String?> getCorreo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kCorreo);
  }

  static Future<String?> getTelefono() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kTelefono);
  }

  static Future<int?> getIdPersona() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kIdPersona);
  }

  static Future<String?> getRol() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRol);
  }

  static Future<List<Map<String, dynamic>>> getUbicaciones() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kUbicaciones);
    if (raw == null || raw.isEmpty) return [];

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (e) {
      debugPrint('⚠️ Error parseando ubicaciones: $e');
      return [];
    }
  }

  /// Refrescar datos desde la base de datos
  static Future<void> refreshFromDatabase({
    required int idPersona,
    required String baseUrl,
  }) async {
    final personService = PersonService(baseUrl: baseUrl);
    final userService   = UserService(baseUrl: baseUrl);
    final locService    = LocationsService(baseUrl: baseUrl);

    final person = await personService.getPerson(idPersona);
    final user   = await userService.getUser(idPersona);
    final ubic   = await locService.listLocations(idPersona);

    await saveUser(
      nombre: person?.name ?? '',
      telefono: person?.phone,
      correo: user?.correo ?? '',
      idPersona: idPersona,
      rol: user?.rol ?? 'cliente',
      ubicaciones: ubic,
    );

    debugPrint("✅ Datos refrescados desde DB y guardados en AuthStorage");
  }

  /// Ver datos (debugging)
  static Future<void> debugPrintData() async {
    final nombre   = await getNombre();
    final correo   = await getCorreo();
    final tel      = await getTelefono();
    final id       = await getIdPersona();
    final rol      = await getRol();

    debugPrint("======= AUTH STORAGE DATA =======");
    debugPrint("Nombre   : $nombre");
    debugPrint("Correo   : $correo");
    debugPrint("Teléfono : $tel");
    debugPrint("IdPersona: $id");
    debugPrint("Rol      : $rol");
    debugPrint("=================================");
  }

  /// Obtener todos los datos del usuario como Map
  static Future<Map<String, dynamic>> getUserData() async {
    final p = await SharedPreferences.getInstance();
    return {
      'nombre': p.getString(_kNombre),
      'correo': p.getString(_kCorreo),
      'telefono': p.getString(_kTelefono),
      'idpersona': p.getInt(_kIdPersona),
      'rol': p.getString(_kRol),
    };
  }

  /// Compara si el usuario actual es igual al que está en memoria
  static Future<bool> isSameUser(int? currentId) async {
    final storedId = await getIdPersona();
    return storedId == currentId;
  }
}
