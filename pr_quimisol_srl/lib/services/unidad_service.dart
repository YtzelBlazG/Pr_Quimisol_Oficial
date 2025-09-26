import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unidad_model.dart';

class UnidadService {
  final String baseUrl = "http://localhost:3000/unidades";

  Future<List<Unit>> obtenerUnidades() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List datos = jsonDecode(response.body);
      return datos.map((e) => Unit.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener unidades');
    }
  }

  Future<void> crearUnidad(Unit unidad) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(unidad.toJson()),
    );
  }

  Future<void> actualizarUnidad(int id, Unit unidad) async {
    await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(unidad.toJson()),
    );
  }

  Future<void> eliminarUnidad(int id) async {
    await http.delete(Uri.parse('$baseUrl/$id'));
  }
}
