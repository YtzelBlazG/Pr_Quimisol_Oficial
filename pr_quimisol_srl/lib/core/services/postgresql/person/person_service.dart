import 'dart:convert';
import 'package:http/http.dart' as http;
import 'person_model.dart';

class PersonService {
  final String baseUrl;
  PersonService({required this.baseUrl});

  Future<Person?> getPerson(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/personas/$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Person.fromJson(data);
    } else {
      throw Exception('Error fetching person: ${response.body}');
    }
  }

  Future<void> updatePerson({
    required int id,
    required String name,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/personas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nombre': name, 'telefono': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error updating person: ${response.body}');
    }
  }
}
