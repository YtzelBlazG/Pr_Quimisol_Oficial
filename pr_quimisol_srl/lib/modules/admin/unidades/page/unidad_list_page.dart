import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../controllers/unidad_controller.dart';
import '../../../../models/unidad_model.dart';

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
    controlador.cargarUnidades().then((_) {
      setState(() {
        filtradas = controlador.unidades;
      });
    });

    _buscadorCtrl.addListener(() {
      final texto = _buscadorCtrl.text.toLowerCase();
      setState(() {
        filtradas = controlador.unidades
            .where((u) => u.nombre.toLowerCase().contains(texto))
            .toList();
      });
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
              setState(() {
                filtradas = controlador.unidades;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unidades")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Nueva unidad"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Modular.to.pushNamed('/unidades/crear');
          await controlador.cargarUnidades();
          setState(() {
            filtradas = controlador.unidades;
          });
        },
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 800,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lista de unidades",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 20),
                  Expanded(
                    child: filtradas.isEmpty
                        ? const Center(child: Text('No hay unidades para mostrar.'))
                        : Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(4),
                              2: FlexColumnWidth(2),
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.grey.shade300),
                            ),
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(color: Color(0xFFEAE6F1)),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              ...filtradas.map((unidad) {
                                return TableRow(
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
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () async {
                                              await Modular.to.pushNamed('/unidades/editar', arguments: unidad);
                                              await controlador.cargarUnidades();
                                              setState(() {
                                                filtradas = controlador.unidades;
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmarEliminar(context, unidad),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList()
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
