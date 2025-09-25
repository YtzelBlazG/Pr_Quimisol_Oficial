import 'package:flutter_modular/flutter_modular.dart';
import 'package:pr_quimisol_srl/features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/auth_module.dart';
import 'features/home/presentation/screens/home_page.dart';

class AppModule extends Module {
  @override
  void routes(RouteManager r) {
    r.module('/auth', module: AuthModule());
    r.child('/home', child: (_) => const HomePage());
    r.child('/auth/profile', child: (_) => const ProfileScreen());

    // ✅ Ahora la app inicia en HomePage
    r.redirect('/', to: '/home');
  }
}
