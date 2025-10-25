import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quimisol/core/storage/auth_storage.dart';

class FavoritosProvider extends ChangeNotifier {
  int? _idUsuario;
  List<Map<String, dynamic>> _favoritos = [];
  bool _loading = false;

  List<Map<String, dynamic>> get favoritos => _favoritos;
  bool get loading => _loading;
  int? get idUsuario => _idUsuario;

  /// Inicializa (al arrancar app)
  Future<void> init() async {
    final id = await AuthStorage.getIdPersona();
    if (id != null) {
      _idUsuario = id;
      await cargarFavoritos();
    }
  }

  /// Detecta si el usuario cambió e inicia nuevo fetch
  Future<void> checkAndUpdateUsuario() async {
    final nuevoId = await AuthStorage.getIdPersona();
    if (nuevoId != _idUsuario) {
      _idUsuario = nuevoId;
      _favoritos = [];
      notifyListeners();
      if (_idUsuario != null) {
        await cargarFavoritos();
      }
    }
  }

  Future<void> cargarFavoritos() async {
    if (_idUsuario == null) return;
    _loading = true;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse('http://localhost:3005/favoritos/$_idUsuario'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _favoritos = List<Map<String, dynamic>>.from(data);
      } else {
        _favoritos = [];
      }
    } catch (e) {
      debugPrint('❌ Error favoritos: $e');
    }

    _loading = false;
    notifyListeners();
  }

  bool esFavorito(int idProducto) {
    return _favoritos.any((p) => p['idproducto'] == idProducto);
  }

  Future<void> toggleFavorito(Map<String, dynamic> producto) async {
    await checkAndUpdateUsuario(); // 👈 asegura usuario actualizado

    if (_idUsuario == null) return;

    final idProducto = producto['idproducto'];
    if (esFavorito(idProducto)) {
      await http.delete(Uri.parse('http://localhost:3005/favoritos/$idProducto/$_idUsuario'));
      _favoritos.removeWhere((p) => p['idproducto'] == idProducto);
    } else {
      final res = await http.post(
        Uri.parse('http://localhost:3005/favoritos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idusuario': _idUsuario, 'idproducto': idProducto}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _favoritos.add(producto);
      }
    }

    notifyListeners();
  }

  void clear() {
    _idUsuario = null;
    _favoritos = [];
    notifyListeners();
  }
}
