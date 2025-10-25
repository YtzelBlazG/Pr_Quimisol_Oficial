import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';



class ProductoEditPage extends StatefulWidget {
  final Producto producto;

  const ProductoEditPage({super.key, required this.producto});

  @override
  State<ProductoEditPage> createState() => _ProductoEditPageState();
}

class _ProductoEditPageState extends State<ProductoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  final ProductoService _productoService = ProductoService();
  final UnidadService _unidadService = UnidadService();

  int? _idUnidad;
  List<Map<String, dynamic>> _unidades = [];

  String _vistaPrevia = "";

  @override
  void initState() {
    super.initState();
    _codigoCtrl.text = widget.producto.codigo;
    _nombreCtrl.text = widget.producto.nombre;
    _descCtrl.text = widget.producto.descripcion;
    _imgCtrl.text = widget.producto.imagen ?? '';
    _precioCtrl.text = widget.producto.precio.toString();
    _idUnidad = widget.producto.idunidad;
    _vistaPrevia = _imgCtrl.text.trim();

    _loadUnidades();

    _imgCtrl.addListener(() {
      setState(() {
        _vistaPrevia = _imgCtrl.text.trim();
      });
    });
  }

  Future<void> _loadUnidades() async {
    final unidades = await _unidadService.obtenerUnidades();
    _unidades = unidades.map((u) => {
          'idunidad': u.id,
          'nombre': u.nombre,
        }).toList();
    setState(() {});
  }

  Future<void> _editarProducto() async {
    if (_formKey.currentState!.validate() && _idUnidad != null) {
      final nuevoProducto = Producto(
        codigo: _codigoCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        idunidad: _idUnidad!,
        imagen: _imgCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text.trim()),
      );

      await _productoService.updateProducto(widget.producto.idproducto!, nuevoProducto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Producto actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Modular.to.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Editar producto',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _codigoCtrl,
                      decoration: const InputDecoration(labelText: 'Código'),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese el código' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese la descripción' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _idUnidad,
                      items: _unidades
                          .map((u) => DropdownMenuItem<int>(
                                value: u['idunidad'],
                                child: Text(u['nombre']),
                              ))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      onChanged: (value) {
                        setState(() {
                          _idUnidad = value;
                        });
                      },
                      validator: (value) => value == null ? 'Seleccione una unidad' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese el precio';
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed < 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imgCtrl,
                      decoration: const InputDecoration(labelText: 'URL de imagen'),
                    ),
                    const SizedBox(height: 12),

                    /// ✅ Vista previa con validación elegante
                    if (_vistaPrevia.isNotEmpty)
                      Column(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _vistaPrevia,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Text(
                                    '❌ No se pudo cargar la imagen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Actualizar producto'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      onPressed: _editarProducto,
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
