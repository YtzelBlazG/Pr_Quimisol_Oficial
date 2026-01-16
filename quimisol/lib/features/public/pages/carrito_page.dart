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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        setState(() => _loading = false);
        return;
      }

      final url = Uri.parse('http://10.192.87.85:3005/carrito/$idUsuario');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarProducto(int idProducto) async {
    final idUsuario = await AuthStorage.getIdPersona();
    if (idUsuario == null) return;

    final url =
        Uri.parse('http://10.192.87.85:3005/carrito/$idUsuario/$idProducto');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        return;
      }

      if (_productosAgrupados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu carrito está vacío')),
        );
        return;
      }

      final result = await Modular.to.pushNamed<bool>('/locations/select');

      if (result == true) {
        await _cargarCarrito(); // backend limpia carrito
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pedido creado y ubicaciones guardadas correctamente ✅',
            ),
          ),
        );

        Modular.to.pushNamed('/pedidos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();
    final itemCount = _productosAgrupados.length;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF3E6FA),
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo-quimisol.png',
          height: 60,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Palette.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.gradientStart, Palette.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // hoja blanca
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header interno "Mi carrito"
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Mi carrito',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Palette.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        itemCount == 0
                            ? 'Aún no has agregado productos'
                            : '$itemCount producto${itemCount == 1 ? '' : 's'} en tu pedido',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Palette.ink.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Color(0xFFECE3F4),
                    ),

                    // contenido scrollable
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Palette.primary,
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarCarrito,
                              color: Palette.primary,
                              child: _productosAgrupados.isEmpty
                                  ? _EmptyCart(
                                      onGoToOrders: () {
                                        Modular.to.pushNamed('/pedidos');
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 110),
                                      itemCount: _productosAgrupados.length,
                                      itemBuilder: (context, index) {
                                        final p = _productosAgrupados[index];
                                        final precio =
                                            double.tryParse(
                                                  p['precio'].toString(),
                                                ) ??
                                                0.0;
                                        final cantidad =
                                            int.tryParse(
                                                  p['cantidad'].toString(),
                                                ) ??
                                                0;
                                        final subtotal = precio * cantidad;

                                        return _PrettyCartItem(
                                          nombre: p['nombre'] ??
                                              'Producto sin nombre',
                                          imagen: p['imagen'],
                                          cantidad: cantidad,
                                          precio: precio,
                                          subtotal: subtotal,
                                          onDelete: () =>
                                              _eliminarProducto(
                                                p['idproducto'],
                                              ),
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _productosAgrupados.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.ink.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: Palette.card.withOpacity(0.9),
                    width: 1.2,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total a pagar',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Palette.ink.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${total.toStringAsFixed(2)} Bs',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Palette.ink,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      _loading ? null : _finalizarCompra,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Palette.button,
                                    foregroundColor: Palette.ink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Finalizar compra',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Palette.ink.withOpacity(0.55),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'La dirección de entrega se selecciona en el siguiente paso.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: Palette.ink.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

// ------- CARD BONITO -------

class _PrettyCartItem extends StatelessWidget {
  final String nombre;
  final String? imagen;
  final int cantidad;
  final double precio;
  final double subtotal;
  final VoidCallback onDelete;

  const _PrettyCartItem({
    required this.nombre,
    required this.imagen,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.card, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 65,
              height: 65,
              color: Palette.card,
              child: imagen != null
                  ? Image.network(
                      imagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        color: Palette.ink.withOpacity(0.4),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2,
                      color: Palette.ink.withOpacity(0.4),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.button,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'x$cantidad',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${precio.toStringAsFixed(2)} Bs c/u',
                      style: TextStyle(
                        color: Palette.ink.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Subtotal: ${subtotal.toStringAsFixed(2)} Bs',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Palette.secondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Palette.statsDanger,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ------- ESTADO VACÍO -------

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({
    required this.onGoToOrders,
  });

  final VoidCallback onGoToOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.card,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 52,
                    color: Palette.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tu carrito está vacío',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega productos para empezar tu pedido. '
                  'Puedes revisar tus pedidos anteriores en cualquier momento.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Palette.ink.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onGoToOrders,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Palette.white.withOpacity(0.9),
                      side: BorderSide(
                        color: Palette.secButton.withOpacity(0.9),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.receipt_long,
                      color: Palette.secButton,
                    ),
                    label: const Text(
                      'Ver mis pedidos',
                      style: TextStyle(
                        color: Palette.secButton,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
