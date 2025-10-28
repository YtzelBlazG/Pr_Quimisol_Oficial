import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';

class DetalleProductoCreatePage extends StatefulWidget {
  const DetalleProductoCreatePage({super.key});

  @override
  State<DetalleProductoCreatePage> createState() =>
      _DetalleProductoCreatePageState();
}

class _DetalleProductoCreatePageState extends State<DetalleProductoCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _atributoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  final DetalleProductoService _service = DetalleProductoService();
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];
  Producto? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final data = await _productoService.getProductos();
    setState(() {
      _productos = data;
    });
  }

  Future<void> _crearDetalle() async {
    if (_formKey.currentState!.validate()) {
      if (_productoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Selecciona un producto")),
        );
        return;
      }

      try {
        final detalle = DetalleProducto(
          id: 0,
          atributo: _atributoCtrl.text.trim(),
          valor: _valorCtrl.text.trim(),
          cantidad: int.parse(_cantidadCtrl.text),
          idproducto: _productoSeleccionado!.idproducto!,
          createdon: DateTime.now(),
          updatedon: DateTime.now(),
          deletedon: null,
        );

        await _service.createDetalleProducto(detalle);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Detalle creado exitosamente')),
        );
        Modular.to.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al crear detalle: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _atributoCtrl.dispose();
    _valorCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Detalle de Producto"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nuevo detalle de producto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo atributo
                    TextFormField(
                      controller: _atributoCtrl,
                      decoration: const InputDecoration(labelText: 'Atributo'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // Campo valor
                    TextFormField(
                      controller: _valorCtrl,
                      decoration: const InputDecoration(labelText: 'Valor'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // Campo cantidad
                    TextFormField(
                      controller: _cantidadCtrl,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo requerido';
                        if (int.tryParse(value) == null) return 'Debe ser un número';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Combo de producto
                    DropdownButtonFormField<Producto>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar producto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      value: _productoSeleccionado,
                      items: _productos
                          .map((p) => DropdownMenuItem<Producto>(
                                value: p,
                                child: Text(p.nombre),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _productoSeleccionado = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona un producto' : null,
                    ),
                    const SizedBox(height: 24),

                    // Botón guardar
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar detalle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _crearDetalle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
