import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:quimisol/features/locations/models/place_suggestions.dart';
import '../utils/geo_utils.dart';

class PlaceSearchService {
  PlaceSearchService({required this.mapboxToken});

  final String mapboxToken;

  // cache simple en memoria
  final Map<String, List<PlaceSuggestion>> _cache = {};

  Future<List<PlaceSuggestion>> fetchCombined(
    String rawQuery,
    LatLng bias,
  ) async {
    final query = rawQuery.trim();
    if (query.length < 2) return [];

    final cacheKey = query.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final results = await Future.wait<List<PlaceSuggestion>>([
      _searchMapbox(query, bias),
      _searchNominatim(query),
    ], eagerError: false);

    final merged = _mergeRank(results.expand((e) => e).toList(), bias);
    _cache[cacheKey] = merged;
    return merged;
  }

  Future<List<PlaceSuggestion>> _searchMapbox(
      String query, LatLng bias) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?access_token=$mapboxToken'
        '&autocomplete=true'
        '&language=es'
        '&limit=7'
        '&types=place,address,poi'
        '&proximity=${bias.longitude},${bias.latitude}'
        '&country=bo';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final feats = (data['features'] as List?) ?? [];
      return feats
          .map<PlaceSuggestion>((f) {
            final m = (f as Map).cast<String, dynamic>();
            final coords = (m['geometry']?['coordinates'] as List?) ?? [];
            final lng =
                coords.length >= 2 ? (coords[0] as num).toDouble() : null;
            final lat =
                coords.length >= 2 ? (coords[1] as num).toDouble() : null;
            final title = (m['text'] ?? '').toString();
            final subtitle = (m['place_name'] ?? '').toString();
            return PlaceSuggestion(
              id: (m['id'] ?? '').toString(),
              provider: 'mapbox',
              title: title,
              subtitle: subtitle,
              lat: lat,
              lng: lng,
            );
          })
          .where((p) => p.lat != null && p.lng != null)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaceSuggestion>> _searchNominatim(String query) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=jsonv2&addressdetails=1&accept-language=es&limit=6');
    try {
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'quimisol-app/1.0 (contact: soporte@quimisol.example)'
        },
      );
      if (resp.statusCode != 200) return [];
      final list = (jsonDecode(resp.body) as List?) ?? [];
      return list.map<PlaceSuggestion>((e) {
        final m = (e as Map).cast<String, dynamic>();
        final lat = (num.tryParse((m['lat'] ?? '').toString()) ?? 0).toDouble();
        final lng = (num.tryParse((m['lon'] ?? '').toString()) ?? 0).toDouble();
        final disp = (m['display_name'] ?? '').toString();
        final addr = (m['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final city = (addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['state_district'] ??
                '')
            .toString();
        final title = city.isNotEmpty
            ? city
            : (addr['road'] ?? addr['neighbourhood'] ?? 'Lugar').toString();
        return PlaceSuggestion(
          id: (m['osm_id'] ?? '').toString(),
          provider: 'nominatim',
          title: title,
          subtitle: disp,
          lat: lat,
          lng: lng,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<PlaceSuggestion> _mergeRank(List<PlaceSuggestion> items, LatLng bias) {
    // 1) dedupe por (título+lat+lng) aprox
    final seen = <String>{};
    final deduped = <PlaceSuggestion>[];
    for (final p in items) {
      final key =
          '${p.title.toLowerCase()}|${(p.lat ?? 0).toStringAsFixed(4)},${(p.lng ?? 0).toStringAsFixed(4)}';
      if (seen.add(key)) deduped.add(p);
    }
    // 2) score por distancia + proveedor
    for (final p in deduped) {
      final d = haversine(bias.latitude, bias.longitude, p.lat!, p.lng!);
      final providerBonus = (p.provider == 'mapbox') ? -200.0 : 0.0;
      p.score = d + providerBonus; // menor = mejor
    }
    deduped.sort((a, b) => a.score.compareTo(b.score));
    return deduped;
  }
}
  