import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';

class DetalleProductoService {
  final String baseUrl = 'http://localhost:3005/detalleproducto'; // ajusta si cambia

  // Obtener todos los detalles
  Future<List<DetalleProducto>> getDetalleProductos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => DetalleProducto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar detalles de producto');
    }
  }

  // Crear detalle
  Future<void> createDetalleProducto(DetalleProducto detalle) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(detalle.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear detalle del producto');
    }
  }

  // Obtener por ID
  Future<DetalleProducto> getDetalleProductoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return DetalleProducto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener detalle del producto');
    }
  }

  // Actualizar detalle
  Future<void> updateDetalleProducto(int id, DetalleProducto detalle) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(detalle.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar detalle del producto');
    }
  }

  // Eliminar detalle
  Future<void> deleteDetalleProducto(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar detalle del producto');
    }
  }
}
