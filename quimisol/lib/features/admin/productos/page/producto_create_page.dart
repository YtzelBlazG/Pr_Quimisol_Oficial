import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';



class ProductoCreatePage extends StatefulWidget {
  const ProductoCreatePage({super.key});

  @override
  State<ProductoCreatePage> createState() => _ProductoCreatePageState();
}

class _ProductoCreatePageState extends State<ProductoCreatePage> {
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

  @override
  void initState() {
    super.initState();
    _loadUnidades();
    _imgCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadUnidades() async {
    final data = await _unidadService.obtenerUnidades();
    setState(() {
      _unidades = data.map((u) => {
            'idunidad': u.id,
            'nombre': u.nombre,
          }).toList();
    });
  }

  Future<void> _crearProducto() async {
    if (_formKey.currentState!.validate() && _idUnidad != null) {
      final nuevoProducto = Producto(
        codigo: _codigoCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        idunidad: _idUnidad!,
        imagen: _imgCtrl.text.trim().isNotEmpty ? _imgCtrl.text.trim() : null,
        precio: double.parse(_precioCtrl.text.trim()),
      );

      await _productoService.createProducto(nuevoProducto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Producto creado exitosamente')),
      );
      Modular.to.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Completa todos los campos')),
      );
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Producto")),
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
                      'Nuevo producto',
                      style: TextStyle(
                        fontSize: 20,
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
                      onChanged: (value) => setState(() => _idUnidad = value),
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
                    const SizedBox(height: 16),

                    /// ✅ Vista previa con manejo de error elegante
                    if (_imgCtrl.text.isNotEmpty)
                      Column(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imgCtrl.text.trim(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text('❌ No se pudo cargar la imagen'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar producto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _crearProducto,
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
