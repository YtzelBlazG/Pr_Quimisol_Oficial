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
  final Map<String, dynamic> _menuItems = {
    "Dashboard": {"route": "/dashboard", "items": []},
    "Usuarios": {
      "items": [
        {"label": "Lista de Usuarios", "icon": Icons.people, "route": "/usuarios"},
        {
          "label": "Roles y Permisos",
          "icon": Icons.admin_panel_settings,
          "route": "/usuarios/roles"
        },
      ],
    },
    "Productos": {
      "items": [
        {"label": "Productos", "icon": Icons.shopping_bag, "route": "/productos"},
        {"label": "Categorías", "icon": Icons.category, "route": "/categorias"},
        {"label": "Unidades", "icon": Icons.grid_view, "route": "/unidades"},
        {
          "label": "Detalle Productos",
          "icon": Icons.list_alt,
          "route": "/detalleproducto"
        },
      ],
    },

    // 👉 MENÚ PEDIDOS CON SUBMENÚ
    "Pedidos": {
      "items": [
        {
          "label": "Lista de pedidos",
          "icon": Icons.receipt_long,
          "route": "/pedidos",
        },
        {
          "label": "Ciclos de entrega",
          "icon": Icons.calendar_month,
          "route": "/ciclos-entrega",
        },
      ],
    },

    "Configuración": {"items": []},
  };

  final Map<String, dynamic> _userMenu = {
    "items": [
      {"label": "Mi Perfil", "icon": Icons.person_outline, "route": "/perfil"},
      {"label": "Cerrar Sesión", "icon": Icons.logout, "route": "/logout"},
    ],
  };

  String? _hoveredMenu;
  OverlayEntry? _dropdownOverlay;

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  void _showDropdown(
    BuildContext context,
    String key,
    GlobalKey menuKey,
    List<Map<String, dynamic>> items,
  ) {
    _removeDropdown();
    if (items.isEmpty) return;

    final renderObj = menuKey.currentContext?.findRenderObject();
    if (renderObj is! RenderBox) return;

    final position = renderObj.localToGlobal(Offset.zero);
    final size = renderObj.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 4,
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
            ),
          ),
          Positioned(
            right: 16,
            top: 68,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Palette.primary,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // ─── Branding ────────────────────────────────────────────────
              Flexible(
                flex: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.science,
                          color: Palette.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Quimisol Admin",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Palette.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ─── Menú (scroll horizontal para evitar overflow) ───────────
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _menuItems.keys.map((key) {
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
                              List<Map<String, dynamic>>.from(
                                  _menuItems[key]!['items']),
                            );
                            setState(() => _hoveredMenu = key);
                          }
                        },
                        onExit: (_) {
                          if (hasSubmenu) {
                            Future.delayed(
                                const Duration(milliseconds: 200), () {
                              if (mounted && _hoveredMenu == key) {
                                setState(() => _hoveredMenu = null);
                              }
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextButton(
                            onPressed: () {
                              if (!hasSubmenu && route != null) {
                                widget.onNavigate?.call(route);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _hoveredMenu == key
                                  ? Palette.secButton
                                  : Colors.transparent,
                            ),
                            child: Text(
                              key,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Palette.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ─── Acciones derecha ────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconButton(Icons.search),
                  const SizedBox(width: 8),
                  _iconButton(
                    Icons.person,
                    onTap: () => _showUserMenu(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Palette.white, size: 22),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

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
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withOpacity(0.1),
          child: Container(
            width: 240,
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.fieldBg, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.items.map((item) {
                return InkWell(
                  onTap: () => widget.onSelect(item['route']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Palette.card,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            item['icon'],
                            color: Palette.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['label'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
