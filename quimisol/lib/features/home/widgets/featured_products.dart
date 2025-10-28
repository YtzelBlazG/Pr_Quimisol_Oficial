import 'package:flutter/material.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';

import 'product_card.dart';

class FeaturedProducts extends StatefulWidget {
  final ProductoService productoService;
  final void Function(Producto producto)? onViewMore;

  const FeaturedProducts({
    super.key,
    required this.productoService,
    this.onViewMore,
  });

  @override
  State<FeaturedProducts> createState() => _FeaturedProductsState();
}

class _FeaturedProductsState extends State<FeaturedProducts> {
  List<Producto> _productos = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.productoService.getProductos();
      if (!mounted) return;
      setState(() => _productos = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _productos = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_productos.isEmpty)
              ? const Center(child: Text('Sin productos por ahora'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final p = _productos[index];
                    return ProductCard(
                      producto: p,
                      onViewMore: () => widget.onViewMore?.call(p),
                    );
                  },
                ),
    );
  }
}
