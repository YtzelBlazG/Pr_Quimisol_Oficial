class PlaceSuggestion {
  PlaceSuggestion({
    required this.id,
    required this.provider, // 'mapbox' | 'nominatim'
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String provider;
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;

  double score = 0; // menor = mejor (para ranking)
}
