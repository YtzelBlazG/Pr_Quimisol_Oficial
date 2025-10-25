import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:quimisol/shared/modals/incomplete_data_message.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';

class PurchaseGuard {
  static Future<void> attempt(
    BuildContext context,
    LocationsService locationsService,
  ) async {
    final bool loggedIn = AuthStorage.loginStatus.value;

    if (!loggedIn) {
      await showIncompleteDataDialog(
        context,
        icon: Icons.lock_outline_rounded,
        title: 'Necesitas iniciar sesión',
        subtitle: 'Para completar la compra primero inicia sesión.',
        color: Colors.deepPurple,
        primaryText: 'Iniciar sesión',
        onPrimaryPressed: () => Modular.to.pushNamed('/auth/login'),
      );
      return;
    }

    final nombre = await AuthStorage.getNombre();
    final correo = await AuthStorage.getCorreo();
    final telefono = await AuthStorage.getTelefono();
    final idPersona = await AuthStorage.getIdPersona();

    bool tieneUbicacion = false;
    if (idPersona != null) {
      try {
        final locs = await locationsService.listLocations(idPersona);
        tieneUbicacion = locs.isNotEmpty;
      } catch (_) {
        tieneUbicacion = false;
      }
    }

    final List<String> faltantes = [];
    if (nombre == null || nombre.trim().isEmpty) faltantes.add('Nombre');
    if (correo == null || correo.trim().isEmpty) faltantes.add('Correo');
    if (telefono == null || telefono.trim().isEmpty) faltantes.add('Teléfono');
    if (!tieneUbicacion) faltantes.add('Ubicación');

    if (faltantes.isEmpty) {
      await showIncompleteDataDialog(
        context,
        icon: Icons.check_circle_rounded,
        title: '✅ Comprado con éxito',
        color: Colors.green,
        primaryText: 'Listo',
        onPrimaryPressed: () {},
      );
    } else {
      await showIncompleteDataDialog(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Información incompleta',
        subtitle: 'Por favor complete la siguiente información:',
        lines: faltantes,
        color: Colors.redAccent,
        primaryText: 'Registrar',
        onPrimaryPressed: () => Modular.to.pushNamed('/auth/profile'),
      );
    }
  }
}
