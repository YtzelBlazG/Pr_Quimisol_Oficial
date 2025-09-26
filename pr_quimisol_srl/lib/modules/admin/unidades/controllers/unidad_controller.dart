import 'package:flutter/material.dart';
import '../../../../models/unidad_model.dart';
import '../../../../services/unidad_service.dart';

class UnidadController extends ChangeNotifier {
  final UnidadService _servicio = UnidadService();

  List<Unit> unidades = [];
  bool cargando = false;

  Future<void> cargarUnidades() async {
    cargando = true;
    notifyListeners();

    unidades = await _servicio.obtenerUnidades();

    cargando = false;
    notifyListeners();
  }

  Future<void> agregarUnidad(Unit unidad) async {
    await _servicio.crearUnidad(unidad);
    await cargarUnidades();
  }

  Future<void> editarUnidad(int id, Unit unidad) async {
    await _servicio.actualizarUnidad(id, unidad);
    await cargarUnidades();
  }

  Future<void> borrarUnidad(int id) async {
    await _servicio.eliminarUnidad(id);
    await cargarUnidades();
  }
}
