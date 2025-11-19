// lib/features/admin/productos/presentation/pages/producto_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_modal.dart';
import '../../../../shared/widgets/delete_dialog.dart';

class ProductoListPage extends StatefulWidget {
  const ProductoListPage({super.key});

  @override
  State<ProductoListPage> createState() => _ProductoListPageState();
}

class _ProductoListPageState extends State<ProductoListPage> {
  final TextEditingController _buscarCtrl = TextEditingController();
  final _service = ProductoService();

  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarCtrl.addListener(_filtrarProductos);
    _cargarProductos();
  }

  @override
  void dispose() {
    _buscarCtrl.removeListener(_filtrarProductos);
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getProductos();
      if (!mounted) return;
      setState(() {
        productos = data;
        productosFiltrados = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los productos. Intenta nuevamente.';
      });
    }
  }

  void _filtrarProductos() {
    final texto = _buscarCtrl.text.toLowerCase().trim();
    final filtrados = productos.where((p) {
      return p.nombre.toLowerCase().contains(texto) ||
          p.codigo.toLowerCase().contains(texto);
    }).toList();

    if (!mounted) return;
    setState(() => productosFiltrados = filtrados);
  }

  void _confirmarEliminar(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: 'Confirmar eliminación',
        message: '¿Seguro que deseas eliminar "${producto.nombre}"?',
        onConfirm: () async {
          try {
            await _service.deleteProducto(producto.idproducto!);
            if (!mounted) return;
            await _cargarProductos();
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo eliminar el producto')),
            );
          }
        },
      ),
    );
  }

 Future<void> _irACrear() async {
  await showProductoModal(context: context);
  if (!mounted) return;
  await _cargarProductos();
}

Future<void> _irAEditar(Producto p) async {
  await showProductoModal(
    context: context,
    producto: p,
  );
  if (!mounted) return;
  await _cargarProductos();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _cargarProductos,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
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
                                    "Productos",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Palette.primary,
                                    ),
                                  ),
                                  Text(
                                    "${productosFiltrados.length} productos encontrados",
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
                                  hintText: 'Buscar por nombre o código',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Palette.primary,
                                  ),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _cargarProductos,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (productosFiltrados.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: productosFiltrados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final producto = productosFiltrados[index];
                              return _ProductoListItem(
                                producto: producto,
                                onEdit: () => _irAEditar(producto),
                                onDelete: () =>
                                    _confirmarEliminar(context, producto),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // BOTÓN FLOTANTE
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton.extended(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  "Nuevo producto",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 10,
                onPressed: _irACrear,
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
            Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: Palette.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(
                fontSize: 17,
                color: Palette.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta buscar o crea uno nuevo',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// === ITEM DE LISTA ===
class _ProductoListItem extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductoListItem({
    required this.producto,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.card, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEdit,
          highlightColor: Palette.card.withOpacity(0.5),
          splashColor: Palette.primary.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // IMAGEN
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: producto.imagen != null && producto.imagen!.isNotEmpty
                      ? Image.network(
                          producto.imagen!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),

                const SizedBox(width: 18),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Palette.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            producto.categoria_nombre ?? 'Sin categoría',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Palette.secButton,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Código: ${producto.codigo}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Palette.ink,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "${producto.precio.toStringAsFixed(2)} Bs",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                     /* if (producto.descripcion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            producto.descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              color: Palette.primary.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),*/
                    ],
                  ),
                ),

                // ACCIONES
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.edit,
                      color: Palette.primary,
                      onTap: onEdit,
                      tooltip: "Editar",
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete,
                      color: Colors.red.shade600,
                      onTap: onDelete,
                      tooltip: "Eliminar",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Palette.primary.withOpacity(0.5),
        size: 32,
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
