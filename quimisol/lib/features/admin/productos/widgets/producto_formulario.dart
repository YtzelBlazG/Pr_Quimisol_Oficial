import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/core/services/postgresql/categorias/categoria_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';

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
      _unidades = data.map((u) => {'idunidad': u.id, 'nombre': u.nombre}).toList();
    });
  }

  Future<void> _loadCategorias() async {
    final data = await _categoriaService.obtenerCategorias();
    setState(() {
      _categorias = data.map((c) => {'idcategoria': c.id, 'nombre': c.nombre}).toList();
    });
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate() || _idUnidad == null || _idCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completa todos los campos'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
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

    try {
      if (widget.producto == null) {
        await _productoService.createProducto(producto);
        _showMessage('Producto creado exitosamente', Palette.statsSuccess);
      } else {
        await _productoService.updateProducto(widget.producto!.idproducto!, producto);
        _showMessage('Producto actualizado correctamente', Palette.statsSuccess);
      }
      widget.onSuccess?.call();
      Modular.to.pop();
    } catch (e) {
      _showMessage('Error al guardar el producto', Colors.redAccent);
    }
  }

  void _showMessage(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 5),
          _buildField(_codigoCtrl, 'Código', Icons.code, validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null),
          const SizedBox(height: 18),
          _buildField(_nombreCtrl, 'Nombre', Icons.label, validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null),
          const SizedBox(height: 18),
          _buildField(_descCtrl, 'Descripción', Icons.description, maxLines: 3, validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null),
          const SizedBox(height: 18),

          DropdownButtonFormField<int>(
            value: _idCategoria,
            decoration: _fieldDecoration('Categoría', Icons.category),
            items: _categorias
                .map((c) => DropdownMenuItem<int>(
                      value: c['idcategoria'],
                      child: Text(c['nombre'], style: const TextStyle(fontSize: 15.5)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _idCategoria = v),
            validator: (v) => v == null ? 'Selecciona una categoría' : null,
          ),
          const SizedBox(height: 18),

          DropdownButtonFormField<int>(
            value: _idUnidad,
            decoration: _fieldDecoration('Unidad', Icons.straighten),
            items: _unidades
                .map((u) => DropdownMenuItem<int>(
                      value: u['idunidad'],
                      child: Text(u['nombre'], style: const TextStyle(fontSize: 15.5)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _idUnidad = v),
            validator: (v) => v == null ? 'Selecciona una unidad' : null,
          ),
          const SizedBox(height: 18),

          _buildField(
            _precioCtrl,
            'Precio (Bs)',
            Icons.attach_money,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final p = double.tryParse(v);
              if (p == null || p < 0) return 'Precio inválido';
              return null;
            },
          ),
          const SizedBox(height: 18),

          _buildField(_imgCtrl, 'URL de imagen (opcional)', Icons.image),

          const SizedBox(height: 32),

          if (_vistaPrevia.isNotEmpty)
            Container(
              width: double.infinity,
              height: 260,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.primary.withOpacity(0.3), width: 2),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  _vistaPrevia,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Palette.card,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Palette.primary.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text('Imagen no válida', style: TextStyle(color: Palette.primary.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              ),
            ),

          const SizedBox(height: 17),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 20),
              label: Text(
                isEdit ? 'Actualizar producto' : 'Guardar producto',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: Palette.primary.withOpacity(0.4),
              ),
              onPressed: _guardarProducto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(label, icon),
      style: const TextStyle(fontSize: 15.5),
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Palette.primary, size: 24),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Palette.card, width: 1.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Palette.primary, width: 2.8),
      ),
    );
  }
}