import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';

class DetalleProductoEditPage extends StatefulWidget {
  final DetalleProducto detalle;

  const DetalleProductoEditPage({super.key, required this.detalle});

  @override
  State<DetalleProductoEditPage> createState() =>
      _DetalleProductoEditPageState();
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

      await _detalleService.updateDetalleProducto(
        widget.detalle.id!,
        nuevoDetalle,
      );

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth * 0.9 : 650.0;

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
          "Editar Detalle de Producto",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Card(
            elevation: 12,
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: const Color(0xFFF8F0FF),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
                vertical: isMobile ? 20 : 32,
              ),
              child: _productos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Palette.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.list_alt,
                                      size: 36,
                                      color: Palette.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Editar detalle de producto',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Palette.primary,
                                    ),
                                  ),
                                 /* const SizedBox(height: 6),
                                  Text(
                                    'Modifica el atributo/valor asociado',
                                    style: TextStyle(
                                      color: Palette.primary.withOpacity(0.7),
                                    ),
                                  ),*/
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildField(
                              _atributoCtrl,
                              'Atributo',
                              Icons.label,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              _valorCtrl,
                              'Valor',
                              Icons.text_fields,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              _cantidadCtrl,
                              'Cantidad',
                              Icons.confirmation_number,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (int.tryParse(v) == null)
                                  return 'Debe ser un número';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<Producto>(
                              value: _productoSeleccionado,
                              decoration: _fieldDecoration(
                                'Producto',
                                Icons.shopping_bag,
                              ),
                              items: _productos
                                  .map(
                                    (p) => DropdownMenuItem<Producto>(
                                      value: p,
                                      child: Text(p.nombre),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _productoSeleccionado = v),
                              validator: (v) =>
                                  v == null ? 'Selecciona un producto' : null,
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save, size: 20),
                                label: const Text(
                                  'Actualizar detalle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: _editarDetalle,
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
      prefixIcon: Icon(icon, color: Palette.primary, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Palette.card, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Palette.primary, width: 2.2),
      ),
    );
  }
}
