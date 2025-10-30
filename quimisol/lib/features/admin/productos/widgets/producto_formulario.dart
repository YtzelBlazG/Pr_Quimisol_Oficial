import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/core/services/postgresql/categorias/categoria_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';

class ProductoFormulario extends StatefulWidget {
  final Producto? producto;
  final VoidCallback? onSuccess;

  const ProductoFormulario({
    super.key,
    this.producto,
    this.onSuccess,
  });

  @override
  State<ProductoFormulario> createState() => _ProductoFormularioState();
}

class _ProductoFormularioState extends State<ProductoFormulario> {
  final _formKey = GlobalKey<FormState>();

  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  final ProductoService _productoService = ProductoService();
  final UnidadService _unidadService = UnidadService();
  final CategoriaService _categoriaService = CategoriaService();

  int? _idUnidad;
  int? _idCategoria;

  List<Map<String, dynamic>> _unidades = [];
  List<Map<String, dynamic>> _categorias = [];

  String get _vistaPrevia => _imgCtrl.text.trim();

  @override
  void initState() {
    super.initState();
    _loadUnidades();
    _loadCategorias();
    _imgCtrl.addListener(() => setState(() {}));

    if (widget.producto != null) {
      final p = widget.producto!;
      _codigoCtrl.text = p.codigo;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion;
      _imgCtrl.text = p.imagen ?? '';
      _precioCtrl.text = p.precio.toString();
      _idUnidad = p.idunidad;
      _idCategoria = p.idcategoria;
    }
  }

  Future<void> _loadUnidades() async {
    final data = await _unidadService.obtenerUnidades();
    setState(() {
      _unidades = data
          .map((u) => {'idunidad': u.id, 'nombre': u.nombre})
          .toList();
    });
  }

  Future<void> _loadCategorias() async {
    final data = await _categoriaService.obtenerCategorias();
    setState(() {
      _categorias = data
          .map((c) => {'idcategoria': c.id, 'nombre': c.nombre})
          .toList();
    });
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate() ||
        _idUnidad == null ||
        _idCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Completa todos los campos')),
      );
      return;
    }

    final producto = Producto(
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      idunidad: _idUnidad!,
      idcategoria: _idCategoria!,
      imagen: _imgCtrl.text.trim().isNotEmpty ? _imgCtrl.text.trim() : null,
      precio: double.parse(_precioCtrl.text.trim()),
    );

    if (widget.producto == null) {
      await _productoService.createProducto(producto);
      _showMessage('✅ Producto creado exitosamente');
    } else {
      await _productoService.updateProducto(widget.producto!.idproducto!, producto);
      _showMessage('✅ Producto actualizado correctamente');
    }

    widget.onSuccess?.call();
    Modular.to.pop();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    final isEdit = widget.producto != null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEdit ? 'Editar producto' : 'Nuevo producto',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _codigoCtrl,
            decoration: const InputDecoration(labelText: 'Código'),
            validator: (v) => v == null || v.isEmpty ? 'Ingrese el código' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
            validator: (v) => v == null || v.isEmpty ? 'Ingrese la descripción' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _idCategoria,
            items: _categorias
                .map((c) => DropdownMenuItem<int>(
                      value: c['idcategoria'],
                      child: Text(c['nombre']),
                    ))
                .toList(),
            decoration: const InputDecoration(labelText: 'Categoría'),
            onChanged: (value) => setState(() => _idCategoria = value),
            validator: (value) => value == null ? 'Seleccione una categoría' : null,
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          TextFormField(
            controller: _precioCtrl,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingrese el precio';
              final parsed = double.tryParse(value);
              if (parsed == null || parsed < 0) return 'Precio inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _imgCtrl,
            decoration: const InputDecoration(labelText: 'URL de imagen'),
          ),
          const SizedBox(height: 16),

          if (_vistaPrevia.isNotEmpty)
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
                      _vistaPrevia,
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
            label: Text(isEdit ? 'Actualizar producto' : 'Guardar producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _guardarProducto,
          ),
        ],
      ),
    );
  }
}
