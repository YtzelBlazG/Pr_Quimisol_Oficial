import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_formulario.dart';

class ProductoCreatePage extends StatelessWidget {
  const ProductoCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Producto')),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SizedBox(
              width: 500,
              child: ProductoFormulario(
                onSuccess: () {
                  Modular.to.pop(); // ✅ navegación Modular
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
