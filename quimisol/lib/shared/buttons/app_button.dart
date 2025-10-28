import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed; 
  final bool isLoading;
  final IconData? icon;
  

  const AppButton({
    super.key,
    required this.label,
    this.onPressed, 
    this.isLoading = false,
    this.icon, 
  });

  @override
  Widget build(BuildContext context) {
    // Si tiene icono → ElevatedButton.icon, sino → ElevatedButton normal
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: Colors.white),
        label: isLoading
            ? const SizedBox.shrink()
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }
}
