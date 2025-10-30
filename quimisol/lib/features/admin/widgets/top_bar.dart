import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';

class AdminTopBar extends StatefulWidget implements PreferredSizeWidget {
  final void Function(String route)? onNavigate;

  const AdminTopBar({super.key, this.onNavigate});

  @override
  State<AdminTopBar> createState() => _AdminTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _AdminTopBarState extends State<AdminTopBar> {
  
  // Menú principal
  final Map<String, dynamic> _menuItems = {
    "Dashboard": {
      "route": "/dashboard", "items": [],
    },
    "Usuarios": {
      "items": [
        {"label": "Lista de Usuarios", "icon": Icons.people, "route": "/usuarios"},
        {
          "label": "Roles y Permisos",
          "icon": Icons.admin_panel_settings,
          "route": "/usuarios/roles",
        },
      ],
    },
    "Productos": {
      "items": [
        {"label": "Productos", "icon": Icons.shopping_bag, "route": "/productos"},
        {"label": "Unidades", "icon": Icons.grid_view, "route": "/unidades"},
        {
          "label": "Detalle Productos",
          "icon": Icons.list_alt,
          "route": "/detalleproducto",
        },
        {"label": "Pedidos", "icon": Icons.receipt_long, "route": "/pedidos"},
      ],
    },
    "Configuración": {
      "items": [],
    },
  };

  // Menú del usuario (perfil)
  final Map<String, dynamic> _userMenu = {
    "items": [
      {"label": "Mi Perfil", "icon": Icons.person_outline, "route": "/perfil"},
      {"label": "Cerrar Sesión", "icon": Icons.logout, "route": "/logout"},
    ],
  };

  String? _hoveredMenu;
  OverlayEntry? _dropdownOverlay;

  // Mostrar submenú bajo el botón exacto
  void _showDropdown(
    BuildContext context,
    String key,
    GlobalKey menuKey,
    List<Map<String, dynamic>> items,
  ) {
    _removeDropdown();

    if (items.isEmpty) return;

    final RenderBox? renderBox =
        menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy + size.height,
            child: _AnimatedDropdown(
              items: items,
              onSelect: (route) {
                _removeDropdown();
                widget.onNavigate?.call(route);
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  // Menú usuario (abre al hacer clic)
  void _showUserMenu(BuildContext context) {
    _removeDropdown();
    final items = _userMenu['items'] as List<Map<String, dynamic>>;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            right: 16,
            top: kToolbarHeight + 8,
            child: _AnimatedDropdown(
              items: items,
              onSelect: (route) {
                _removeDropdown();
                widget.onNavigate?.call(route);
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  // Build principal
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Palette.primary,
      elevation: 2,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Icon(Icons.science, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              "Quimisol Admin",
              style: TextStyle(
                color: Palette.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            ..._menuItems.keys.map((key) {
              final GlobalKey itemKey = GlobalKey();
              final hasSubmenu =
                  (_menuItems[key]!['items'] as List).isNotEmpty;
              final route = _menuItems[key]!['route'];

              return MouseRegion(
                key: itemKey,
                onEnter: (_) {
                  if (hasSubmenu) {
                    _showDropdown(
                      context,
                      key,
                      itemKey,
                      _menuItems[key]!['items'],
                    );
                    setState(() => _hoveredMenu = key);
                  }
                },
                onExit: (_) {
                  if (hasSubmenu) {
                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (!mounted) return;
                      _removeDropdown();
                      setState(() => _hoveredMenu = null);
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () {
                      // Dashboard u otros sin submenú → navegan directo
                      if (!hasSubmenu && route != null) {
                        widget.onNavigate?.call(route);
                      }
                    },
                    child: Text(
                      key,
                      style: TextStyle(
                        color: _hoveredMenu == key
                            ? Palette.button
                            : Palette.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // falta la búsqueda xd
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => _showUserMenu(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Dropdown animado
class _AnimatedDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onSelect;

  const _AnimatedDropdown({required this.items, required this.onSelect});

  @override
  State<_AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<_AnimatedDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.items.map((item) {
                return InkWell(
                  onTap: () => widget.onSelect(item['route']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'], color: Palette.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          item['label'],
                          style: const TextStyle(
                            color: Palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}