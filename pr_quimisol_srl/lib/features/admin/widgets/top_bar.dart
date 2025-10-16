import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/storage/auth_storage.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  // Rutas alineadas a AppModule
  static const _rutaHome = '/home';
  static const _rutaProductos = '/admin/productos'; // OJO: con barra final
  static const _rutaUnidades = '/admin/unidades'; // Unidades está en admin
  static const _rutaLogin = '/auth/login';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFCE9F3),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + nombre
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAXwAAACFCAMAAABv07OdAAABR1BMVEX///8AqFkEVqIAmEYApVEAplUAU6Hx+fXx8fHu7u+p3MEArVhju4gAqVj5/fwAo0zf9esAUaC56NKW2Ld1xpeQ0q3b2toltG8Lql13z6Vgw4739/efnp59ps6t4cjQ7d5ubG3o+PIYERPl5eXI7dyhuteD06sAAAB7enpTUVHm7fVdWlunpqZSwYqysbGHhofLy8uTkZIrbq8AS50/PD3Ix8esw9yBf4ANAAYgHB1FQkMAlTtnZWY2MjQ0eLWguddUhrw+uXvT4O0lZKkAnD0ARZsuKixdh7h5msiHo8PI1uQAsE6X37ebzrg5snFMyoYZvnAAU6+nweEZaba+zNtOr3iBs5xw1KB+w5acz6+GxZ4AozFksYVTecQAeHZhyYsASK4wcagnnG4Oe4kAkEoAYpUAl00AjFQAaIc1YcE/bcO72MjO498D5qkaAA==',
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'QUISIMOL SRL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF432667),
                ),
              ),
            ],
          ),

          // Nav + sesión
          ValueListenableBuilder<bool>(
            valueListenable: AuthStorage.loginStatus,
            builder: (context, loggedIn, _) {
              return Row(
                children: [
                  _navButton('Inicio', () => Modular.to.navigate(_rutaHome)),
                  _navButton(
                    'Productos',
                    () => Modular.to.navigate(_rutaProductos),
                  ),
                  _navButton(
                    'Unidades',
                    () => Modular.to.navigate(_rutaUnidades),
                  ),
                  const SizedBox(width: 12),
                  if (loggedIn)
                    TextButton.icon(
                      onPressed: () async {
                        await AuthStorage.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sesión cerrada')),
                          );
                        }
                        Modular.to.navigate(_rutaHome);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF5D3A99),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cerrar sesión'),
                    )
                  else
                    TextButton(
                      onPressed: () => Modular.to.pushNamed(_rutaLogin),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF5D3A99),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Iniciar Sesión'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF432667),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
