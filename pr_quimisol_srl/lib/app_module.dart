import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app_widget.dart';
import 'modules/admin/productos/producto_module.dart';
import 'modules/admin/unidades/unidad_module.dart';
import 'modules/admin/home/home_module.dart'; // 👈 nuevo módulo

class AppModule extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
    // Ruta inicial: Home
    ModuleRoute(Modular.initialRoute, module: HomeModule()),

    // Rutas a otros módulos
    ModuleRoute('/productos', module: ProductoModule()),
    ModuleRoute('/unidades', module: UnidadModule()),
  ];

  @override
  Widget get bootstrap => const AppWidget();
}
