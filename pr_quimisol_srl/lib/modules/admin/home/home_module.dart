import 'package:flutter_modular/flutter_modular.dart';
import 'page/home_page.dart';


class HomeModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(Modular.initialRoute, child: (_, __) => const HomePage()),
  ];
}
