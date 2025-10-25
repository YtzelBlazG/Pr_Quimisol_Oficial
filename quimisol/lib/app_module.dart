import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/features/admin/detalleproducto/data/models/detalleproducto_model.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_create_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_edit_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_list_page.dart';

// ====== MODELOS (para pasar objetos vía args en rutas /edit) ======
import 'package:quimisol/features/admin/productos/data/models/producto_model.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';

// ====== PÁGINAS ADMIN (del proyecto integrado) ======
// Usa el path correcto según tu repo:
import 'package:quimisol/features/admin/presentation/screens/admin_page.dart';
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart';
// Si en tu proyecto quedó como "presentatios", usa estos en su lugar:
// import 'package:quimisol/features/admin/presentatios/screens/admin_page.dart';
// import 'package:quimisol/features/admin/presentatios/screens/admin_dashboard_page.dart';

// Pantalla de Usuarios (refactor, bajo presentation/)
import 'package:quimisol/features/admin/presentation/screens/admin_user_page.dart';

// ====== PAGES PRODUCTOS ======
import 'package:quimisol/features/admin/productos/page/producto_list_page.dart';
import 'package:quimisol/features/admin/productos/page/producto_create_page.dart';
import 'package:quimisol/features/admin/productos/page/producto_edit_page.dart';

// ====== PAGES UNIDADES ======
import 'package:quimisol/features/admin/unidades/page/unidad_list_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_create_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_edit_page.dart';
import 'package:quimisol/features/home/screens/home_guest_page.dart';
import 'package:quimisol/features/home/screens/home_user_page.dart';

// ====== LAYOUT WRAPPER (opcional) ======
import 'package:quimisol/shared/widgets/MainLayout.dart';

// ============================================================
// ==  SECCIÓN: CLIENTES (Screens base)
// ============================================================
import 'package:quimisol/features/splash/screens/splash_screen.dart';
import 'package:quimisol/features/home/screens/home_page.dart';
import 'package:quimisol/features/locations/screens/add_location_map_page.dart';

// ====== (NUEVO) CLIENTE: Carrito & Pedidos ======
import 'package:quimisol/features/public/pages/carrito_page.dart';
import 'package:quimisol/features/pedidos/pedidos_page.dart';

// ============================================================
// ==  SECCIÓN: AUTH (API / Repository / Controller / Screens)
// ============================================================
import 'package:quimisol/features/login/registro/data/sources/auth_api.dart';
import 'package:quimisol/features/login/registro/data/repositories/auth_repository.dart';
import 'package:quimisol/features/login/registro/data/controllers/auth_controller.dart';
import 'package:quimisol/features/login/registro/data/screens/login_screen.dart';
import 'package:quimisol/features/login/registro/data/screens/profile_screen.dart';
// import 'package:quimisol/features/login/registro/data/screens/register_screen.dart';
// import 'package:quimisol/features/login/registro/data/screens/edit_profile_screen.dart';

// ============================================================
// ==  SERVICES & CONTROLLERS (Admin)
// ============================================================
import 'package:quimisol/core/services/postgresql/unidades/unidad_service.dart';
import 'package:quimisol/features/admin/unidades/controllers/unidad_controller.dart';

import 'package:quimisol/core/services/postgresql/productos/producto_service.dart';
import 'package:quimisol/features/admin/productos/controllers/producto_controller.dart';

import 'package:quimisol/core/services/postgresql/user_admin/user_admin_service.dart';

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
    i.addSingleton<AuthApi>(() => AuthApi()); // usa DioClient.instance internamente
    i.addSingleton<AuthRepository>(() => AuthRepository(i<AuthApi>()));
    i.addSingleton<AuthController>(() => AuthController(i<AuthRepository>()));

    // =========================
    // ADMIN: SERVICES
    // =========================
    // Según tus clases actuales, NO reciben baseUrl por constructor:
    i.addLazySingleton<UnidadService>(() => UnidadService());
    i.addLazySingleton<ProductoService>(() => ProductoService());

    // Este SÍ recibe baseUrl:
    i.addLazySingleton<UserAdminService>(
      () => UserAdminService(baseUrl: Env.apiBaseUrl),
    );

    // =========================
    // ADMIN: CONTROLLERS
    // =========================
    // Constructores sin named param 'service'
    i.addLazySingleton<UnidadController>(() => UnidadController());
    i.addLazySingleton<ProductoController>(() => ProductoController());
  }

  // ---------------------------------------------------------------------------
  // ROUTES
  // ---------------------------------------------------------------------------
  @override
  void routes(RouteManager r) {
    // Clientes
    r.child('/', child: (_) => const SplashScreen());
    r.child('/home-guest', child: (_) => const HomeGuestPage());
    r.child('/home-user', child: (_) => const HomeUserPage());
    r.child('/locations/add', child: (_) => const AddLocationMapPage());

    // ====== (NUEVO) CLIENTE: Carrito & Pedidos ======
    r.child('/carrito', child: (_) => const CarritoPage());   // NEW
    r.child('/pedidos', child: (_) => const PedidosPage()); // NEW

    // Auth
    r.child('/auth/login', child: (_) => const LoginPage());
    r.child('/auth/profile', child: (_) => const ProfileScreen());
    // r.child('/auth/register', child: (_) => const RegisterScreen());
    // r.child('/auth/profile/edit'
    // , child: (_) => const EditProfileScreen());

    // Admin – Shell / Dashboard
    r.child('/admin', child: (_) => const AdminPage());
    //r.child('/admin/home', child: (_) => const MainLayout(child: HomePage()));
    r.child('/admin/dashboard', child: (_) => const AdminDashboardPage());

    // Admin – Usuarios (SIN baseUrl en el widget)
    //r.child('/admin/usuarios', child: (_) => AdminUserPage(baseUrl: Env.apiBaseUrl));

    // Admin – Productos
    r.child('/admin/productos', child: (_) => const ProductoListPage());
    r.child('/admin/productos/create', child: (_) => const ProductoCreatePage());
    r.child('/admin/productos/edit', child: (_) {
      final producto = Modular.args.data as Producto;
      return ProductoEditPage(producto: producto);
    });

    // Admin – Unidades
    r.child('/admin/unidades', child: (_) => const UnidadListPage());
    r.child('/admin/unidades/create', child: (_) => const UnidadCreatePage());
    r.child('/admin/unidades/edit', child: (_) {
      final unidad = Modular.args.data as Unit;
      return UnidadEditPage(unidad: unidad);
    });

    // Admin – Detalle Producto
    r.child('/admin/detalleproducto', child: (_) => const DetalleProductoListPage());
    r.child('/admin/detalleproducto/create', child: (_) => const DetalleProductoCreatePage());
    r.child('/admin/detalleproducto/edit', child: (_) {
      final detalle = Modular.args.data as DetalleProducto;
      return DetalleProductoEditPage(detalle: detalle);
    });
  }
}
