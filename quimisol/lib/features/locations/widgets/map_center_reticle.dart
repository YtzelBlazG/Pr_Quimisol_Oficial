import 'package:flutter/material.dart';

class MapCenterReticle extends StatelessWidget {
  const MapCenterReticle({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Icon(
            Icons.add_location_alt,
            size: 28,
            color: active ? Colors.blueAccent : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
