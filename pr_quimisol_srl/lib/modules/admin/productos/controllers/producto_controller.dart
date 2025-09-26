import 'package:flutter/material.dart';
import '../../../../models/producto_model.dart';
import '../../../../services/producto_service.dart';

class ProductoController extends ChangeNotifier {
  final ProductoService _service = ProductoService();

  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];

  bool isLoading = false;

  // Cargar productos desde el backend
  Future<void> cargarProductos() async {
    isLoading = true;
    notifyListeners();

    try {
      productos = await _service.getProductos();
      productosFiltrados = productos;
    } catch (e) {
      debugPrint('❌ Error al cargar productos: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Crear producto
  Future<void> crearProducto(Producto producto) async {
    await _service.createProducto(producto);
    await cargarProductos();
  }

  // Actualizar producto
  Future<void> actualizarProducto(int id, Producto producto) async {
    await _service.updateProducto(id, producto);
    await cargarProductos();
  }

  // Eliminar producto
  Future<void> eliminarProducto(int id) async {
    await _service.deleteProducto(id);
    await cargarProductos();
  }

  // Filtrar productos por nombre
  void filtrarProductos(String query) {
    if (query.isEmpty) {
      productosFiltrados = productos;
    } else {
      productosFiltrados = productos
          .where((p) =>
              p.nombre.toLowerCase().contains(query.toLowerCase()) ||
              p.codigo.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
