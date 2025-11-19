import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/features/admin/ciclo-entrega/ciclos_entrega_page.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_create_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_edit_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_list_page.dart';
import 'package:quimisol/features/admin/pedidos/screens/pedidos_list_page.dart';

// ====== MODELOS (para pasar objetos vía args en rutas /edit) ======
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';
import 'package:quimisol/features/admin/categorias/data/categoria_model.dart';

// ====== PÁGINAS ADMIN (del proyecto integrado) ======
import 'package:quimisol/features/admin/presentation/screens/admin_page.dart';
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart';

// ====== PAGES PRODUCTOS ======
import 'package:quimisol/features/admin/productos/page/producto_list_page.dart';
import 'package:quimisol/features/admin/productos/page/producto_create_page.dart';
import 'package:quimisol/features/admin/productos/page/producto_edit_page.dart';

// ====== PAGES UNIDADES ======
import 'package:quimisol/features/admin/unidades/page/unidad_list_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_create_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_edit_page.dart';

// 🔹 Mapa repartidor
import 'package:quimisol/features/distributor/distributor_map/screens/location_route_page.dart';

// 🔹 Home repartidor
import 'package:quimisol/features/distributor/home/screens/home_distributor_page.dart';

// Homes cliente / invitado
import 'package:quimisol/features/home/screens/home_guest_page.dart';
import 'package:quimisol/features/home/screens/home_user_page.dart';

// ====== PAGES CATEGORIAS ======
import 'package:quimisol/features/admin/categorias/page/categoria_create_page.dart';
import 'package:quimisol/features/admin/categorias/page/categoria_edit_page.dart';
import 'package:quimisol/features/admin/categorias/page/categoria_list_page.dart';

import 'package:quimisol/features/locations/screens/location_edit_page.dart';
import 'package:quimisol/features/locations/screens/locations_list_page.dart';
import 'package:quimisol/features/pedidos/pages/select_location_page.dart';

// ============================================================
// ==  SECCIÓN: CLIENTES (Screens base)
// ============================================================
import 'package:quimisol/features/splash/screens/splash_screen.dart';
import 'package:quimisol/features/locations/screens/add_location_map_page.dart';

// ====== (NUEVO) CLIENTE: Carrito & Pedidos ======
import 'package:quimisol/features/public/pages/carrito_page.dart';
import 'package:quimisol/features/pedidos/pages/pedidos_page.dart';

// ============================================================
// ==  SECCIÓN: AUTH (API / Repository / Controller / Screens)
// ============================================================
import 'package:quimisol/features/auth/data/sources/auth_api.dart';
import 'package:quimisol/features/auth/data/repositories/auth_repository.dart';
import 'package:quimisol/features/auth/data/controllers/auth_controller.dart';
import 'package:quimisol/features/auth/data/screens/login_screen.dart';
import 'package:quimisol/features/auth/data/screens/profile_screen.dart';

// ============================================================
// ==  SERVICES & CONTROLLERS (Admin)
// ============================================================
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/features/admin/unidades/controllers/unidad_controller.dart';

import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/productos/controllers/producto_controller.dart';

import 'package:quimisol/core/services/postgresql/user_admin/user_admin_service.dart';

// ====== CONTROLLER CATEGORÍAS ======
import 'package:quimisol/features/admin/categorias/controllers/categoria_controller.dart';

// ====== SERVICE CATEGORÍAS ======
import 'package:quimisol/core/services/postgresql/categorias/categoria_service.dart';
import 'package:quimisol/features/public/favoritos/favoritos_page.dart';

// ============================================================
// ==  CONFIG
// ============================================================
import 'package:quimisol/core/config/env.dart';


class AppModule extends Module {
  // ---------------------------------------------------------------------------
  // BINDS (DI)
  // ---------------------------------------------------------------------------
  @override
  void binds(Injector i) {
    // =========================
    // AUTH
    // =========================
    i.addSingleton<AuthApi>(() => AuthApi());
    i.addSingleton<AuthRepository>(() => AuthRepository(i<AuthApi>()));
    i.addSingleton<AuthController>(() => AuthController(i<AuthRepository>()));

    // =========================
    // ADMIN: SERVICES
    // =========================
    i.addLazySingleton<UnidadService>(() => UnidadService());
    i.addLazySingleton<ProductoService>(() => ProductoService());
    i.addLazySingleton<CategoriaService>(() => CategoriaService());

    i.addLazySingleton<UserAdminService>(
      () => UserAdminService(baseUrl: Env.apiBaseUrl),
    );

    // =========================
    // ADMIN: CONTROLLERS
    // =========================
    i.addLazySingleton<UnidadController>(() => UnidadController());
    i.addLazySingleton<ProductoController>(() => ProductoController());
    i.addLazySingleton<CategoriaController>(() => CategoriaController());
  }

