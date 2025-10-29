import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationSearchBar extends StatelessWidget {
  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchLoading,
    required this.onChanged,
    required this.onKey,
    required this.onClear,
    this.hintText = 'Buscar dirección o lugar...',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searchLoading;
  final ValueChanged<String> onChanged;
  final void Function(RawKeyEvent e) onKey;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: RawKeyboardListener(
          focusNode: focusNode,
          onKey: onKey,
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (searchLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (controller.text.isNotEmpty && !searchLoading)
                IconButton(
                  tooltip: 'Limpiar',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, color: Colors.black45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
