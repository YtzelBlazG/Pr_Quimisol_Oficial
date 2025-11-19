import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';        // 👈 NUEVO

import 'app_module.dart';
import 'app_widget.dart';
import 'package:quimisol/core/providers/favoritos_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 inicializa los datos de formato para español
  await initializeDateFormatting('es', null);

  final favoritosProvider = FavoritosProvider();
  await favoritosProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => favoritosProvider),
      ],
      child: ModularApp(module: AppModule(), child: const AppWidget()),
    ),
  );
}
