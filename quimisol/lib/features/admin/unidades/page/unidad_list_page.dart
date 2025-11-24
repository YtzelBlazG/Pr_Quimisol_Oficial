import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';
import 'package:quimisol/features/admin/unidades/widgets/unidad_modal.dart';
import '../../../../shared/buttons/btn_floating_custom.dart';
import '../../../../shared/widgets/delete_dialog.dart';
import '../controllers/unidad_controller.dart';
import 'package:quimisol/core/theme/palette.dart';


class UnidadListPage extends StatefulWidget {
  const UnidadListPage({super.key});

  @override
  State<UnidadListPage> createState() => _UnidadListPageState();
}

class _UnidadListPageState extends State<UnidadListPage> {
  final UnidadController controlador = Modular.get<UnidadController>();
  final TextEditingController _buscadorCtrl = TextEditingController();
  List<Unit> filtradas = [];

  @override
  void initState() {
    super.initState();
    _cargarYFiltrar();
    _buscadorCtrl.addListener(_filtrarResultados);
  }

  @override
  void dispose() {
    _buscadorCtrl.removeListener(_filtrarResultados);
    _buscadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarYFiltrar() async {
    await controlador.cargarUnidades();
    setState(() {
      filtradas = controlador.unidades;
    });
  }

  void _filtrarResultados() {
    final texto = _buscadorCtrl.text.toLowerCase();
    setState(() {
      filtradas = controlador.unidades
          .where((u) => u.nombre.toLowerCase().contains(texto))
          .toList();
    });
  }

  void _confirmarEliminar(BuildContext context, Unit unidad) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: 'Confirmar eliminación',
        message: '¿Seguro que deseas eliminar "${unidad.nombre}"?',
        onConfirm: () async {
          await controlador.borrarUnidad(unidad.id);
          await _cargarYFiltrar();
        },
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // === CONTENIDO ===
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                                      "Unidades",
                                      style: TextStyle(
                                        fontSize: isMobile ? 24 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.primary,
                                      ),
                                    ),
                                    Text(
                                      "${filtradas.length} unidades encontradas",
                                      style: TextStyle(fontSize: 14, color: Palette.primary.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 300,
                                  child: _buildSearchBar(isMobile),
                                ),
                              ],
                            ],
                          ),

                          if (isMobile) ...[
                            const SizedBox(height: 16),
                            _buildSearchBar(isMobile),
                          ],

                          const SizedBox(height: 32),

                          // TABLA RESPONSIVA
                          filtradas.isEmpty
                              ? _buildEmptyState(isMobile)
                              : _ModernUnidadTable(
                                  unidades: filtradas,
                                  /*onEdit: (unidad) async {
                                    await Modular.to.pushNamed('/admin/unidades/edit', arguments: unidad);
                                    await _cargarYFiltrar();
                                  },*/
                                  onEdit: (unidad) async {
                                    await showUnidadModal(context: context, unidad: unidad);
                                    await _cargarYFiltrar();
                                  },
                                  onDelete: (unidad) => _confirmarEliminar(context, unidad),
                                  isMobile: isMobile,
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // BOTÓN FLOTANTE
            Positioned(
              right: isMobile ? 16 : 24,
              bottom: isMobile ? 16 : 24,
              child: FloatingActionButtonCustom(
                label: isMobile ? "Nueva" : "Nueva unidad",
                icon: Icons.add,
               /* onPressed: () async {
                  await Modular.to.pushNamed('/admin/unidades/create');
                  await _cargarYFiltrar();
                },*/
                onPressed: () async {
                  await showUnidadModal(context: context);
                  await _cargarYFiltrar();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return TextField(
      controller: _buscadorCtrl,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre',
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
        contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: isMobile ? 48 : 64, color: Palette.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No hay unidades para mostrar.',
              style: TextStyle(fontSize: isMobile ? 15 : 16, color: Palette.primary.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// === TABLA MODERNA Y RESPONSIVA ===
class _ModernUnidadTable extends StatelessWidget {
  final List<Unit> unidades;
  final void Function(Unit) onEdit;
  final void Function(Unit) onDelete;
  final bool isMobile;

  const _ModernUnidadTable({
    required this.unidades,
    required this.onEdit,
    required this.onDelete,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: unidades.map((u) => _MobileUnidadCard(unidad: u, onEdit: onEdit, onDelete: onDelete)).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.card),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
              _buildHeader('Nombre', width: 200),
              _buildHeader('Descripción', width: 300),
              _buildHeader('Acciones', width: 150, alignment: Alignment.center),
            ],
            rows: unidades.map((unidad) {
              return DataRow(
                color: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.hovered) ? Palette.card.withOpacity(0.5) : Colors.transparent;
                }),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unidad.nombre,
                            style: TextStyle(fontWeight: FontWeight.w600, color: Palette.primary, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unidad.descripcion,
                            style: TextStyle(color: Palette.primary.withOpacity(0.9), fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(icon: Icons.edit, color: Palette.primary, 
                          onTap: () => onEdit(unidad), tooltip: "Editar"),
                          const SizedBox(width: 12),
                          _ActionButton(icon: Icons.delete, color: Colors.red.shade600, 
                          onTap: () => onDelete(unidad), tooltip: "Eliminar"),
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
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Palette.primary.withOpacity(0.95))),
      ),
    );
  }
}

// === CARD PARA MÓVIL ===
class _MobileUnidadCard extends StatelessWidget {
  final Unit unidad;
  final void Function(Unit) onEdit;
  final void Function(Unit) onDelete;

  const _MobileUnidadCard({required this.unidad, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.card),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Palette.button),
              const SizedBox(width: 6),
              Expanded(
                child: Text(unidad.nombre, style: TextStyle(fontWeight: FontWeight.w600, color: Palette.primary, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.circle, size: 14, color: Palette.primary.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(unidad.descripcion, style: TextStyle(color: Palette.primary.withOpacity(0.8), fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(icon: Icons.edit, color: Palette.primary, onTap: () => onEdit(unidad), tooltip: "Editar"),
              const SizedBox(width: 8),
              _ActionButton(icon: Icons.delete, color: Colors.red.shade600, onTap: () => onDelete(unidad), tooltip: "Eliminar"),
            ],
          ),
        ],
      ),
    );
  }
}

// === BOTÓN DE ACCIÓN ===
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({required this.icon, required this.color, required this.onTap, required this.tooltip});

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
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}