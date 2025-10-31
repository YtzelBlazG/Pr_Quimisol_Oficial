import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/core/theme/palette.dart';
import '../../../../shared/buttons/btn_floating_custom.dart';
import '../../../../shared/widgets/delete_dialog.dart';

class ProductoListPage extends StatefulWidget {
  const ProductoListPage({super.key});

  @override
  State<ProductoListPage> createState() => _ProductoListPageState();
}

class _ProductoListPageState extends State<ProductoListPage> {
  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];
  final TextEditingController _buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _buscarCtrl.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _buscarCtrl.removeListener(_filtrarProductos);
    _buscarCtrl.dispose();
    super.dispose();
 }

  Future<void> _cargarProductos() async {
    final data = await ProductoService().getProductos();
    setState(() {
      productos = data;
      productosFiltrados = data;
    });
  }

  void _filtrarProductos() {
    final texto = _buscarCtrl.text.toLowerCase();
    setState(() {
      productosFiltrados = productos
          .where(
            (p) =>
                p.nombre.toLowerCase().contains(texto) ||
                p.codigo.toLowerCase().contains(texto),
          )
          .toList();
    });
  }

  void _confirmarEliminar(BuildContext context, Producto producto) {
  showDialog(
    context: context,
    builder: (_) => ConfirmDeleteDialog(
      title: 'Confirmar eliminación',
      message: '¿Seguro que deseas eliminar "${producto.nombre}"?',
      onConfirm: () async {
        await ProductoService().deleteProducto(producto.idproducto!);
        await _cargarProductos();
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
            // === CONTENIDO PRINCIPAL ===
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // === TÍTULO + BUSCADOR ===
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

                      // === LISTA VERTICAL DE PRODUCTOS ===
                      productosFiltrados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60),
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 64, color: Palette.primary.withOpacity(0.3)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay productos para mostrar.',
                                      style: TextStyle(fontSize: 16, color: Palette.primary.withOpacity(0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: productosFiltrados.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];
                                return _ProductoListItem(
                                  producto: producto,
                                  onEdit: () async {
                                    await Modular.to.pushNamed(
                                      '/admin/productos/edit',
                                      arguments: producto,
                                    );
                                    await _cargarProductos();
                                  },
                                  onDelete: () => _confirmarEliminar(context, producto),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // === BOTÓN FLOTANTE ===
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButtonCustom(
                label: "Nuevo producto",
                icon: Icons.add,
                onPressed: () async {
                  await Modular.to.pushNamed('/admin/productos/create');
                  await _cargarProductos();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === ITEM DE LISTA (UNA FILA) ===
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          highlightColor: Palette.card.withOpacity(0.6),
          splashColor: Palette.button.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // === IMAGEN ===
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: producto.imagen != null && producto.imagen!.isNotEmpty
                      ? Image.network(
                          producto.imagen!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),

                const SizedBox(width: 18),

                // === INFORMACIÓN ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Palette.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Código: ${producto.codigo}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Palette.primary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "${producto.precio.toStringAsFixed(2)} Bs",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (producto.descripcion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            producto.descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              color: Palette.primary.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // === ACCIONES ===
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
      width: 60,
      height: 60,
      color: Palette.card,
      child: Icon(Icons.image_not_supported, color: Palette.primary.withOpacity(0.5), size: 30),
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
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}