import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';

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

  @override
  void initState() {
    super.initState();
    _codigoCtrl.text = widget.producto.codigo;
    _nombreCtrl.text = widget.producto.nombre;
    _descCtrl.text = widget.producto.descripcion;
    _imgCtrl.text = widget.producto.imagen ?? '';
    _precioCtrl.text = widget.producto.precio.toString();
    _idUnidad = widget.producto.idunidad;

    _loadUnidades();

    // No necesitamos un campo separado para la vista previa; usamos directamente _imgCtrl.text
  }

  Future<void> _loadUnidades() async {
    final unidades = await _unidadService.obtenerUnidades();
    _unidades = unidades
        .map((u) => {'idunidad': u.id, 'nombre': u.nombre})
        .toList();
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

      await _productoService.updateProducto(
        widget.producto.idproducto!,
        nuevoProducto,
      );

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth * 0.9 : 950.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          onPressed: () => Modular.to.pop(),
        ),
        title: const Text(
          "Editar Producto",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 950, minWidth: 400),
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            color: const Color(0xFFF8F0FF),
            child: SizedBox(
              width: cardWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 28 : 56,
                  vertical: isMobile ? 36 : 44,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // HEADER
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Palette.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 40,
                                  color: Palette.primary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Editar producto',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.primary,
                                ),
                              ),
                             /* const SizedBox(height: 8),
                              Text(
                                'Modifica los datos del producto',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Palette.primary.withOpacity(0.75),
                                ),
                                textAlign: TextAlign.center,
                              ),*/
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // CAMPOS
                        _buildField(
                          _codigoCtrl,
                          'Código',
                          Icons.code,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 18),
                        _buildField(
                          _nombreCtrl,
                          'Nombre',
                          Icons.label,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 18),
                        _buildField(
                          _descCtrl,
                          'Descripción',
                          Icons.description,
                          maxLines: 3,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 18),

                        // UNIDAD
                        DropdownButtonFormField<int>(
                          value: _idUnidad,
                          decoration: _fieldDecoration(
                            'Unidad',
                            Icons.category,
                          ),
                          items: _unidades
                              .map(
                                (u) => DropdownMenuItem<int>(
                                  value: u['idunidad'],
                                  child: Text(
                                    u['nombre'],
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _idUnidad = v),
                          validator: (v) =>
                              v == null ? 'Selecciona una unidad' : null,
                        ),
                        const SizedBox(height: 18),

                        _buildField(
                          _precioCtrl,
                          'Precio (Bs)',
                          Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final p = double.tryParse(v);
                            if (p == null || p < 0) return 'Precio inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        _buildField(
                          _imgCtrl,
                          'URL de imagen (opcional)',
                          Icons.image,
                        ),

                        const SizedBox(height: 32),

                        // VISTA PREVIA
                        if (_imgCtrl.text.trim().isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 260,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Palette.primary.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                _imgCtrl.text.trim(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Palette.card,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Palette.primary.withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Imagen no válida',
                                        style: TextStyle(
                                          color: Palette.primary.withOpacity(
                                            0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 36),

                        // BOTÓN
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, size: 22),
                            label: const Text(
                              'Actualizar producto',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              shadowColor: Palette.primary.withOpacity(0.4),
                            ),
                            onPressed: _editarProducto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }
}
