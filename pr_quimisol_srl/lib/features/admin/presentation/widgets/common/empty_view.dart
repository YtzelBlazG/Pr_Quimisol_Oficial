import 'package:flutter/material.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';

class EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  const EmptyView({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.black26),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: const TextStyle(color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
