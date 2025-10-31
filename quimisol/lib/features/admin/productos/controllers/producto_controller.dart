import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/categorias/categoria_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';

class ProductoController extends ChangeNotifier {
  final ProductoService _service = ProductoService();
  final CategoriaService _categoriaService = CategoriaService();

  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];
  List<Categoria> categorias = []; // ✅ categorías reales

  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  int? categoriaSeleccionada;
  OrdenProducto ordenActual = OrdenProducto.nombreAZ;

  bool isLoading = false;

  // 🟣 Buscar con debounce
  void onSearchChanged(VoidCallback callback) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), callback);
  }

  // 🟣 Cambiar filtros
  void cambiarCategoria(int? id) {
    categoriaSeleccionada = id;
    filtrarProductos();
  }

  void cambiarOrden(OrdenProducto nuevoOrden) {
    ordenActual = nuevoOrden;
    filtrarProductos();
  }

  // 🟣 Lógica combinada de búsqueda + categoría + orden
  void filtrarProductos() {
    final query = searchController.text.toLowerCase();

    productosFiltrados = productos.where((p) {
      final matchesText = p.nombre.toLowerCase().contains(query) ||
          p.codigo.toLowerCase().contains(query);
      final matchesCategoria =
          categoriaSeleccionada == null || p.idcategoria == categoriaSeleccionada;
      return matchesText && matchesCategoria;
    }).toList();

    switch (ordenActual) {
      case OrdenProducto.precioAsc:
        productosFiltrados.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case OrdenProducto.precioDesc:
        productosFiltrados.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case OrdenProducto.nombreAZ:
        productosFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case OrdenProducto.nombreZA:
        productosFiltrados.sort((a, b) => b.nombre.compareTo(a.nombre));
        break;
    }

    notifyListeners();
  }

  // 🟣 Cargar productos y categorías desde backend
  Future<void> cargarProductos() async {
    isLoading = true;
    notifyListeners();

    try {
      productos = await _service.getProductos();
      await cargarCategorias(); // ✅ también carga las categorías
      filtrarProductos();
    } catch (e) {
      debugPrint('❌ Error al cargar productos: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> cargarCategorias() async {
    try {
      categorias = await _categoriaService.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error al cargar categorías: $e");
    }
  }

  // 🟣 Crear / actualizar / eliminar
  Future<void> crearProducto(Producto producto) async {
    await _service.createProducto(producto);
    await cargarProductos();
  }

  Future<void> actualizarProducto(int id, Producto producto) async {
    await _service.updateProducto(id, producto);
    await cargarProductos();
  }

  Future<void> eliminarProducto(int id) async {
    await _service.deleteProducto(id);
    await cargarProductos();
  }
}

// 🔄 Enum para ordenamiento
enum OrdenProducto { precioAsc, precioDesc, nombreAZ, nombreZA }
