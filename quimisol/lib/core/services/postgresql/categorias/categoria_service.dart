import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';

class CategoriaService {
  final String baseUrl = "http://localhost:3005/categorias";

  Future<List<Categoria>> obtenerCategorias() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List datos = jsonDecode(response.body);
      return datos.map((e) => Categoria.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

  Future<void> crearCategoria(Categoria categoria) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(categoria.toJson()),
    );
  }

  Future<void> actualizarCategoria(int id, Categoria categoria) async {
    await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(categoria.toJson()),
    );
  }

  Future<void> eliminarCategoria(int id) async {
    await http.delete(Uri.parse('$baseUrl/$id'));
  }
}