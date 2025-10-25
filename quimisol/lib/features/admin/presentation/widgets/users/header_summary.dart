import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';

class HeaderSummary extends StatelessWidget {
  final int total;
  final int activos;
  const HeaderSummary({super.key, required this.total, required this.activos});

  @override
  Widget build(BuildContext context) {
    final inactivos = total - activos;
    return Glass(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TitleRow(
              icon: Icons.people_alt_rounded,
              title: 'Usuarios',
              subtitle: 'Resumen general',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                StatPill(icon: Icons.all_inclusive, label: 'Total'),
                StatPill(icon: Icons.check_circle, label: 'Activos'),
                StatPill(icon: Icons.cancel, label: 'Inactivos'),
              ],
            ),
            const SizedBox(height: 8),
            // Valores
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _valueText('$total'),
                _valueText('$activos'),
                _valueText('$inactivos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _valueText(String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _TitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _TitleRow({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Palette.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
      ],
    );
  }
}

class StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const StatPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
