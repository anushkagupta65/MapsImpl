import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:map_assessment/src/models/route_info.dart';
import 'package:map_assessment/src/utils/app_constants.dart';

class DirectionsApi {
  final PolylinePoints _polylinePoints = PolylinePoints();

  Future<RouteInfo> getDirections(String origin, String destination) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=${AppConstants.googleApiKey}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] != "OK") {
        throw Exception('Directions API error: ${data['status']}');
      }

      String distance = data['routes'][0]['legs'][0]['distance']['text'];
      String duration = data['routes'][0]['legs'][0]['duration']['text'];
      String points = data['routes'][0]['overview_polyline']['points'];

      List<PointLatLng> result = _polylinePoints.decodePolyline(points);
      List<LatLng> polylineCoordinates =
          result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      return RouteInfo(
        distance: distance,
        duration: duration,
        polylineCoordinates: polylineCoordinates,
      );
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }
}
