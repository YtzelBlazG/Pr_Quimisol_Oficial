import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_card.dart';

class ProductosPublicList extends StatefulWidget {
  const ProductosPublicList({super.key});

  @override
  State<ProductosPublicList> createState() => _ProductosPublicListState();
}

class _ProductosPublicListState extends State<ProductosPublicList> {
  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];
  List<dynamic> categorias = [];

  bool loading = true;
  int? categoriaSeleccionada;
  String textoBusqueda = '';
  String ordenSeleccionado = 'nombre_asc';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    cargarProductos();
    cargarCategorias();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final favoritosProvider =
        Provider.of<FavoritosProvider>(context, listen: false);
    favoritosProvider.checkAndUpdateUsuario();
  }

  Future<void> cargarCategorias() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3005/categorias'));
      if (response.statusCode == 200) {
        setState(() {
          categorias = jsonDecode(response.body);
        });
      } else {
        print('❌ Error al cargar categorías');
      }
    } catch (e) {
      print('❌ Excepción al cargar categorías: $e');
    }
  }

  Future<void> cargarProductos() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3005/productos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          productos = data;
          productosFiltrados = List.from(data);
          loading = false;
        });
        aplicarFiltros();
      } else {
        setState(() => loading = false);
        print('❌ Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      print('❌ Excepción cargando productos: $e');
    }
  }

  void aplicarFiltros() {
    List<dynamic> filtrados = productos.where((p) {
      final matchesCategoria =
          categoriaSeleccionada == null || p['idcategoria'] == categoriaSeleccionada;
      final matchesTexto = textoBusqueda.isEmpty ||
          p['nombre'].toString().toLowerCase().contains(textoBusqueda.toLowerCase()) ||
          p['codigo'].toString().toLowerCase().contains(textoBusqueda.toLowerCase());
      return matchesCategoria && matchesTexto;
    }).toList();

    switch (ordenSeleccionado) {
      case 'precio_asc':
        filtrados.sort((a, b) => (a['precio'] ?? 0).compareTo(b['precio'] ?? 0));
        break;
      case 'precio_desc':
        filtrados.sort((a, b) => (b['precio'] ?? 0).compareTo(a['precio'] ?? 0));
        break;
      case 'nombre_asc':
        filtrados.sort((a, b) => (a['nombre'] ?? '').compareTo(b['nombre'] ?? ''));
        break;
      case 'nombre_desc':
        filtrados.sort((a, b) => (b['nombre'] ?? '').compareTo(a['nombre'] ?? ''));
        break;
    }

    setState(() {
      productosFiltrados = filtrados;
    });
  }

  void onBuscar(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        textoBusqueda = value;
      });
      aplicarFiltros();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.purple[300],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Barra de búsqueda + filtros
          Container(
            color: Colors.purple[50],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onBuscar,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 🏷️ Categorías
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: categorias.any(
                                (cat) => cat['id'] == categoriaSeleccionada)
                            ? categoriaSeleccionada
                            : null,
                        hint: const Text("Categoría"),
                        onChanged: (value) {
                          setState(() => categoriaSeleccionada = value);
                          aplicarFiltros();
                        },
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("Todas")),
                          if (categorias.isNotEmpty)
                            ...categorias.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat['id'],
                                child: Text(cat['nombre']),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ↕️ Orden
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: ordenSeleccionado,
                        onChanged: (value) {
                          setState(() => ordenSeleccionado = value!);
                          aplicarFiltros();
                        },
                        items: const [
                          DropdownMenuItem(
                              value: 'nombre_asc', child: Text("Nombre A-Z")),
                          DropdownMenuItem(
                              value: 'nombre_desc', child: Text("Nombre Z-A")),
                          DropdownMenuItem(
                              value: 'precio_asc', child: Text("Precio ↑")),
                          DropdownMenuItem(
                              value: 'precio_desc', child: Text("Precio ↓")),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🧾 Lista de productos
          Expanded(
            child: productosFiltrados.isEmpty
                ? const Center(
                    child: Text('No hay productos disponibles.'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: productosFiltrados.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2 / 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final producto = productosFiltrados[index];
                      producto['categoria_nombre'] ??= 'Sin categoría';
                      return ProductoCard(producto: producto);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
