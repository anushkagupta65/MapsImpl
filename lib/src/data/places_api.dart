// lib/api/places_api.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:map_assessment/src/utils/app_constants.dart';

class PlacesApi {
  Future<LatLng?> getLatLngFromPlaceId(String identifier) async {
    // Check if it's likely a place_id (usually long, alphanumeric with hyphens)
    // or a raw address. This is a heuristic, better to rely on actual selection.
    bool isPlaceId = identifier.length > 15 && identifier.contains('-');

    String url;
    if (isPlaceId) {
      url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$identifier&key=${AppConstants.googleApiKey}';
    } else {
      // Use Geocoding API for raw address
      url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$identifier&key=${AppConstants.googleApiKey}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    // Return null if not found or error, let the caller handle it.
    return null;
  }
}
