// lib/core/services/postgresql/rest/locations_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationsService {
  final String baseUrl;
  LocationsService({required this.baseUrl});

  /// GET /ubicaciones/:idpersona
  Future<List<Map<String, dynamic>>> listLocations(int idPersona) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idPersona');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception(
        'Error al listar ubicaciones (${res.statusCode}): ${res.body}',
      );
    }

    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// POST /ubicaciones/:idpersona
  /// Campos requeridos: nombre, ciudad, direccion
  /// Opcionales: latitud, longitud
  Future<Map<String, dynamic>> createLocation({
    required int idUsuario, // idpersona
    required String nombre,
    required String ciudad,
    required String direccion,
    double? latitud,
    double? longitud,
  }) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idUsuario');

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
      throw Exception(
        'Error al crear ubicación (${res.statusCode}): ${res.body}',
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// PUT /ubicaciones/:idubicacion
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
      throw Exception(
        'Error al actualizar ubicación (${res.statusCode}): ${res.body}',
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// DELETE /ubicaciones/:idubicacion
  Future<void> deleteLocation(int idUbicacion) async {
    final uri = Uri.parse('$baseUrl/ubicaciones/$idUbicacion');
    final res = await http.delete(uri);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Error al eliminar ubicación (${res.statusCode}): ${res.body}',
      );
    }
  }
}
