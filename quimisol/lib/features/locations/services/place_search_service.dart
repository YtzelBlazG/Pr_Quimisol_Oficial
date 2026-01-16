import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quimisol/features/locations/models/place_suggestions.dart';

class PlaceSearchService {
  final String mapboxToken;
  PlaceSearchService({required this.mapboxToken});

  Future<List<PlaceSuggestion>> search(String query,
      {String proximity = '-66.1568,-17.3895' /* Cochabamba aprox */}) async {
    if (query.trim().isEmpty) return [];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?access_token=$mapboxToken&autocomplete=true&language=es&limit=6&proximity=$proximity';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = (data['features'] as List?) ?? [];
    return features
        .map((e) => PlaceSuggestion.fromMapbox(e as Map<String, dynamic>))
        .toList();
  }
}
