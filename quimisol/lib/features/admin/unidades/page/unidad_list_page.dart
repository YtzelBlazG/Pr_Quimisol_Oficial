import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/features/admin/unidades/data/models/unidad_model.dart';
import '../controllers/unidad_controller.dart';

class UnidadListPage extends StatefulWidget {
  const UnidadListPage({super.key});

  @override
  State<UnidadListPage> createState() => _UnidadListPageState();
}

class _UnidadListPageState extends State<UnidadListPage> {
  final UnidadController controlador = Modular.get<UnidadController>();
  final TextEditingController _buscadorCtrl = TextEditingController();
  List<Unit> filtradas = [];

  @override
  void initState() {
    super.initState();
    _cargarYFiltrar();
    _buscadorCtrl.addListener(_filtrarResultados);
  }

  Future<void> _cargarYFiltrar() async {
    await controlador.cargarUnidades();
    setState(() {
      filtradas = controlador.unidades;
    });
  }

  void _filtrarResultados() {
    final texto = _buscadorCtrl.text.toLowerCase();
    setState(() {
      filtradas = controlador.unidades
          .where((u) => u.nombre.toLowerCase().contains(texto))
          .toList();
    });
  }

  void _confirmarEliminar(BuildContext context, Unit unidad) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Seguro que deseas eliminar "${unidad.nombre}"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await controlador.borrarUnidad(unidad.id);
              await _cargarYFiltrar();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unidades"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 👉 Botón crear nueva unidad
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Nueva unidad"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await Modular.to.pushNamed('/admin/unidades/create');
                      await _cargarYFiltrar();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                /// 👉 Buscador
                TextField(
                  controller: _buscadorCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                /// 👉 Tabla de unidades
                filtradas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No hay unidades para mostrar.'),
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(4),
                              2: FlexColumnWidth(2),
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.grey.shade300),
                            ),
                            children: [
                              /// Encabezados
                              const TableRow(
                                decoration:
                                    BoxDecoration(color: Color(0xFFEAE6F1)),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Nombre',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Descripción',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Acciones',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              /// Filas
                              ...filtradas.map((unidad) {
                                return TableRow(
                                  decoration: const BoxDecoration(
                                      color: Colors.white),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(unidad.nombre),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(unidad.descripcion),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            tooltip: "Editar",
                                            onPressed: () async {
                                              await Modular.to.pushNamed(
                                                '/admin/unidades/edit',
                                                arguments: unidad,
                                              );
                                              await _cargarYFiltrar();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            tooltip: "Eliminar",
                                            onPressed: () => _confirmarEliminar(
                                                context, unidad),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
