import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List usuarios = [];

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
  }

  Future<void> fetchUsuarios() async {
    try {
      final response =
          await http.get(Uri.parse("http://localhost:3000/usuarios")); 
      if (response.statusCode == 200) {
        setState(() {
          usuarios = json.decode(response.body);
        });
      } else {
        print("Error en la API: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al conectar con la API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: usuarios.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final user = usuarios[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user['id_usuario'].toString())),
                  title: Text(user['correo']),
                  subtitle: Text(user['estado']),
                );
              },
            ),
    );
  }
}
