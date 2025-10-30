import 'package:flutter/material.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_formulario.dart';

class ProductoEditPage extends StatelessWidget {
  final Producto producto;

  const ProductoEditPage({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
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
                producto: producto,
                onSuccess: () {
                  // Aquí redirige al listado una vez guardado
                  // Puedes hacer pop también si prefieres regresar
                  Navigator.of(context).pop(); 
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
