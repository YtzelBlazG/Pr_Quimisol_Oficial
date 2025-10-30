// admin_dashboard_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/* ===========================
 *  Paleta
 * =========================== */
class Palette {
  static const primary = Color(0xFF2563EB);
  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFDC2626);
  static const slate = Color(0xFF0F172A);
}

/* ===========================
 *  Página
 * =========================== */

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // <- AJUSTA TU BACKEND
  static const _apiBase = 'http://localhost:3005';

  late final AdminStatsService _service;
  late final AiDashboardService _ai;

  bool _loading = true;
  String? _error;
  AdminSummary _summary = AdminSummary.empty();

  // Estado IA
  String? _aiReport;
  List<String> _aiIssues = [];
  String? _aiAnswer;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _service = AdminStatsService(baseUrl: _apiBase);
    _ai = AiDashboardService(baseUrl: _apiBase);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.fetchSummary();
      if (!mounted) return;
      setState(() => _summary = s);
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
      setState(() => _error = 'No se pudo cargar el dashboard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _payloadForAi() => {
    'totalUsers': _summary.totalUsers,
    'totalProducts': _summary.totalProducts,
    'totalOrders': _summary.totalOrders,
    'ordersPending': _summary.ordersPending,
    'lowStockCount': _summary.lowStockCount,
    'revenueToday': _summary.revenueToday,
    'revenueMonth': _summary.revenueMonth,
    'recentOrders': _summary.recentOrders
        .map(
          (e) => {
            'id': e.id,
            'code': e.code,
            'customer': e.customer,
            'items': e.items,
            'total': e.total,
            'status': e.status,
          },
        )
        .toList(),
    'topProducts': _summary.topProducts
        .map((e) => {'name': e.name, 'sold': e.sold, 'revenue': e.revenue})
        .toList(),
    'lowStock': _summary.lowStockItems
        .map((e) => {'name': e.name, 'stock': e.stock, 'minStock': e.minStock})
        .toList(),
  };

  void _openAiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setMState) {
          Future<void> _runReport() async {
            setMState(() => _aiLoading = true);
            try {
              final rep = await _ai.generateExecutiveReport(_payloadForAi());
              setMState(() {
                _aiReport = rep.summary;
                _aiIssues = [];
                _aiAnswer = null;
              });
            } catch (_) {
              // Fallback local
              final rep = LocalAi.report(_payloadForAi());
              setMState(() {
                _aiReport = rep;
                _aiIssues = [];
                _aiAnswer = null;
              });
            } finally {
              setMState(() => _aiLoading = false);
            }
          }

          Future<void> _runIrregularities() async {
            setMState(() => _aiLoading = true);
            try {
              final res = await _ai.analyzeIrregularities(_payloadForAi());
              setMState(() {
                _aiIssues = res.issues;
                _aiReport = null;
                _aiAnswer = null;
              });
            } catch (_) {
              final res = LocalAi.analyze(_payloadForAi());
              setMState(() {
                _aiIssues = (res['issues'] as List).cast<String>();
                _aiReport = null;
                _aiAnswer = null;
              });
            } finally {
              setMState(() => _aiLoading = false);
            }
          }

          final controller = TextEditingController();
          Future<void> _ask() async {
            final q = controller.text.trim();
            if (q.isEmpty) return;
            setMState(() => _aiLoading = true);
            try {
              final ans = await _ai.ask(q, _payloadForAi());
              setMState(() {
                _aiAnswer = ans;
                _aiReport = null;
                _aiIssues = [];
              });
            } catch (_) {
              setMState(() => _aiAnswer = 'No pude consultar la IA ahora.');
            } finally {
              setMState(() => _aiLoading = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Asistente IA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (_aiLoading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _runReport,
                      icon: const Icon(Icons.description),
                      label: const Text('Reporte'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _runIrregularities,
                      icon: const Icon(Icons.rule_folder),
                      label: const Text('Irregularidades'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Pregúntale a la IA (ej: ¿qué cambió vs ayer?)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _ask,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_aiReport != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_aiReport!, textAlign: TextAlign.left),
                  ),
                if (_aiIssues.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Irregularidades:',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final i in _aiIssues)
                    Align(alignment: Alignment.centerLeft, child: Text('• $i')),
                ],
                if (_aiAnswer != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_aiAnswer!, textAlign: TextAlign.left),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Palette.orange,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _SectionTitle(
                    title: 'Resumen',
                    subtitle: 'Métricas principales para administrar',
                  ),
                  const SizedBox(height: 8),
                  _KpiGrid(summary: _summary),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth >= 920;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _RecentOrdersCard(
                                orders: _summary.recentOrders,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TopProductsCard(
                                items: _summary.topProducts,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _LowStockCard(
                                items: _summary.lowStockItems,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _RecentOrdersCard(orders: _summary.recentOrders),
                          const SizedBox(height: 16),
                          _TopProductsCard(items: _summary.topProducts),
                          const SizedBox(height: 16),
                          _LowStockCard(items: _summary.lowStockItems),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAiSheet,
        icon: const Icon(Icons.smart_toy),
        label: const Text('IA'),
      ),
    );
  }
}

/* ===========================
 *  UI Widgets
 * =========================== */

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.insights, color: Palette.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AdminSummary summary;
  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _KpiTile(
        icon: Icons.people_alt_rounded,
        label: 'Usuarios',
        value: _fmt(summary.totalUsers),
        color: Palette.primary,
      ),
      _KpiTile(
        icon: Icons.shopping_bag_rounded,
        label: 'Productos',
        value: _fmt(summary.totalProducts),
        color: Colors.teal,
      ),
      _KpiTile(
        icon: Icons.receipt_long_rounded,
        label: 'Pedidos',
        value: _fmt(summary.totalOrders),
        color: Colors.indigo,
      ),
      _KpiTile(
        icon: Icons.attach_money_rounded,
        label: 'Ingresos hoy',
        value: _money(summary.revenueToday),
        color: Palette.green,
      ),
      _KpiTile(
        icon: Icons.calendar_month_rounded,
        label: 'Ingresos mes',
        value: _money(summary.revenueMonth),
        color: Colors.purple,
      ),
      _KpiTile(
        icon: Icons.pending_actions_rounded,
        label: 'Pendientes',
        value: _fmt(summary.ordersPending),
        color: Palette.orange,
      ),
      _KpiTile(
        icon: Icons.inventory_2_rounded,
        label: 'Stock bajo',
        value: _fmt(summary.lowStockCount),
        color: Palette.red,
      ),
      _KpiTile(
        icon: Icons.star_rate_rounded,
        label: 'Top Producto',
        value: summary.topProducts.isNotEmpty
            ? summary.topProducts.first.name
            : '—',
        color: Colors.amber.shade800,
        small: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final crossCount = c.maxWidth >= 1200
            ? 4
            : c.maxWidth >= 720
            ? 3
            : 2;
        return GridView.builder(
          itemCount: tiles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (_, i) => tiles[i],
        );
      },
    );
  }

  static String _fmt(num? n) => (n ?? 0).toStringAsFixed(0);
  static String _money(num? n) =>
      'Bs ${((n ?? 0).toDouble()).toStringAsFixed(2)}';
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool small;

  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: small ? 16 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List<RecentOrder> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Órdenes recientes',
      icon: Icons.receipt_long_rounded,
      child: orders.isEmpty
          ? const _EmptyState(text: 'Sin órdenes recientes.')
          : Column(
              children: orders
                  .map(
                    (o) => _TwoLineTile(
                      leading: Icons.shopping_cart_checkout_rounded,
                      title:
                          '#${o.code ?? o.id?.toString() ?? '—'} • ${o.customer ?? 'Cliente'}',
                      subtitle:
                          '${o.items} ítems · Bs ${o.total.toStringAsFixed(2)} · ${o.status}',
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<TopProduct> items;
  const _TopProductsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top productos',
      icon: Icons.trending_up_rounded,
      child: items.isEmpty
          ? const _EmptyState(text: 'Aún no hay productos destacados.')
          : Column(
              children: items
                  .map(
                    (p) => _TwoLineTile(
                      leading: Icons.star,
                      title: p.name,
                      subtitle:
                          '${p.sold} vendidos · Bs ${p.revenue.toStringAsFixed(2)}',
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<LowStockItem> items;
  const _LowStockCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Stock bajo',
      icon: Icons.inventory_2_rounded,
      child: items.isEmpty
          ? const _EmptyState(text: 'Sin alertas de stock bajo.')
          : Column(
              children: items
                  .map(
                    (i) => _TwoLineTile(
                      leading: Icons.warning_amber_rounded,
                      title: i.name,
                      subtitle: 'Stock: ${i.stock} · Mínimo: ${i.minStock}',
                      color: Palette.red,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Palette.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TwoLineTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final Color? color;
  const _TwoLineTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(leading, color: color ?? Palette.slate),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}

/* ===========================
 *  Modelo + Servicio
 * =========================== */
class AdminSummary {
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final int ordersPending;
  final int lowStockCount;
  final double revenueToday;
  final double revenueMonth;
  final List<RecentOrder> recentOrders;
  final List<TopProduct> topProducts;
  final List<LowStockItem> lowStockItems;

  const AdminSummary({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.ordersPending,
    required this.lowStockCount,
    required this.revenueToday,
    required this.revenueMonth,
    required this.recentOrders,
    required this.topProducts,
    required this.lowStockItems,
  });

  factory AdminSummary.empty() => const AdminSummary(
    totalUsers: 0,
    totalProducts: 0,
    totalOrders: 0,
    ordersPending: 0,
    lowStockCount: 0,
    revenueToday: 0,
    revenueMonth: 0,
    recentOrders: [],
    topProducts: [],
    lowStockItems: [],
  );
}

class RecentOrder {
  final int? id;
  final String? code;
  final String? customer;
  final int items;
  final double total;
  final String status;
  RecentOrder({
    this.id,
    this.code,
    this.customer,
    required this.items,
    required this.total,
    required this.status,
  });
}

class TopProduct {
  final String name;
  final int sold;
  final double revenue;
  TopProduct({required this.name, required this.sold, required this.revenue});
}

class LowStockItem {
  final String name;
  final int stock;
  final int minStock;
  LowStockItem({
    required this.name,
    required this.stock,
    required this.minStock,
  });
}

class AdminStatsService {
  final String baseUrl;
  AdminStatsService({required this.baseUrl});

  Future<AdminSummary> fetchSummary() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/summary'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return _fromJsonFlexible(json);
      }
      return _fallbackCalls();
    } catch (e) {
      debugPrint('⚠️ summary endpoint falló, usando fallback: $e');
      return _fallbackCalls();
    }
  }

  Future<AdminSummary> _fallbackCalls() async {
    try {
      final usersF = http.get(Uri.parse('$baseUrl/admin/users/count'));
      final prodsF = http.get(Uri.parse('$baseUrl/admin/products/count'));
      final ordersF = http.get(Uri.parse('$baseUrl/admin/orders/count'));
      final pendF = http.get(Uri.parse('$baseUrl/admin/orders/pending'));
      final lowCntF = http.get(Uri.parse('$baseUrl/admin/stock/low/count'));
      final revTodayF = http.get(Uri.parse('$baseUrl/admin/revenue/today'));
      final revMonthF = http.get(Uri.parse('$baseUrl/admin/revenue/month'));
      final recentF = http.get(Uri.parse('$baseUrl/admin/orders/recent'));
      final topF = http.get(Uri.parse('$baseUrl/admin/products/top'));
      final lowF = http.get(Uri.parse('$baseUrl/admin/stock/low'));

      final res = await Future.wait([
        usersF,
        prodsF,
        ordersF,
        pendF,
        lowCntF,
        revTodayF,
        revMonthF,
        recentF,
        topF,
        lowF,
      ]);

      int _count(http.Response r) {
        if (r.statusCode != 200) return 0;
        final j = jsonDecode(r.body);
        return (j['count'] ?? j['total'] ?? 0) as int;
      }

      double _amount(http.Response r) {
        if (r.statusCode != 200) return 0.0;
        final j = jsonDecode(r.body);
        final a = (j['amount'] ?? j['total'] ?? j['revenue'] ?? 0);
        return (a is num) ? a.toDouble() : 0.0;
      }

      List<RecentOrder> _recent(http.Response r) {
        if (r.statusCode != 200) return [];
        final list = jsonDecode(r.body);
        if (list is! List) return [];
        return list.map<RecentOrder>((e) {
          return RecentOrder(
            id: e['id'] as int?,
            code: e['code']?.toString(),
            customer: e['customer']?.toString() ?? e['client']?.toString(),
            items: (e['items'] ?? e['qty'] ?? 0) as int,
            total: ((e['total'] ?? 0) as num).toDouble(),
            status: e['status']?.toString() ?? '—',
          );
        }).toList();
      }

      List<TopProduct> _top(http.Response r) {
        if (r.statusCode != 200) return [];
        final list = jsonDecode(r.body);
        if (list is! List) return [];
        return list.map<TopProduct>((e) {
          return TopProduct(
            name: e['name']?.toString() ?? '—',
            sold: (e['sold'] ?? e['cantidad'] ?? 0) as int,
            revenue: ((e['revenue'] ?? e['ingreso'] ?? 0) as num).toDouble(),
          );
        }).toList();
      }

      List<LowStockItem> _low(http.Response r) {
        if (r.statusCode != 200) return [];
        final list = jsonDecode(r.body);
        if (list is! List) return [];
        return list.map<LowStockItem>((e) {
          return LowStockItem(
            name: e['name']?.toString() ?? e['product']?.toString() ?? '—',
            stock: (e['stock'] ?? 0) as int,
            minStock: (e['min_stock'] ?? e['minStock'] ?? 0) as int,
          );
        }).toList();
      }

      return AdminSummary(
        totalUsers: _count(res[0]),
        totalProducts: _count(res[1]),
        totalOrders: _count(res[2]),
        ordersPending: _count(res[3]),
        lowStockCount: _count(res[4]),
        revenueToday: _amount(res[5]),
        revenueMonth: _amount(res[6]),
        recentOrders: _recent(res[7]),
        topProducts: _top(res[8]),
        lowStockItems: _low(res[9]),
      );
    } catch (e) {
      debugPrint('⚠️ fallback también falló, usando MOCK: $e');
      return _mock();
    }
  }

  AdminSummary _fromJsonFlexible(dynamic json) {
    final j = (json is Map && json['data'] is Map) ? json['data'] : json;

    int _i(String a, [String? b, String? c]) {
      final v =
          j[a] ?? (b != null ? j[b] : null) ?? (c != null ? j[c] : null) ?? 0;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    double _d(String a, [String? b, String? c]) {
      final v =
          j[a] ?? (b != null ? j[b] : null) ?? (c != null ? j[c] : null) ?? 0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    List<RecentOrder> recent = [];
    if (j['recentOrders'] is List) {
      recent = (j['recentOrders'] as List).map<RecentOrder>((e) {
        return RecentOrder(
          id: e['id'] as int?,
          code: e['code']?.toString(),
          customer: e['customer']?.toString(),
          items: (e['items'] ?? 0) as int,
          total: ((e['total'] ?? 0) as num).toDouble(),
          status: e['status']?.toString() ?? '—',
        );
      }).toList();
    }

    List<TopProduct> top = [];
    if (j['topProducts'] is List) {
      top = (j['topProducts'] as List).map<TopProduct>((e) {
        return TopProduct(
          name: e['name']?.toString() ?? '—',
          sold: (e['sold'] ?? 0) as int,
          revenue: ((e['revenue'] ?? 0) as num).toDouble(),
        );
      }).toList();
    }

    List<LowStockItem> low = [];
    if (j['lowStock'] is List) {
      low = (j['lowStock'] as List).map<LowStockItem>((e) {
        return LowStockItem(
          name: e['name']?.toString() ?? '—',
          stock: (e['stock'] ?? 0) as int,
          minStock: (e['minStock'] ?? e['min_stock'] ?? 0) as int,
        );
      }).toList();
    }

    return AdminSummary(
      totalUsers: _i('totalUsers', 'users'),
      totalProducts: _i('totalProducts', 'products'),
      totalOrders: _i('totalOrders', 'orders'),
      ordersPending: _i('ordersPending', 'pending'),
      lowStockCount: _i('lowStockCount', 'lowStock'),
      revenueToday: _d('revenueToday', 'todayRevenue'),
      revenueMonth: _d('revenueMonth', 'monthRevenue'),
      recentOrders: recent,
      topProducts: top,
      lowStockItems: low,
    );
  }

  AdminSummary _mock() {
    return AdminSummary(
      totalUsers: 128,
      totalProducts: 342,
      totalOrders: 57,
      ordersPending: 9,
      lowStockCount: 5,
      revenueToday: 1240.50,
      revenueMonth: 18350.75,
      recentOrders: [
        RecentOrder(
          id: 1012,
          code: 'QMS-1012',
          customer: 'Juan Pérez',
          items: 4,
          total: 220.90,
          status: 'Paid',
        ),
        RecentOrder(
          id: 1011,
          code: 'QMS-1011',
          customer: 'María Gómez',
          items: 2,
          total: 95.00,
          status: 'Pending',
        ),
      ],
      topProducts: [
        TopProduct(name: 'Desengrasante X', sold: 84, revenue: 2450),
        TopProduct(name: 'Detergente Y', sold: 65, revenue: 1800),
        TopProduct(name: 'Ambientador Z', sold: 41, revenue: 980),
      ],
      lowStockItems: [
        LowStockItem(name: 'Cloro 5L', stock: 8, minStock: 15),
        LowStockItem(name: 'Guantes Nitrilo M', stock: 12, minStock: 25),
      ],
    );
  }
}

/* ===========================
 *  Servicio IA + Fallback local
 * =========================== */

class AiDashboardService {
  final String baseUrl;
  AiDashboardService({required this.baseUrl});

  Future<AiReport> generateExecutiveReport(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/report');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return AiReport.fromJson(j);
    }
    throw Exception('IA report failed (${res.statusCode})');
  }

  Future<AiIrregularities> analyzeIrregularities(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/irregularities');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return AiIrregularities.fromJson(j);
    }
    throw Exception('IA irregularities failed (${res.statusCode})');
  }

  Future<String> ask(String question, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/qa');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'context': payload}),
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return (j['answer'] ?? '').toString();
    }
    throw Exception('IA Q&A failed (${res.statusCode})');
  }
}

class AiReport {
  final String summary;
  final List<String> highlights;
  AiReport({required this.summary, required this.highlights});
  factory AiReport.fromJson(Map j) => AiReport(
    summary: (j['summary'] ?? '').toString(),
    highlights: (j['highlights'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

class AiIrregularities {
  final List<String> issues;
  final Map<String, dynamic> fixes;
  AiIrregularities({required this.issues, required this.fixes});
  factory AiIrregularities.fromJson(Map j) => AiIrregularities(
    issues: (j['issues'] as List? ?? []).map((e) => e.toString()).toList(),
    fixes: ((j['fixes'] as Map? ?? const {}) as Map).cast<String, dynamic>(),
  );
}

/// Reglas locales por si el backend no responde (detección rápida + mini reporte)
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

    if (users < 0 || prods < 0 || orders < 0) {
      issues.add('Valores negativos en contadores.');
    }
    if (revToday < 0 || revMonth < 0) {
      issues.add('Ingresos negativos.');
    }
    if (pending > orders) {
      issues.add('Pendientes mayor que total de órdenes.');
    }
    if (revMonth < revToday) {
      issues.add('Ingresos del mes menores que los del día.');
    }
    if (orders == 0 && revToday > 0) {
      issues.add('Ingresos positivos sin órdenes registradas hoy.');
    }
    if (prods > 0 && lowStock > prods * 0.5) {
      issues.add('Más del 50% del catálogo en stock bajo.');
    }

    return {
      'issues': issues,
      'fixes': {
        'recheckEndpoints': ['orders/count', 'revenue/today', 'revenue/month'],
        'consistencyQueries': ['SELECT ... COUNT(*)', 'SELECT ... SUM(total)'],
      },
    };
  }

  static String report(Map<String, dynamic> d) {
    String money(num? n) => 'Bs ${((n ?? 0).toDouble()).toStringAsFixed(2)}';
    return 'Resumen del día:\n'
        '- Usuarios: ${d['totalUsers']}\n'
        '- Productos: ${d['totalProducts']}\n'
        '- Órdenes: ${d['totalOrders']} (Pendientes: ${d['ordersPending']})\n'
        '- Ingresos hoy: ${money(d['revenueToday'])}\n'
        '- Ingresos mes: ${money(d['revenueMonth'])}\n';
  }
}
