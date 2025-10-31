import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/detalleproducto/detalleproducto_service.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/core/theme/palette.dart';

import '../../../../shared/buttons/btn_floating_custom.dart';
import '../../../../shared/widgets/delete_dialog.dart';

class DetalleProductoListPage extends StatefulWidget {
  const DetalleProductoListPage({super.key});

  @override
  State<DetalleProductoListPage> createState() => _DetalleProductoListPageState();
}

class _DetalleProductoListPageState extends State<DetalleProductoListPage> {
  List<DetalleProducto> detalles = [];
  List<DetalleProducto> detallesFiltrados = [];
  final TextEditingController _buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
    _buscarCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscarCtrl.removeListener(_filtrar);
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalles() async {
    final data = await DetalleProductoService().getDetalleProductos();
    setState(() {
      detalles = data;
      detallesFiltrados = data;
    });
  }

  void _filtrar() {
    final texto = _buscarCtrl.text.toLowerCase();
    setState(() {
      detallesFiltrados = detalles
          .where((d) =>
              d.atributo.toLowerCase().contains(texto) ||
              d.valor.toLowerCase().contains(texto))
          .toList();
    });
  }

  void _confirmarEliminar(BuildContext context, DetalleProducto detalle) {
  showDialog(
    context: context,
    builder: (_) => ConfirmDeleteDialog(
      title: 'Confirmar eliminación',
      message: '¿Eliminar "${detalle.atributo}"?',
      onConfirm: () async {
        await DetalleProductoService().deleteDetalleProducto(detalle.id!);
        await _cargarDetalles();
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // TÍTULO + BUSCADOR
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Detalles de Producto",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Palette.primary),
                                ),
                                Text(
                                  "${detallesFiltrados.length} detalles encontrados",
                                  style: TextStyle(fontSize: 14, color: Palette.primary.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _buscarCtrl,
                              decoration: InputDecoration(
                                hintText: 'Buscar por atributo o valor',
                                prefixIcon: Icon(Icons.search, color: Palette.primary),
                                filled: true,
                                fillColor: Palette.fieldBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Palette.card),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Palette.card),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // TABLA MODERNA
                      detallesFiltrados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60),
                                child: Column(
                                  children: [
                                    Icon(Icons.list_alt_outlined, size: 64, color: Palette.primary.withOpacity(0.3)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay detalles para mostrar.',
                                      style: TextStyle(fontSize: 16, color: Palette.primary.withOpacity(0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _ModernDataTable(
                              detalles: detallesFiltrados,
                              onEdit: (detalle) async {
                                await Modular.to.pushNamed('/admin/detalleproducto/edit', arguments: detalle);
                                await _cargarDetalles();
                              },
                              onDelete: (detalle) => _confirmarEliminar(context, detalle),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTÓN FLOTANTE REUTILIZABLE
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButtonCustom(
                label: "Nuevo detalle",
                icon: Icons.add,
                onPressed: () async {
                  await Modular.to.pushNamed('/admin/detalleproducto/create');
                  await _cargarDetalles();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === TABLA MODERNA ===
class _ModernDataTable extends StatelessWidget {
  final List<DetalleProducto> detalles;
  final void Function(DetalleProducto) onEdit;
  final void Function(DetalleProducto) onDelete;

  const _ModernDataTable({
    required this.detalles,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.card),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 64,
            dataRowHeight: 72,
            headingRowColor: WidgetStateProperty.all(Palette.card),
            columnSpacing: 32,
            horizontalMargin: 24,
            columns: [
              _buildHeader('Atributo', width: 190),
              _buildHeader('Valor', width: 190),
              _buildHeader('Cantidad', width: 170),
              _buildHeader('Acciones', width: 170, alignment: Alignment.center),
            ],
            rows: detalles.map((detalle) {
              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Palette.card.withOpacity(0.5);
                  }
                  return Colors.transparent;
                }),
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              detalle.atributo,
                              style: TextStyle(fontWeight: FontWeight.w600, color: Palette.primary, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detalle.valor,
                            style: TextStyle(color: Palette.primary.withOpacity(0.9), fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        '${detalle.cantidad}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.edit,
                            color: Palette.primary,
                            onTap: () => onEdit(detalle),
                            tooltip: "Editar",
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            icon: Icons.delete,
                            color: Colors.red.shade600,
                            onTap: () => onDelete(detalle),
                            tooltip: "Eliminar",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildHeader(String label, {double? width, AlignmentGeometry alignment = Alignment.centerLeft}) {
    return DataColumn(
      label: Container(
        width: width,
        alignment: alignment,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Palette.primary.withOpacity(0.95),
          ),
        ),
      ),
    );
  }
}

// === BOTÓN DE ACCIÓN (REUTILIZABLE) ===
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}