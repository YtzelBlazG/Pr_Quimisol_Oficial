import 'package:latlong2/latlong.dart';

extension LatLngFmt on LatLng {
  String get latStr => latitude.toStringAsFixed(6);
  String get lngStr => longitude.toStringAsFixed(6);
}
