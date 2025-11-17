import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/features/admin/ciclo-entrega/ciclos_entrega_page.dart';

// ✅ Pedidos
import 'package:quimisol/features/admin/pedidos/screens/pedidos_list_page.dart';


// Pantallas principales
import 'package:quimisol/features/admin/presentation/screens/admin_user_page.dart';
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart';
import 'package:quimisol/features/auth/data/screens/profile_screen.dart';
import 'package:quimisol/features/admin/roles/pages/rol_create_page.dart';

// CRUDs
import 'package:quimisol/features/admin/productos/page/producto_list_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_list_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_list_page.dart';
import 'package:quimisol/features/admin/categorias/page/categoria_list_page.dart';

// TopBar
import 'package:quimisol/features/admin/widgets/top_bar.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? _userName;
  String? _userEmail;
  bool _loadingUser = true;

  // 👇 aquí se decide qué widget mostrar
  String _currentRoute = '/dashboard';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await AuthStorage.getNombre();
    final email = await AuthStorage.getCorreo();
    if (!mounted) return;
    setState(() {
      _userName = (name ?? '').trim().isEmpty ? 'Usuario' : name!.trim();
      _userEmail = (email ?? '').trim().isEmpty
          ? 'sin_correo@ejemplo.com'
          : email!.trim();
      _loadingUser = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AuthStorage.clear();
    Modular.to.pushReplacementNamed('/auth/login');
  }

  // 🔁 Navegación interna para TopBar + Drawer
  void _handleNavigation(String route) {
    if (route == '/logout') {
      _logout(context);
      return;
    }
    if (route == '/perfil') {
      _openProfile();
      return;
    }

    if (_currentRoute == route) return;

    setState(() => _currentRoute = route);
  }

  void _openProfile() {
    Navigator.of(context).maybePop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AdminTopBar(onNavigate: _handleNavigation),
      drawer: _buildDrawer(context),
      body: _buildContent(),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Palette.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (_userName != null && _userName!.isNotEmpty)
                      ? _userName!.substring(0, 1).toUpperCase()
                      : '🙂',
                  style: TextStyle(
                    color: Palette.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              accountName: Text(
                _loadingUser ? 'Cargando...' : (_userName ?? 'Usuario'),
                overflow: TextOverflow.ellipsis,
              ),
              accountEmail: Text(
                _loadingUser
                    ? 'Cargando...'
                    : (_userEmail ?? 'sin_correo@ejemplo.com'),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // === Navegación principal ===
            _DrawerItem(
              icon: Icons.dashboard,
              text: "Dashboard",
              selected: _currentRoute == '/dashboard',
              onTap: () => _handleNavigation('/dashboard'),
            ),
            _DrawerItem(
              icon: Icons.people,
              text: "Usuarios",
              selected: _currentRoute == '/usuarios',
              onTap: () => _handleNavigation('/usuarios'),
            ),
            _DrawerItem(
              icon: Icons.shopping_bag,
              text: "Productos",
              selected: _currentRoute == '/productos',
              onTap: () => _handleNavigation('/productos'),
            ),
            _DrawerItem(
              icon: Icons.category,
              text: "Categorías",
              selected: _currentRoute == '/categorias',
              onTap: () => _handleNavigation('/categorias'),
            ),
            _DrawerItem(
              icon: Icons.grid_view,
              text: "Unidades",
              selected: _currentRoute == '/unidades',
              onTap: () => _handleNavigation('/unidades'),
            ),
            _DrawerItem(
              icon: Icons.list_alt,
              text: "Detalle Productos",
              selected: _currentRoute == '/detalleproducto',
              onTap: () => _handleNavigation('/detalleproducto'),
            ),
            // (Opcional) también puedes poner un item para ciclos aquí
            /*
            _DrawerItem(
              icon: Icons.calendar_month,
              text: "Ciclos de entrega",
              selected: _currentRoute == '/ciclos-entrega',
              onTap: () => _handleNavigation('/ciclos-entrega'),
            ),
            */
            _DrawerItem(
              icon: Icons.settings,
              text: "Configuración",
              selected: _currentRoute == '/configuracion',
              onTap: () => _handleNavigation('/configuracion'),
            ),

            const Divider(),
            _DrawerItem(
              icon: Icons.person_outline,
              text: "Perfil",
              selected: false,
              onTap: _openProfile,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar Sesión"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.primary,
                  side: BorderSide(color: Palette.primary),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentRoute) {
      case '/dashboard':
        return const AdminDashboardPage();
      case '/usuarios':
        return const AdminUserPage();
      case '/usuarios/roles':
        return const RolCreatePage();
      case '/productos':
        return const ProductoListPage();
      case '/categorias':
        return const CategoriaListPage();
      case '/pedidos':
        return const PedidosListPage();
      case '/ciclos-entrega':                 // ✅ NUEVO CASE
        return const CiclosEntregaPage();
      case '/unidades':
        return const UnidadListPage();
      case '/detalleproducto':
        return const DetalleProductoListPage();
      case '/configuracion':
        return Center(
          child: Text(
            "⚙️ Configuración del Sistema",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      default:
        return const AdminDashboardPage();
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? Palette.primary : null),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? Palette.primary : null,
        ),
      ),
      selected: selected,
      selectedTileColor: Palette.primary.withOpacity(0.08),
      onTap: onTap,
    );
  }
}
