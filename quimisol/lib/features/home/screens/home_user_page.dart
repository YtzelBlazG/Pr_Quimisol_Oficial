import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/widgets/BeneficioItem.dart';
import 'package:quimisol/features/admin/widgets/categoryitem.dart';
import 'package:quimisol/features/admin/productos/widgets/producto_card.dart';
import 'package:quimisol/features/admin/productos/page/productos_public_list.dart';
import 'package:quimisol/features/home/screens/home_user_perfil.dart';
import 'package:quimisol/features/public/pages/carrito_page.dart';

class HomeUserPage extends StatefulWidget {
  const HomeUserPage({super.key});

  @override
  State<HomeUserPage> createState() => _HomeUserPageState();
}

class _HomeUserPageState extends State<HomeUserPage> {
  int _currentIndex = 0;
  List<dynamic> productos = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final data = await ProductoService().getProductos();
    setState(() {
      productos = data
          .map(
            (p) => {
              "idproducto": p.idproducto,
              "nombre": p.nombre,
              "precio": p.precio,
              "imagen": p.imagen,
              "stock_disponible": p.stockDisponible ?? 0,
            },
          )
          .toList();
    });
  }

  /// 🏠 HOME
  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/inicio.png',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Soluciones industriales para tu negocio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: () {
                          setState(
                            () => _currentIndex = 1,
                          ); // 🔁 cambia a Productos
                        },
                        child: const Text('Ver productos'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Beneficios
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              BeneficioItem(icon: Icons.local_shipping, label: 'Envío rápido'),
              BeneficioItem(icon: Icons.science, label: 'Alta calidad'),
              BeneficioItem(icon: Icons.headset_mic, label: 'Soporte'),
              BeneficioItem(icon: Icons.store, label: 'Industria local'),
            ],
          ),
          const SizedBox(height: 24),

          // Categorías
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              CategoriaItem(icon: Icons.cleaning_services, label: 'Limpieza'),
              CategoriaItem(icon: Icons.bubble_chart, label: 'Detergentes'),
              CategoriaItem(icon: Icons.inventory, label: 'Insumos'),
              CategoriaItem(
                icon: Icons.medical_services,
                label: 'Desinfectantes',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Productos destacados
          const Text(
            'Productos destacados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: productos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return SizedBox(
                    width: 180,
                    child: ProductoCard(producto: producto),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 Logout completo
  Future<void> _onLogout() async {
    await AuthStorage.clear();
    Provider.of<FavoritosProvider>(context, listen: false).clear();
    Modular.to.navigate('/home-guest');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🌍 Cuerpo según pestaña
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildHome();
      case 1:
        return const ProductosPublicList();
      case 2:
        return const CarritoPage();
      case 3:
        return const HomeUserPerfil();
      default:
        return const Center(child: Text("Página no encontrada"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF3E6FA),
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/logo-quimisol.png', height: 60),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Palette.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Palette.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Productos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
