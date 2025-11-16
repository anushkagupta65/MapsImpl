// lib/services/map_service.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService extends ChangeNotifier {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  void addMarker(Marker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void clearPolylines() {
    _polylines.clear();
    notifyListeners();
  }

  void clearAll() {
    _markers.clear();
    _polylines.clear();
    notifyListeners();
  }

  int get markerCount => _markers.length;
  int get polylineCount => _polylines.length;
}