  // ---------------------------------------------------------------------------
  // ROUTES
  // ---------------------------------------------------------------------------
  @override
  void routes(RouteManager r) {
    // Clientes / splash
    r.child('/', child: (_) => const SplashScreen());
    r.child('/home-guest', child: (_) => const HomeGuestPage());
    r.child('/home-user', child: (_) => const HomeUserPage());
    r.child('/favoritos', child: (_) => const FavoritosPage());

    // Repartidor
    r.child('/home-repartidor', child: (_) => const HomeRepartidorPage());

    // Ruta mapa: desde mi ubicación actual hasta la ubicación seleccionada
    r.child('/location-route', child: (_) {
      final data = Modular.args.data as Map<String, dynamic>;

      return LocationRoutePage(
        idubicacion: data['idubicacion'] as int,
        idPedido: data['idPedido'] as int, // 👈 AÑADIDO
        nombre: (data['nombre'] ?? '') as String,
        latitud: (data['latitud'] as num).toDouble(),
        longitud: (data['longitud'] as num).toDouble(),
      );
    });

    // Locations
    r.child(
      '/locations/add',
      child: (_) => AddLocationMapPage(baseUrl: Env.apiBaseUrl),
    );
    r.child('/locations', child: (_) => const LocationsListPage());
    r.child('/locations/view', child: (_) => LocationViewerPage.fromArgs());

    // Cliente: Carrito & Pedidos
    r.child('/carrito', child: (_) => const CarritoPage());
    r.child('/pedidos', child: (_) => const PedidosPage());
    r.child(
      '/locations/select',
      child: (_) => const SelectLocationsPage(),
    );

    // Auth
    r.child('/auth/login', child: (_) => const LoginPage());
    r.child('/auth/profile', child: (_) => const ProfileScreen());

    // Admin – Shell / Dashboard
    r.child('/admin', child: (_) => const AdminPage());
    r.child('/admin/dashboard', child: (_) => const AdminDashboardPage());

    // Admin – Productos
    r.child('/admin/productos', child: (_) => const ProductoListPage());
    r.child('/admin/productos/create', child: (_) => const ProductoCreatePage());
    r.child(
      '/admin/productos/edit',
      child: (_) {
        final producto = Modular.args.data as Producto;
        return ProductoEditPage(producto: producto);
      },
    );

    // Admin – Unidades
    r.child('/admin/unidades', child: (_) => const UnidadListPage());
    r.child('/admin/unidades/create', child: (_) => const UnidadCreatePage());
    r.child(
      '/admin/unidades/edit',
      child: (_) {
        final unidad = Modular.args.data as Unit;
        return UnidadEditPage(unidad: unidad);
      },
    );

    // Admin – Detalle Producto
    r.child(
      '/admin/detalleproducto',
      child: (_) => const DetalleProductoListPage(),
    );
    r.child(
      '/admin/detalleproducto/create',
      child: (_) => const DetalleProductoCreatePage(),
    );
    r.child(
      '/admin/detalleproducto/edit',
      child: (_) {
        final detalle = Modular.args.data as DetalleProducto;
        return DetalleProductoEditPage(detalle: detalle);
      },
    );

    // Admin – Categorías
    r.child('/admin/categorias', child: (_) => const CategoriaListPage());
    r.child(
      '/admin/categorias/create',
      child: (_) => const CategoriaCreatePage(),
    );
    r.child(
      '/admin/categorias/edit',
      child: (_) {
        final categoria = Modular.args.data as Categoria;
        return CategoriaEditPage(categoria: categoria);
      },
    );

    // Admin – Pedidos & ciclos
    r.child('/admin/pedidos', child: (_) => const PedidosListPage());
    r.child('/admin/ciclos-entrega', child: (_) => const CiclosEntregaPage());
  }
}
