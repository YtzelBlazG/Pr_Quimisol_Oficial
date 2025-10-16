import 'package:flutter/material.dart';
import 'feature_icon.dart';

class FeaturesRow extends StatelessWidget {
  const FeaturesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        FeatureIcon(icon: Icons.local_shipping, label: 'Entrega rápida'),
        FeatureIcon(icon: Icons.verified, label: 'Calidad garantizada'),
        FeatureIcon(icon: Icons.headset_mic, label: 'Atención personalizada'),
      ],
    );
  }
}
