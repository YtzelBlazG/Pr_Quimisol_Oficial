import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String mapboxToken;
  GeocodingService({required this.mapboxToken});

  Future<Map<String, String>> reverse(double lat, double lng) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
        '?access_token=$mapboxToken&language=es&limit=1';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      return {'direccion': '', 'ciudad': ''};
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final feat = (json['features'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (feat.isEmpty) return {'direccion': '', 'ciudad': ''};

    final f = feat.first;
    final direccion = (f['place_name'] ?? '') as String;

    String ciudad = '';
    final ctx = (f['context'] as List?) ?? [];
    for (final c in ctx) {
      final id = (c['id'] ?? '') as String;
      if (id.startsWith('place.')) {
        ciudad = (c['text'] ?? '') as String;
        break;
      }
    }
    return {'direccion': direccion, 'ciudad': ciudad};
  }
}
