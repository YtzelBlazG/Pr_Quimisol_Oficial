// lib/features/admin/categorias/presentation/pages/categoria_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';
import 'package:quimisol/features/admin/categorias/widgets/categoria_modal.dart';
import 'package:quimisol/shared/widgets/delete_dialog.dart';
import '../controllers/categoria_controller.dart';

class CategoriaListPage extends StatefulWidget {
  const CategoriaListPage({super.key});

  @override
  State<CategoriaListPage> createState() => _CategoriaListPageState();
}

class _CategoriaListPageState extends State<CategoriaListPage> {
  final CategoriaController controlador = Modular.get<CategoriaController>();
  final TextEditingController _buscarCtrl = TextEditingController();
  List<Categoria> filtradas = [];

  @override
  void initState() {
    super.initState();
    _cargarYFiltrar();
    _buscarCtrl.addListener(_filtrarResultados);
  }

  @override
  void dispose() {
    _buscarCtrl.removeListener(_filtrarResultados);
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarYFiltrar() async {
    await controlador.cargarCategorias();
    setState(() {
      filtradas = controlador.categorias;
    });
  }

  void _filtrarResultados() {
    final texto = _buscarCtrl.text.toLowerCase();
    setState(() {
      filtradas = controlador.categorias
          .where((c) => c.nombre.toLowerCase().contains(texto))
          .toList();
    });
  }

  void _confirmarEliminar(Categoria categoria) {
  showDialog(
    context: context,
    builder: (_) => ConfirmDeleteDialog(
      title: 'Confirmar eliminación',
      message: '¿Seguro que deseas eliminar "${categoria.nombre}"?',
      onConfirm: () async {
        try {
          await controlador.borrarCategoria(categoria.id);
          await _cargarYFiltrar();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar la categoría'),
            ),
          );
        }
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                                  "Categorías",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.primary,
                                  ),
                                ),
                                Text(
                                  "${filtradas.length} categorías encontradas",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Palette.primary.withOpacity(0.7),
                                  ),
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
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // TABLA MODERNA
                      filtradas.isEmpty
                          ? _buildEmptyState()
                          : _ModernDataTable(
                              categorias: filtradas,
                              onEdit: (categoria) async {
                                await showCategoriaModal(
                                  context: context,
                                  categoria: categoria,
                                );
                                await _cargarYFiltrar();
                              },
                              onDelete: (categoria) => _confirmarEliminar(categoria),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTÓN FLOTANTE (MANTENIDO COMO ESTÁ)
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton.extended(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  "Nueva categoría",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: 10,
                onPressed: () async {
                  await showCategoriaModal(context: context);
                  await _cargarYFiltrar();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 70, color: Palette.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No se encontraron categorías',
              style: TextStyle(fontSize: 17, color: Palette.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta buscar o crea una nueva',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// === TABLA MODERNA ===
class _ModernDataTable extends StatelessWidget {
  final List<Categoria> categorias;
  final void Function(Categoria) onEdit;
  final void Function(Categoria) onDelete;

  const _ModernDataTable({
    required this.categorias,
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 64,
            dataRowHeight: 64,
            headingRowColor: WidgetStateProperty.all(Palette.card),
            columnSpacing: 32,
            horizontalMargin: 24,
            columns: [
              _buildHeader('Nombre', width: 250),
              _buildHeader('Descripción', width: 350),
              _buildHeader('Acciones', width: 150, alignment: Alignment.center),
            ],
            rows: categorias.map((categoria) {
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
                      child: Text(
                        categoria.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Palette.primary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      categoria.descripcion ?? 'Sin descripción',
                      style: TextStyle(
                        color: Palette.primary.withOpacity(0.9),
                        fontSize: 15,
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
                            onTap: () => onEdit(categoria),
                            tooltip: "Editar",
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            icon: Icons.delete,
                            color: Colors.red.shade600,
                            onTap: () => onDelete(categoria),
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

// === BOTÓN DE ACCIÓN ===
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
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}