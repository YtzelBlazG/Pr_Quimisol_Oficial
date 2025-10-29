import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  GeocodingService({required this.mapboxToken});

  final String mapboxToken;

  Future<Map<String, String>> reverseGeocodeMapbox({
    required double lat,
    required double lng,
  }) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
        '?access_token=$mapboxToken&language=es&limit=1';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = (json['features'] as List?) ?? [];
      if (features.isNotEmpty) {
        final f = features.first as Map<String, dynamic>;
        final fullAddress = (f['place_name'] ?? '').toString();

        String city = '';
        final ctx = (f['context'] as List?) ?? [];
        for (final c in ctx) {
          final id = (c['id'] ?? '').toString();
          if (id.startsWith('place')) {
            city = (c['text'] ?? '').toString();
            break;
          }
        }
        if (city.isEmpty) city = (f['text'] ?? '').toString();

        return {'direccion': fullAddress, 'ciudad': city};
      }
    }
    return {'direccion': '', 'ciudad': ''};
  }
}
