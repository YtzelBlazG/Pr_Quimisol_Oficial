import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/controllers/auth_controller.dart';
import 'data/repositories/auth_repository.dart';
import 'data/sources/auth_api.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<AuthApi>(() => AuthApi());
    i.addSingleton<AuthRepository>(() => AuthRepository(i()));
    i.addSingleton<AuthController>(() => AuthController(i()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/login', child: (_) => const LoginPage());
    r.child('/register', child: (_) => const RegisterPage());
  }
}
