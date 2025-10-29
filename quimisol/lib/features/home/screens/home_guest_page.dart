import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/widgets/BeneficioItem.dart';
import 'package:quimisol/features/admin/widgets/categoryitem.dart';

class HomeGuestPage extends StatefulWidget {
  const HomeGuestPage({super.key});

  @override
  State<HomeGuestPage> createState() => _HomeGuestPageState();
}

class _HomeGuestPageState extends State<HomeGuestPage> {
  List<Producto> productos = [];

  // ✅ ScrollController agregado para el Scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final data = await ProductoService().getProductos();
    setState(() {
      productos = data;
    });
  }

  Future<void> _verificarSesionOLogin(VoidCallback accion) async {
    final logueado = await AuthStorage.isLoggedIn();
    if (!logueado) {
      Modular.to.pushNamed('/auth/login');
    } else {
      accion();
    }
  }

  // ✅ liberar el controlador
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E6FA),
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo-quimisol.png',
          height: 60,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.purple),
            onPressed: () => _verificarSesionOLogin(() {}),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Palette.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) => _verificarSesionOLogin(() {}),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟣 Hero Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                            onPressed: () => _verificarSesionOLogin(() {
                              Modular.to.pushNamed('/productos');
                            }),
                            child: const Text('Ver productos'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🟣 Beneficios
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

              // 🟣 Categorías
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
                  CategoriaItem(icon: Icons.medical_services, label: 'Desinfectantes'),
                ],
              ),
              const SizedBox(height: 24),

              // 🟣 Productos destacados
              const Text(
                'Productos destacados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: Scrollbar(
                  controller: _scrollController, // ✅ agregado
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController, // ✅ agregado
                    scrollDirection: Axis.horizontal,
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      return GestureDetector(
                        onTap: () => _verificarSesionOLogin(() {}),
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.network(
                                p.imagen ?? '',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bs ${p.precio}',
                                style: const TextStyle(color: Palette.primary),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _verificarSesionOLogin(() {}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.button,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                child: const Text('Ver'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


