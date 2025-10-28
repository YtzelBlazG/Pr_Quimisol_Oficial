import 'package:flutter/material.dart';

class ActivoChips extends StatelessWidget {
  final ValueNotifier<bool?> activo;
  const ActivoChips({super.key, required this.activo});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: activo,
      builder: (_, value, __) {
        Widget chip(String text, bool? val) {
          final selected = value == val;
          return ChoiceChip(
            label: Text(
              text,
              style: TextStyle(
                color: selected ? const Color(0xFF6A34AF) : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: selected,
            onSelected: (_) => activo.value = val,
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
        }

        return Wrap(
          spacing: 6,
          children: [
            chip('Todos', null),
            chip('Activos', true),
            chip('Inactivos', false),
          ],
        );
      },
    );
  }
}
