import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink[100],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // ✅ LOGO MÁS GRANDE Y VISIBLE
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://scontent.fcbb2-1.fna.fbcdn.net/v/t39.30808-6/485404527_685981397294255_4038830063392828407_n.jpg?stp=dst-jpg_p526x296_tt6&_nc_cat=100&ccb=1-7&_nc_sid=a5f93a&_nc_ohc=sGNg8NrVMDMQ7kNvwHiRTeu&_nc_oc=AdlzBuwYq-QHtLwXGph7iyBtcS86lEzmC9I7aiIDj6cpFxpwRUQtchL_deCLFRq5CnD1pjVBY4dDKMcFeo6r6ZZL&_nc_zt=23&_nc_ht=scontent.fcbb2-1.fna&_nc_gid=mF3kqWcQZLbGIqA6EZRCOw&oh=00_AfYF9MgFyMWjVkWA2qCZmh_AapadH6kKRAsBRaXUAlAKxA&oe=68DBDE2F',
              height: 80,
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 100);
              },
            ),
          ),

          const Spacer(),

          // 🔗 ENLACES DE NAVEGACIÓN
          TextButton(
            onPressed: () => Modular.to.navigate('/'),
            child: const Text('Inicio'),
          ),
          TextButton(
            onPressed: () => Modular.to.navigate('/productos'),
            child: const Text('Productos'),
          ),
          TextButton(
            onPressed: () => Modular.to.navigate('/unidades'),
            child: const Text('Unidades'),
          ),

          const SizedBox(width: 30),

          // 📞 SOPORTE, CUENTA, CARRITO
          Row(
            children: const [
              Icon(Icons.support_agent, color: Colors.purple),
              SizedBox(width: 5),
              Text(
                '(+591) 7492-3477',
                style: TextStyle(fontSize: 12),
              ),
              VerticalDivider(),
              Icon(Icons.person, color: Colors.purple),
              SizedBox(width: 5),
              Text('Cuenta'),
              VerticalDivider(),
              Icon(Icons.shopping_cart_outlined, color: Colors.purple),
              SizedBox(width: 5),
              Text('\$0'),
            ],
          ),
        ],
      ),
    );
  }
}
