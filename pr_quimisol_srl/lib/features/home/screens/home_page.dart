import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:quimisol/features/admin/widgets/footer.dart';
import 'package:quimisol/features/admin/widgets/top_bar.dart';

import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';
import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/home/actions/purchase_guard.dart';
import 'package:quimisol/features/home/widgets/featured_products.dart';
import 'package:quimisol/features/home/widgets/features_row.dart';
import 'package:quimisol/features/home/widgets/home_ctas.dart';
import 'package:quimisol/features/home/widgets/home_hero.dart';
import 'package:quimisol/features/home/widgets/units_section.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // === Backend para ubicaciones (requisito de compra)
  static const String _baseUrl = "http://localhost:3005";
  late final LocationsService _locationsService =
      LocationsService(baseUrl: _baseUrl);

  // === Productos destacados (inyectamos el service al widget)
  final _productoService = ProductoService();

  @override
  void initState() {
    super.initState();
    AuthStorage.init();
  }

  Future<void> _onComprar() async {
    await PurchaseGuard.attempt(context, _locationsService);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthStorage.loginStatus,
      builder: (context, loggedIn, _) {
        return Scaffold(
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(64),
            child: TopBar(),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const HomeHero(),
                const SizedBox(height: 20),
                HomeCTAs(
                  onViewProducts: () => Modular.to.navigate('/productos/'),
                  onComprar: _onComprar,
                ),
                const SizedBox(height: 28),
                // Productos Destacados
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Productos Destacados',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF432667),
                        ),
                  ),
                ),
                const SizedBox(height: 14),
                FeaturedProducts(
                  productoService: _productoService,
                  onViewMore: (p) {
                    // Aquí irá navegación a detalle
                    // Modular.to.pushNamed('/productos/detalle', arguments: p.id);
                  },
                ),
                const SizedBox(height: 28),
                const FeaturesRow(),
                const SizedBox(height: 28),
                const UnitsSection(),
                const SizedBox(height: 28),
                const Footer(),
              ],
            ),
          ),
          floatingActionButton: (!loggedIn)
              ? FloatingActionButton.extended(
                  onPressed: () => Modular.to.pushNamed('/auth/login'),
                  label: const Text('Iniciar sesión'),
                  icon: const Icon(Icons.login),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
