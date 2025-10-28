import 'package:flutter/material.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';

class DetalleProductoController extends ChangeNotifier {
  final DetalleProductoService _service = DetalleProductoService();

  List<DetalleProducto> detalleProductos = [];
  List<DetalleProducto> detalleFiltrados = [];

  bool isLoading = false;

  // Cargar detalles desde el backend
  Future<void> cargarDetalleProductos() async {
    isLoading = true;
    notifyListeners();

    try {
      detalleProductos = await _service.getDetalleProductos();
      detalleFiltrados = detalleProductos;
    } catch (e) {
      debugPrint('❌ Error al cargar detalles de producto: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // Crear detalle
  Future<void> crearDetalleProducto(DetalleProducto detalle) async {
    await _service.createDetalleProducto(detalle);
    await cargarDetalleProductos();
  }

  // Actualizar detalle
  Future<void> actualizarDetalleProducto(int id, DetalleProducto detalle) async {
    await _service.updateDetalleProducto(id, detalle);
    await cargarDetalleProductos();
  }

  // Eliminar detalle
  Future<void> eliminarDetalleProducto(int id) async {
    await _service.deleteDetalleProducto(id);
    await cargarDetalleProductos();
  }

  // Filtrar por atributo o valor
  void filtrarDetalle(String query) {
    if (query.isEmpty) {
      detalleFiltrados = detalleProductos;
    } else {
      detalleFiltrados = detalleProductos
          .where((d) =>
              d.atributo.toLowerCase().contains(query.toLowerCase()) ||
              d.valor.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
