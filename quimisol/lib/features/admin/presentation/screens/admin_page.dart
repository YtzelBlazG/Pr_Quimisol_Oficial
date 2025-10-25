import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/storage/auth_storage.dart';

// Pantallas
import 'package:quimisol/features/admin/presentation/screens/admin_user_page.dart';
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart'
    hide Palette;
import 'package:quimisol/features/login/registro/data/screens/profile_screen.dart';

// CRUD: Productos, Unidades, DetalleProducto
import 'package:quimisol/features/admin/productos/page/producto_list_page.dart';
import 'package:quimisol/features/admin/unidades/page/unidad_list_page.dart';
import 'package:quimisol/features/admin/detalleproducto/page/detalleproducto_list_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _userName;
  String? _userEmail;
  bool _loadingUser = true;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
    Tab(icon: Icon(Icons.people), text: "Usuarios"),
    Tab(icon: Icon(Icons.shopping_bag), text: "Productos"),
    Tab(icon: Icon(Icons.shopping_bag), text: "Unidades"),
    Tab(icon: Icon(Icons.shopping_bag), text: "Detalle Productos"),
    Tab(icon: Icon(Icons.settings), text: "Configuración"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthStorage.clear();
    Modular.to.pushReplacementNamed('/auth/login');
  }

  void _goToTab(int index) {
    _tabController.index = index;
    Navigator.of(context).maybePop();
    setState(() {});
  }

  void _openProfile() {
    Navigator.of(context).maybePop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Palette.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              labelColor: Palette.primary,
              indicatorColor: Palette.primary,
              unselectedLabelColor: Colors.black54,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const AdminDashboardPage(),         // index 0
                const AdminUserPage(),              // index 1
                const ProductoListPage(),           // index 2
                const UnidadListPage(),             // index 3
                const DetalleProductoListPage(),    // index 4
                _buildConfiguracion(context),       // index 5
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final current = _tabController.index;

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
            _DrawerItem(
              icon: Icons.dashboard,
              text: "Dashboard",
              selected: current == 0,
              onTap: () => _goToTab(0),
            ),
            _DrawerItem(
              icon: Icons.people,
              text: "Usuarios",
              selected: current == 1,
              onTap: () => _goToTab(1),
            ),
            _DrawerItem(
              icon: Icons.shopping_bag,
              text: "Productos",
              selected: current == 2,
              onTap: () => _goToTab(2),
            ),
            _DrawerItem(
              icon: Icons.shopping_bag,
              text: "Unidades",
              selected: current == 3,
              onTap: () => _goToTab(3),
            ),
            _DrawerItem(
              icon: Icons.shopping_bag,
              text: "Detalle Productos",
              selected: current == 4,
              onTap: () => _goToTab(4),
            ),
            _DrawerItem(
              icon: Icons.settings,
              text: "Configuración",
              selected: current == 5,
              onTap: () => _goToTab(5),
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

  Widget _buildConfiguracion(BuildContext context) {
    return Center(
      child: Text(
        "⚙️ Configuración del Sistema",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
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
