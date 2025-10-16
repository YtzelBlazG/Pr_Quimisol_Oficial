// lib/features/admin/presentation/screens/admin_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/core/storage/auth_storage.dart';

// Pantallas
import 'package:quimisol/features/admin/presentation/screens/admin_user_page.dart';
// OJO: path correcto es "presentation", no "presentatios"
import 'package:quimisol/features/admin/presentation/screens/admin_dashboard_page.dart'
    hide Palette;
import 'package:quimisol/features/auth/data/screens/profile_screen.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Datos de usuario (mostrados en el Drawer)
  String? _userName;
  String? _userEmail;
  bool _loadingUser = true;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
    Tab(icon: Icon(Icons.people), text: "Usuarios"),
    Tab(icon: Icon(Icons.shopping_bag), text: "Productos"),
    Tab(icon: Icon(Icons.settings), text: "Configuración"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUser(); // ← carga nombre/correo
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
    Navigator.of(context).maybePop(); // cierra el Drawer
    setState(() {});
  }

  void _openProfile() {
    Navigator.of(context).maybePop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    // O con Modular:
    // Modular.to.pushNamed('/auth/profile');
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
                const AdminDashboardPage(),
                // ✅ SIN baseUrl: AdminUserPage usa Modular.get<UserAdminService>()
                const AdminUserPage(),
                _buildProductos(context),
                _buildConfiguracion(context),
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
            // Header con datos reales (nombre y correo)
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Palette.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  // inicial del nombre si existe, si no un ícono
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
              icon: Icons.settings,
              text: "Configuración",
              selected: current == 3,
              onTap: () => _goToTab(3),
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

  Widget _buildProductos(BuildContext context) {
    return Center(
      child: Text(
        "🛒 Gestión de Productos",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
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
