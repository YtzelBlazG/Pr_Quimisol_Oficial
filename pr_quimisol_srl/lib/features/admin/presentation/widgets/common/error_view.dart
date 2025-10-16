import 'package:flutter/material.dart';
import 'package:quimisol/core/theme/palette.dart';
import 'package:quimisol/features/admin/presentation/widgets/common/glass.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Glass(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amberAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, color: Palette.primary),
                  label: const Text('Reintentar',
                      style: TextStyle(color: Palette.primary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
