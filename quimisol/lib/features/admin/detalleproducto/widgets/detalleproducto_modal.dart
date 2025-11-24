import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';

Future<void> showDetalleProductoModal({
  required BuildContext context,
  DetalleProducto? detalle,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: DetalleProductoModal(detalle: detalle),
        ),
      );
    },
  );
}

class DetalleProductoModal extends StatefulWidget {
  final DetalleProducto? detalle;

  const DetalleProductoModal({super.key, this.detalle});

  @override
  State<DetalleProductoModal> createState() => _DetalleProductoModalState();
}

class _DetalleProductoModalState extends State<DetalleProductoModal> {
  final _formKey = GlobalKey<FormState>();
  final _atributoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  final DetalleProductoService _detalleService = DetalleProductoService();
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];
  Producto? _productoSeleccionado;
  bool _loadingProductos = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.detalle != null) {
      _atributoCtrl.text = widget.detalle!.atributo;
      _valorCtrl.text = widget.detalle!.valor;
      _cantidadCtrl.text = widget.detalle!.cantidad.toString();
    }
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final data = await _productoService.getProductos();
      setState(() {
        _productos = data;
        if (widget.detalle != null && data.isNotEmpty) {
          _productoSeleccionado = data.firstWhere(
            (p) => p.idproducto == widget.detalle!.idproducto,
            orElse: () => data.first,
          );
        }
        _loadingProductos = false;
      });
    } catch (e) {
      setState(() => _loadingProductos = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Selecciona un producto")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.detalle == null) {
        // CREAR
        final detalle = DetalleProducto(
          id: 0,
          atributo: _atributoCtrl.text.trim(),
          valor: _valorCtrl.text.trim(),
          cantidad: int.parse(_cantidadCtrl.text.trim()),
          idproducto: _productoSeleccionado!.idproducto!,
          createdon: DateTime.now(),
          updatedon: DateTime.now(),
          deletedon: null,
        );

        await _detalleService.createDetalleProducto(detalle);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Detalle creado exitosamente')),
        );
      } else {
        // EDITAR
        final nuevoDetalle = DetalleProducto(
          id: widget.detalle!.id,
          idproducto: _productoSeleccionado!.idproducto!,
          atributo: _atributoCtrl.text.trim(),
          valor: _valorCtrl.text.trim(),
          cantidad: int.parse(_cantidadCtrl.text.trim()),
          createdon: widget.detalle!.createdon,
          updatedon: DateTime.now(),
          deletedon: widget.detalle!.deletedon,
        );

        await _detalleService.updateDetalleProducto(
          widget.detalle!.id!,
          nuevoDetalle,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Detalle actualizado exitosamente')),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar detalle: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final titulo = widget.detalle == null
        ? "Nuevo Detalle de Producto"
        : "Editar Detalle de Producto";

    return Container(
      width: 520,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Palette.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 26, color: Palette.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loadingProductos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(
                      controller: _atributoCtrl,
                      label: 'Atributo',
                      icon: Icons.label,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _valorCtrl,
                      label: 'Valor',
                      icon: Icons.text_fields,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _cantidadCtrl,
                      label: 'Cantidad',
                      icon: Icons.confirmation_number,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (int.tryParse(v.trim()) == null) {
                          return 'Debe ser un número';
                        }
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
                      onChanged: (v) => setState(() {
                        _productoSeleccionado = v;
                      }),
                      validator: (v) =>
                          v == null ? 'Selecciona un producto' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(
                          widget.detalle == null
                              ? 'Guardar detalle'
                              : 'Actualizar detalle',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.button,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _saving ? null : _guardar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
