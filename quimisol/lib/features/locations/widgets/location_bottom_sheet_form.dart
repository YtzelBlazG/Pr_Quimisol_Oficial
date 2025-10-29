import 'package:flutter/material.dart';
import '../../../shared/buttons/app_button.dart';

class LocationBottomSheetForm extends StatelessWidget {
  const LocationBottomSheetForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.dirCtrl,
    required this.cityCtrl,
    required this.lat,
    required this.lng,
    required this.expanded,
    required this.isSubmitting,
    required this.isGeocoding,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController dirCtrl;
  final TextEditingController cityCtrl;
  final double? lat;
  final double? lng;
  final bool expanded;
  final bool isSubmitting;
  final bool isGeocoding;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Ubicación de sucursal",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Nombre ubicación",
              hintText: "Ej: Sucursal Centro",
              prefixIcon: Icon(Icons.flag),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Requerido" : null,
          ),
          AnimatedCrossFade(
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Column(
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: dirCtrl,
                  decoration: InputDecoration(
                    labelText: "Dirección",
                    hintText: "Se completa al elegir el punto o una sugerencia",
                    prefixIcon: const Icon(Icons.place),
                    suffixIcon: isGeocoding
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Requerido" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ciudad",
                    hintText: "Se completa al elegir el punto o una sugerencia",
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Requerido" : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (lat == null || lng == null)
                        ? "Toca el mapa o usa el buscador para fijar el punto"
                        : "Lat: ${lat!.toStringAsFixed(6)}  •  Lng: ${lng!.toStringAsFixed(6)}",
                    style: TextStyle(
                      color: (lat == null) ? Colors.red : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: "Agregar",
                  icon: Icons.check,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ],
            ),
            secondChild: const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }
}
