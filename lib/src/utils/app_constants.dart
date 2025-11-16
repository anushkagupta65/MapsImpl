import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  static String googleApiKey = dotenv.env['API_KEY']!;
  static const LatLng defaultIndiaLocation = LatLng(20.5937, 78.9629);
  static const double defaultZoom = 10;
  static const double currentLocationZoom = 18;
  static const double selectedPlaceZoom = 16;
}
