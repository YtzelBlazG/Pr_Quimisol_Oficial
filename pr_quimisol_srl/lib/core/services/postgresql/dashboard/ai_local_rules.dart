import 'dart:math';

class LocalAi {
  static Map<String, dynamic> analyze(Map<String, dynamic> d) {
    final issues = <String>[];

    num nz(num? v) => (v ?? 0);
    final users = nz(d['totalUsers']);
    final prods = nz(d['totalProducts']);
    final orders = nz(d['totalOrders']);
    final pending = nz(d['ordersPending']);
    final lowStock = nz(d['lowStockCount']);
    final revToday = nz(d['revenueToday']);
    final revMonth = nz(d['revenueMonth']);

    // Reglas básicas
    if (users < 0 || prods < 0 || orders < 0) issues.add('Valores negativos en contadores.');
    if (revToday < 0 || revMonth < 0) issues.add('Ingresos negativos.');
    if (pending > orders) issues.add('Pendientes mayor que total de órdenes.');

    // Razones entre métricas
    if (orders > 0 && users > 0) {
      final r = orders / max(users, 1);
      if (r > 5) issues.add('Ordenes por usuario muy altas (>$r). Verificar bots o carga histórica.');
    }

    // Coherencia ingresos
    if (revMonth < revToday) issues.add('Ingresos del mes menores que los del día.');
    if (orders == 0 && revToday > 0) issues.add('Ingresos positivos sin órdenes registradas hoy.');

    // Stock
    if (lowStock > prods * 0.5 && prods > 0) {
      issues.add('Más del 50% del catálogo en stock bajo.');
    }

    return {
      'issues': issues,
      'fixes': {
        'recheckEndpoints': ['orders/count','revenue/today','revenue/month'],
        'consistencyQueries': ['SELECT ... COUNT(*)', 'SELECT ... SUM(total)'],
      }
    };
  }

  static String report(Map<String, dynamic> d) {
    String money(num? n) => 'Bs ${((n ?? 0).toDouble()).toStringAsFixed(2)}';
    return
      'Resumen del día:\n'
      '- Usuarios: ${d['totalUsers']}\n'
      '- Productos: ${d['totalProducts']}\n'
      '- Órdenes: ${d['totalOrders']} (Pendientes: ${d['ordersPending']})\n'
      '- Ingresos hoy: ${money(d['revenueToday'])}\n'
      '- Ingresos mes: ${money(d['revenueMonth'])}\n';
  }
}
