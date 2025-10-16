import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';


class ProductoService {
  final String baseUrl = 'http://localhost:3005/productos'; // Ajusta si usas otro puerto

  // Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  // Crear producto
  Future<void> createProducto(Producto producto) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(producto.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear producto');
    }
  }

  // Obtener producto por ID
  Future<Producto> getProductoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener producto');
    }
  }

  // Actualizar producto
  Future<void> updateProducto(int id, Producto producto) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(producto.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar producto');
    }
  }

  // Eliminar producto
  Future<void> deleteProducto(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }
}
