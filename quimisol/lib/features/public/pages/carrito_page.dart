import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:http/http.dart' as http;
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _productosAgrupados = [];

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    try {
      final idUsuario = await AuthStorage.getIdPersona();
      if (idUsuario == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
        setState(() => _loading = false);
        return;
      }

      final url = Uri.parse('http://localhost:3005/carrito/$idUsuario');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Agrupar por idproducto
        final Map<int, Map<String, dynamic>> agrupado = {};
        for (var p in data) {
          final id = p['idproducto'];
          if (agrupado.containsKey(id)) {
            agrupado[id]!['cantidad'] += p['cantidad'];
          } else {
            agrupado[id] = {...p};
          }
        }

        setState(() {
          _productosAgrupados = agrupado.values.toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el carrito')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _eliminarProducto(int idProducto) async {
    final idUsuario = await AuthStorage.getIdPersona();
    if (idUsuario == null) return;
    final url = Uri.parse(
      'http://localhost:3005/carrito/$idUsuario/$idProducto',
    );
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        _productosAgrupados.removeWhere((p) => p['idproducto'] == idProducto);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado del carrito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar producto')),
      );
    }
  }

  double _calcularTotal() {
    return _productosAgrupados.fold(0.0, (sum, p) {
      final precio = double.tryParse(p['precio'].toString()) ?? 0.0;
      final cantidad = int.tryParse(p['cantidad'].toString()) ?? 0;
      return sum + precio * cantidad;
    });
  }

  Future<void> _finalizarCompra() async {
    try {
      final idUsuario = await AuthStorage.getIdPersona();
      if (idUsuario == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
        return;
      }
      if (_productosAgrupados.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tu carrito está vacío')));
        return;
      }

      setState(() => _loading = true);
      final url = Uri.parse(
        'http://localhost:3005/pedidos/crear-desde-carrito/$idUsuario',
      );
      final resp = await http.post(url);
      setState(() => _loading = false);

      if (resp.statusCode == 201) {
        final json = jsonDecode(resp.body);
        final idPedido = json['pedido']?['idpedido'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡Pedido #$idPedido creado!')));

        // limpiar UI local y navegar a pedidos
        setState(() {
          _productosAgrupados = [];
        });

        // Navegar con Modular a /pedidos
        Modular.to.pushNamed('/pedidos');
      } else {
        final msg =
            jsonDecode(resp.body)['message'] ?? 'Error al crear el pedido';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _productosAgrupados.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tu carrito está vacío'),
                  const SizedBox(height: 12),
                  IconButton.filled(
                    onPressed: () => Modular.to.pushNamed('/pedidos'),
                    icon: const Icon(Icons.receipt_long),
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.button,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _productosAgrupados.length,
              itemBuilder: (context, index) {
                final producto = _productosAgrupados[index];
                final precio =
                    double.tryParse(producto['precio'].toString()) ?? 0.0;
                final cantidad =
                    int.tryParse(producto['cantidad'].toString()) ?? 0;
                final subtotal = precio * cantidad;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: producto['imagen'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              producto['imagen'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                            ),
                          )
                        : const Icon(Icons.image_not_supported, size: 50),
                    title: Text(
                      producto['nombre'] ?? 'Producto sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cantidad: $cantidad'),
                        Text(
                          'Precio unitario: ${precio.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Subtotal: ${subtotal.toStringAsFixed(2)} Bs',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _eliminarProducto(producto['idproducto']),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _productosAgrupados.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total: ${total.toStringAsFixed(2)} Bs',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _finalizarCompra,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Finalizar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
