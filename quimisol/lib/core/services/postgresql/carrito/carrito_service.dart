import 'dart:convert';
import 'package:http/http.dart' as http;

class CarritoService {
  static const String _baseUrl = 'http://10.192.87.85:3005';

  /// ➕ Agregar producto al carrito
  static Future<bool> agregarProductoAlCarrito({
    required int idUsuario,
    required int idProducto,
    required int cantidad,
  }) async {
    final url = Uri.parse('$_baseUrl/carrito');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idusuario': idUsuario,
        'idproducto': idProducto,
        'cantidad': cantidad,
      }),
    );

    if (response.statusCode == 201) return true;

    if (response.statusCode == 409) {
      throw Exception('No hay suficiente stock disponible');
    }

    throw Exception('Error al añadir al carrito');
  }

  /// 🛒 Obtener productos del carrito por ID de usuario
  static Future<List<dynamic>> obtenerCarrito(int idUsuario) async {
    final url = Uri.parse('$_baseUrl/carrito/$idUsuario');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Error al obtener el carrito');
  }

  /// ❌ Eliminar producto del carrito
  static Future<void> eliminarProductoDelCarrito({
    required int idUsuario,
    required int idProducto,
  }) async {
    final url = Uri.parse('$_baseUrl/carrito/$idUsuario/$idProducto');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 404) {
      throw Exception('Producto no encontrado en el carrito');
    }

    throw Exception('Error al eliminar producto del carrito');
  }
}
