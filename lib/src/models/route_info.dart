import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final String distance;
  final String duration;
  final List<LatLng> polylineCoordinates;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylineCoordinates,
  });
}
