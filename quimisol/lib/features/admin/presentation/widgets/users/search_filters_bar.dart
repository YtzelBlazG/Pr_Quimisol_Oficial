import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/role_chip.dart';
import 'package:quimisol/features/admin/presentation/widgets/users/activo_chip.dart';

class SearchFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueNotifier<String?> role; // admin|cliente|null
  final ValueNotifier<bool?> activo; // true|false|null
  final String sort; // nombre|correo|rol
  final ValueChanged<String> onSortChanged;
  final int shown;
  final int total;

  const SearchFiltersBar({
    super.key,
    required this.searchCtrl,
    required this.role,
    required this.activo,
    required this.sort,
    required this.onSortChanged,
    required this.shown,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFBFBFB),
                hintText: 'Buscar por nombre, correo, rol, estado, ubicación…',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                hintStyle: const TextStyle(color: Colors.black54),
                isDense: true,
                enabledBorder: _border(),
                focusedBorder: _border(color: Palette.primary),
                border: _border(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RoleChips(role: role),
                ActivoChips(activo: activo),
                _SortDropdown(value: sort, onChanged: onSortChanged),
                Chip(
                  backgroundColor: const Color(0xFFF3F4F6),
                  avatar:
                      const Icon(Icons.people, size: 18, color: Colors.black54),
                  label: Text('Mostrando $shown de $total'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color? color}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color ?? const Color(0xFFDDE2E7)),
      );
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
          items: const [
            DropdownMenuItem(value: 'nombre', child: Text('Orden: Nombre')),
            DropdownMenuItem(value: 'correo', child: Text('Orden: Correo')),
            DropdownMenuItem(value: 'rol', child: Text('Orden: Rol')),
          ],
          onChanged: (v) => onChanged(v ?? 'nombre'),
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
