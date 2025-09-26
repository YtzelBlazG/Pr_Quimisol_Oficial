import 'package:flutter_modular/flutter_modular.dart';

import 'controllers/producto_controller.dart';
import 'page/producto_list_page.dart';
import 'page/producto_create_page.dart';
import 'page/producto_edit_page.dart';

class ProductoModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton((i) => ProductoController()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const ProductoListPage()),
    ChildRoute('/crear', child: (_, __) => const ProductoCreatePage()),
    ChildRoute('/editar', child: (_, args) => ProductoEditPage(producto: args.data)),
  ];
}

