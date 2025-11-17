// lib/features/admin/pedidos/page/ciclos_entrega_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/theme/palette.dart';

class CiclosEntregaPage extends StatefulWidget {
  const CiclosEntregaPage({super.key});

  @override
  State<CiclosEntregaPage> createState() => _CiclosEntregaPageState();
}

class _CiclosEntregaPageState extends State<CiclosEntregaPage> {
  bool _loading = true;
  bool _error = false;
  String _errorMessage = '';

  // año visible
  int _anio = DateTime.now().year;

  // lista cruda desde la API
  List<Map<String, dynamic>> _ciclos = [];

  // selección de fecha por mes (1..12)
  final Map<int, DateTime> _selectedByMes = {};

  String get _baseUrl => Env.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _cargarCiclos();
  }

  Future<void> _cargarCiclos() async {
    try {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = '';
      });

      final uri = Uri.parse('$_baseUrl/ciclos-entrega?anio=$_anio');
      final resp = await http.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode}: ${resp.body}');
      }

      final data = jsonDecode(resp.body);
      if (data is! List) {
        throw Exception('Respuesta inválida de la API');
      }

      _ciclos = data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _selectedByMes.clear();
      for (final ciclo in _ciclos) {
        final mes = int.tryParse(ciclo['mes']?.toString() ?? '') ?? 0;
        final rawFecha = ciclo['fecha_entrega']?.toString();
        if (mes >= 1 && mes <= 12) {
          if (rawFecha != null && rawFecha.isNotEmpty) {
            _selectedByMes[mes] = DateTime.parse(rawFecha);
          } else {
            _selectedByMes[mes] = DateTime(_anio, mes, 15);
          }
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  // buscar ciclo por mes
  Map<String, dynamic>? _cicloPorMes(int mes) {
    try {
      return _ciclos.firstWhere(
        (c) => int.tryParse(c['mes']?.toString() ?? '') == mes,
        orElse: () => {},
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _actualizarCiclo(int mes) async {
    final ciclo = _cicloPorMes(mes);
    final fecha = _selectedByMes[mes];

    if (ciclo == null || ciclo.isEmpty || fecha == null) return;

    final idciclo = ciclo['idciclo']?.toString();
    if (idciclo == null) return;

    final fechaStr =
        '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    try {
      final uri = Uri.parse('$_baseUrl/ciclos-entrega/$idciclo');
      final resp = await http.put(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'fecha_entrega': fechaStr}),
      );

      if (!mounted) return;

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar ciclo de ${_nombreMes(mes)}: ${resp.statusCode}',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ciclo de ${_nombreMes(mes)} actualizado a $fechaStr ✅',
          ),
        ),
      );

      await _cargarCiclos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar ciclo: $e')));
    }
  }

  String _nombreMes(int mes) {
    const nombres = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (mes < 1 || mes > 12) return 'Mes $mes';
    return nombres[mes];
  }

  int _ultimoDiaMes(int anio, int mes) {
    final inicioMesSiguiente = (mes == 12)
        ? DateTime(anio + 1, 1, 1)
        : DateTime(anio, mes + 1, 1);
    return inicioMesSiguiente.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ciclos de entrega',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Palette.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configura el día de entrega de pedidos para cada mes del año.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Año anterior',
                                onPressed: () {
                                  setState(() {
                                    _anio--;
                                  });
                                  _cargarCiclos();
                                },
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                '$_anio',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Año siguiente',
                                onPressed: () {
                                  setState(() {
                                    _anio++;
                                  });
                                  _cargarCiclos();
                                },
                                icon: const Icon(Icons.chevron_right),
                              ),
                              IconButton(
                                tooltip: 'Recargar',
                                onPressed: _cargarCiclos,
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error)
                        _buildError()
                      else
                        _buildGridCalendarios(maxWidth),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ocurrió un error al cargar los ciclos.\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _cargarCiclos,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: Palette.primary),
        ),
      ],
    );
  }

  /// Grid responsive para web
  Widget _buildGridCalendarios(double maxWidth) {
    int crossAxisCount;
    if (maxWidth >= 1300) {
      crossAxisCount = 4;
    } else if (maxWidth >= 1000) {
      crossAxisCount = 3;
    } else if (maxWidth >= 700) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    // 👉 bajamos un poco el aspectRatio cuando hay más columnas
    double childAspectRatio;
    if (crossAxisCount >= 4) {
      childAspectRatio = 0.9; // más alto
    } else if (crossAxisCount == 3) {
      childAspectRatio = 1.0;
    } else if (crossAxisCount == 2) {
      childAspectRatio = 1.2;
    } else {
      childAspectRatio = 1.4;
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: 12,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final mes = index + 1;
        final ciclo = _cicloPorMes(mes);
        final selected = _selectedByMes[mes] ?? DateTime(_anio, mes, 15);
        final lastDay = _ultimoDiaMes(_anio, mes);

        return Container(
          decoration: BoxDecoration(
            color: Palette.fieldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // header mes
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Palette.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_nombreMes(mes)} $_anio',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // calendario (compacto)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: TableCalendar(
                      locale: 'es',
                      firstDay: DateTime(_anio, mes, 1),
                      lastDay: DateTime(_anio, mes, lastDay),
                      focusedDay: selected,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mes',
                      },
                      availableGestures: AvailableGestures.none,
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                        titleTextStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        headerPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        weekendStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        dowTextFormatter: (date, _) {
                          const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                          return labels[(date.weekday + 6) % 7];
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        cellMargin: EdgeInsets.zero,
                        cellPadding: EdgeInsets.zero,
                        rowDecoration: const BoxDecoration(),
                        selectedDecoration: BoxDecoration(
                          color: Palette.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Palette.primary,
                            width: 1.4,
                          ),
                        ),
                        todayTextStyle: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                        defaultTextStyle: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                        ),
                      ),
                      // 👇 un poco más pequeño
                      rowHeight: 24,
                      daysOfWeekHeight: 18,
                      selectedDayPredicate: (day) =>
                          day.year == selected.year &&
                          day.month == selected.month &&
                          day.day == selected.day,
                      onDaySelected: (day, focusedDay) {
                        setState(() {
                          _selectedByMes[mes] = day;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Text(
                'Fecha seleccionada: '
                '${selected.day.toString().padLeft(2, '0')}/'
                '${selected.month.toString().padLeft(2, '0')}/'
                '${selected.year}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: ciclo == null || ciclo.isEmpty
                      ? null
                      : () => _actualizarCiclo(mes),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
