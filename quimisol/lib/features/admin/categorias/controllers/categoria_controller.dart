import 'package:flutter/material.dart';
import 'package:quimisol/core/services/postgresql/categorias/categoria_service.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';

class CategoriaController extends ChangeNotifier {
  final CategoriaService _servicio = CategoriaService();

  List<Categoria> categorias = [];
  bool cargando = false;

  Future<void> cargarCategorias() async {
    cargando = true;
    notifyListeners();

    categorias = await _servicio.obtenerCategorias();

    cargando = false;
    notifyListeners();
  }

  Future<void> agregarCategoria(Categoria categoria) async {
    await _servicio.crearCategoria(categoria);
    await cargarCategorias();
  }

  Future<void> editarCategoria(int id, Categoria categoria) async {
    await _servicio.actualizarCategoria(id, categoria);
    await cargarCategorias();
  }

  Future<void> borrarCategoria(int id) async {
    await _servicio.eliminarCategoria(id);
    await cargarCategorias();
  }
}
