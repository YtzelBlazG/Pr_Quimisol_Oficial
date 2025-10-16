import 'package:flutter/material.dart';

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          side: BorderSide(
            color: enabled ? const Color(0xFFE5E7EB) : const Color(0xFFF1F5F9),
          ),
          foregroundColor: enabled ? Colors.black87 : Colors.black38,
          disabledForegroundColor: Colors.black38,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
