import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol/core/config/env.dart';
import 'package:quimisol/core/storage/auth_storage.dart';
import 'package:quimisol/core/services/postgresql/locations/locations_service.dart';

class LocationsListPage extends StatefulWidget {
  const LocationsListPage({super.key});

  @override
  State<LocationsListPage> createState() => _LocationsListPageState();
}

class _LocationsListPageState extends State<LocationsListPage> {
  late final LocationsService _svc;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int? _idPersona;

  @override
  void initState() {
    super.initState();
    _svc = LocationsService(baseUrl: Env.apiBaseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _idPersona = await AuthStorage.getIdPersona();
    if (_idPersona != null) {
      _items = await _svc.listByPersona(_idPersona!);
    }
    setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    await _svc.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ubicaciones'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aún no tienes ubicaciones.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.place)),
                        title: Text(it['nombre'] ?? ''),
                        subtitle: Text(
                          (it['direccion'] ?? '') as String,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(it['idubicacion'] as int),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Agregar'),
        onPressed: () => Modular.to.pushNamed('/locations/add')
            .then((_) => _load()),
      ),
    );
  }
}
