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
      productosFiltrados = productos.where((p) {
        return p.nombre.toLowerCase().contains(texto) ||
            p.codigo.toLowerCase().contains(texto);
      }).toList();
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
      appBar: AppBar(
        title: const Text("Productos"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 👉 Botón de nuevo producto
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo producto"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      await Modular.to.pushNamed('/admin/productos/create');
                      await _cargarProductos();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                /// 👉 Buscador
                TextField(
                  controller: _buscarCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                /// 👉 Tabla de productos
                productosFiltrados.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No hay productos para mostrar.'),
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Table(
                            columnWidths: const {
                              0: FixedColumnWidth(80), // Imagen
                              1: FlexColumnWidth(3), // Nombre
                              2: FlexColumnWidth(2), // Código
                              3: FlexColumnWidth(3), // Descripción
                              4: FlexColumnWidth(2), // Categoría
                              5: FlexColumnWidth(2), // Precio
                              6: FlexColumnWidth(2), // Acciones
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.grey.shade300),
                            ),
                            children: [
                              /// Encabezados
                              const TableRow(
                                decoration:
                                    BoxDecoration(color: Color(0xFFEAE6F1)),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Imagen',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Nombre',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Código',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Descripción',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Categoría',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Precio (Bs)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Acciones',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              /// Filas de productos
                              ...productosFiltrados.map((producto) {
                                return TableRow(
                                  decoration: const BoxDecoration(
                                      color: Colors.white),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: producto.imagen != null &&
                                                producto.imagen!.isNotEmpty
                                            ? CircleAvatar(
                                                radius: 26,
                                                backgroundImage: NetworkImage(
                                                    producto.imagen!),
                                                onBackgroundImageError:
                                                    (_, __) => const Icon(
                                                        Icons.broken_image),
                                              )
                                            : const CircleAvatar(
                                                radius: 26,
                                                child: Icon(Icons
                                                    .image_not_supported),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(producto.nombre),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(producto.codigo),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(producto.descripcion),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        producto.categoria_nombre ??
                                            'Sin categoría',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('${producto.precio} Bs'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            tooltip: "Editar",
                                            onPressed: () async {
                                              await Modular.to.pushNamed(
                                                '/admin/productos/edit',
                                                arguments: producto,
                                              );
                                              await _cargarProductos();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            tooltip: "Eliminar",
                                            onPressed: () => _confirmarEliminar(
                                                context, producto),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
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