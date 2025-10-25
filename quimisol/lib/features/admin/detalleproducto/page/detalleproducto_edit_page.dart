import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';

class DetalleProductoEditPage extends StatefulWidget {
  final DetalleProducto detalle;

  const DetalleProductoEditPage({super.key, required this.detalle});

  @override
  State<DetalleProductoEditPage> createState() => _DetalleProductoEditPageState();
}

class _DetalleProductoEditPageState extends State<DetalleProductoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _atributoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  final DetalleProductoService _detalleService = DetalleProductoService();
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];
  Producto? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    _atributoCtrl.text = widget.detalle.atributo;
    _valorCtrl.text = widget.detalle.valor;
    _cantidadCtrl.text = widget.detalle.cantidad.toString();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final data = await _productoService.getProductos();
    setState(() {
      _productos = data;
      _productoSeleccionado = data.firstWhere(
        (p) => p.idproducto == widget.detalle.idproducto,
        orElse: () => data.first,
      );
    });
  }

  Future<void> _editarDetalle() async {
    if (_formKey.currentState!.validate()) {
      if (_productoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Selecciona un producto")),
        );
        return;
      }

      final nuevoDetalle = DetalleProducto(
        id: widget.detalle.id,
        idproducto: _productoSeleccionado!.idproducto!,
        atributo: _atributoCtrl.text.trim(),
        valor: _valorCtrl.text.trim(),
        cantidad: int.parse(_cantidadCtrl.text.trim()),
        createdon: widget.detalle.createdon,
        updatedon: DateTime.now(),
        deletedon: widget.detalle.deletedon,
      );

      await _detalleService.updateDetalleProducto(widget.detalle.id!, nuevoDetalle);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Detalle actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Modular.to.pop();
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
        title: const Text("Editar Detalle de Producto"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SizedBox(
              width: 500,
              child: _productos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Editar detalle de producto',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 24),

                          /// Atributo
                          TextFormField(
                            controller: _atributoCtrl,
                            decoration: const InputDecoration(labelText: 'Atributo'),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese el atributo' : null,
                          ),
                          const SizedBox(height: 12),

                          /// Valor
                          TextFormField(
                            controller: _valorCtrl,
                            decoration: const InputDecoration(labelText: 'Valor'),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese el valor' : null,
                          ),
                          const SizedBox(height: 12),

                          /// Cantidad
                          TextFormField(
                            controller: _cantidadCtrl,
                            decoration: const InputDecoration(labelText: 'Cantidad'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Ingrese la cantidad';
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed < 0) return 'Cantidad inválida';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          /// Producto (dropdown)
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

                          /// Botón guardar
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Actualizar detalle'),
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
                            onPressed: _editarDetalle,
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
