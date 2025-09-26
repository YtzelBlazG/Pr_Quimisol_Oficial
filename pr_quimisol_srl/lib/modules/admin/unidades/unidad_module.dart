import 'package:flutter_modular/flutter_modular.dart';

import 'controllers/unidad_controller.dart';
import 'page/unidad_list_page.dart';
import 'page/unidad_create_page.dart';
import 'page/unidad_edit_page.dart';

class UnidadModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton((i) => UnidadController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const UnidadListPage()),
    ChildRoute('/crear', child: (_, __) => const UnidadCreatePage()),
    ChildRoute('/editar', child: (_, args) => UnidadEditPage(unidad: args.data)),
  ];
}
