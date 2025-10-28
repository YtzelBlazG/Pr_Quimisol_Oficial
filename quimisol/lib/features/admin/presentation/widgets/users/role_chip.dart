import 'package:flutter/material.dart';

class RoleChips extends StatelessWidget {
  final ValueNotifier<String?> role;
  const RoleChips({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final roles = <String?>[null, 'admin', 'cliente'];
    final labels = {null: 'Todos', 'admin': 'Admin', 'cliente': 'Cliente'};

    return ValueListenableBuilder<String?>(
      valueListenable: role,
      builder: (_, value, __) {
        return Wrap(
          spacing: 6,
          children: roles.map((r) {
            final selected = value == r;
            return ChoiceChip(
              label: Text(
                labels[r]!,
                style: TextStyle(
                  color: selected ? const Color(0xFF6A34AF) : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              onSelected: (_) => role.value = (value == r) ? null : r,
              selectedColor: const Color(0xFF6A34AF).withOpacity(.12),
              backgroundColor: const Color(0xFFF3F4F6),
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF6A34AF)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
