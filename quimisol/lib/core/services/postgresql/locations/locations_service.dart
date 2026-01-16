// lib/core/services/postgresql/locations/locations_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Endpoints esperados en tu API Node:
///   GET    /ubicaciones/:idpersona
///   POST   /ubicaciones/:idpersona
///   PUT    /ubicaciones/:idubicacion
///   DELETE /ubicaciones/:idubicacion
class LocationsService {
  final String baseUrl;
  LocationsService({required this.baseUrl});

  // ===========================
  // API "nueva" (nombres claros)
  // ===========================

  /// Lista ubicaciones por ID de persona
  Future<List<Map<String, dynamic>>> listLocations(int idPersona) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idPersona');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error al listar ubicaciones (${res.statusCode}): ${res.body}');
    }
    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Crea una ubicación
  Future<Map<String, dynamic>> createLocation({
    required int idPersona,
    required String nombre,
    required String ciudad,
    required String direccion,
    double? latitud,
    double? longitud,
  }) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idPersona');
    final payload = <String, dynamic>{
      'nombre': nombre,
      'ciudad': ciudad,
      'direccion': direccion,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error al crear ubicación (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Actualiza una ubicación
  Future<Map<String, dynamic>> updateLocation({
    required int idUbicacion,
    required String nombre,
    required String ciudad,
    required String direccion,
    double? latitud,
    double? longitud,
  }) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idUbicacion');
    final payload = <String, dynamic>{
      'nombre': nombre,
      'ciudad': ciudad,
      'direccion': direccion,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al actualizar ubicación (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Elimina (soft-delete) una ubicación
  Future<void> deleteLocation(int idUbicacion) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idUbicacion');
    final res = await http.delete(uri);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Error al eliminar ubicación (${res.statusCode}): ${res.body}');
    }
  }

  // ==========================================
  // API "antigua" (aliases para compatibilidad)
  // ==========================================

  /// Alias de listLocations(...)
  Future<List<Map<String, dynamic>>> listByPersona(int idPersona) {
    return listLocations(idPersona);
  }

  /// Alias de createLocation(...) con la misma firma que usas en AddLocation
  Future<Map<String, dynamic>> create({
    required int idPersona,
    required String nombre,
    required String ciudad,
    required String direccion,
    double? latitud,
    double? longitud,
  }) {
    return createLocation(
      idPersona: idPersona,
      nombre: nombre,
      ciudad: ciudad,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
    );
  }

  /// Alias de updateLocation(...)
  Future<Map<String, dynamic>> update({
    required int idUbicacion,
    required String nombre,
    required String ciudad,
    required String direccion,
    double? latitud,
    double? longitud,
  }) {
    return updateLocation(
      idUbicacion: idUbicacion,
      nombre: nombre,
      ciudad: ciudad,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
    );
  }

  /// Alias de deleteLocation(...)
  Future<void> delete(int idUbicacion) {
    return deleteLocation(idUbicacion);
  }
}
