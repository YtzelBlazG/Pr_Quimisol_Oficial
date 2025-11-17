class PlaceSuggestion {
  final String name;        // texto principal (place_name corto)
  final String placeName;   // place_name completo
  final double lat;
  final double lng;
  final String? city;

  PlaceSuggestion({
    required this.name,
    required this.placeName,
    required this.lat,
    required this.lng,
    this.city,
  });

  factory PlaceSuggestion.fromMapbox(Map<String, dynamic> f) {
    final coords = f['center'] as List?;
    final context = (f['context'] as List?) ?? [];
    String? city;

    for (final c in context) {
      final id = (c['id'] ?? '') as String;
      if (id.startsWith('place.')) {
        city = (c['text'] ?? '') as String;
        break;
      }
    }

    return PlaceSuggestion(
      name: (f['text'] ?? '') as String,
      placeName: (f['place_name'] ?? '') as String,
      lat: (coords?[1] ?? 0).toDouble(),
      lng: (coords?[0] ?? 0).toDouble(),
      city: city,
    );
  }
}
