import 'package:flutter/material.dart';

Future<void> showIncompleteDataDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? subtitle,
  List<String>? lines,
  Color color = Colors.deepPurple,
  String primaryText = "Entendido",
  VoidCallback? onPrimaryPressed,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono con efecto neumórfico
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      offset: const Offset(4, 4),
                      blurRadius: 10,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),

              // Subtítulo opcional
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],

              // Lista de datos faltantes
              if (lines != null && lines.isNotEmpty) ...[
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines
                      .map((e) => Text("• $e",
                          style: const TextStyle(color: Colors.black87)))
                      .toList(),
                ),
              ],

              const SizedBox(height: 20),

              // Botón principal
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPrimaryPressed != null) {
                    onPrimaryPressed();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  primaryText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
