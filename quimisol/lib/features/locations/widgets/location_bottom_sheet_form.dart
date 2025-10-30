import 'package:flutter/material.dart';

class LocationBottomSheetForm extends StatefulWidget {
  final String direccion;
  final String ciudad;
  final void Function(String nombre) onSave;
  const LocationBottomSheetForm({
    super.key,
    required this.direccion,
    required this.ciudad,
    required this.onSave,
  });

  @override
  State<LocationBottomSheetForm> createState() => _LocationBottomSheetFormState();
}

class _LocationBottomSheetFormState extends State<LocationBottomSheetForm> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 56, height: 6, decoration: BoxDecoration(
              color: Colors.black26, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            const Text('Ubicación de sucursal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.direccion, maxLines: 2)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.apartment_outlined, size: 18),
                const SizedBox(width: 6),
                Text(widget.ciudad),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
                hintText: 'Nombre ubicación (Casa, Oficina...)',
                filled: true,
                border: OutlineInputBorder(borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  widget.onSave(name);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
