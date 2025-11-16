// lib/presentation/screens/map_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_assessment/src/models/route_info.dart';
import 'package:map_assessment/src/presentation/screens/route_search_screen.dart';
import 'package:map_assessment/src/services/location_service.dart';
import 'package:map_assessment/src/services/map_service.dart';
import 'package:map_assessment/src/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();

  LatLng? _currentLocation;
  RouteInfo? _currentRouteInfo;
  String? _currentSourceAddress;
  String? _currentDestinationAddress;
  LatLng? _currentSourceLatLng;
  LatLng? _currentDestinationLatLng;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // NEW: control the visibility of the stacked sheet
  bool _showRouteSheet = false;

  @override
  void initState() {
    super.initState();
    print("[MapScreen] Initializing MapScreen...");
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      _currentLocation = await _locationService.getCurrentLocation();
      print("[MapScreen] Current location obtained: $_currentLocation");
      _moveToLocation(_currentLocation!, AppConstants.currentLocationZoom);
    } catch (e) {
      print("[MapScreen] Error getting current location: $e");
      _showSnackBar("Failed to get current location: ${e.toString()}");
      _moveToDefaultLocation();
    }
  }

  Future<void> _moveToLocation(LatLng location, double zoom) async {
    final GoogleMapController controller = await _controller.future;
    print("[MapScreen] Moving camera to $location with zoom $zoom");
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom),
      ),
    );
  }

  void _moveToDefaultLocation() {
    print("[MapScreen] Moving to default location.");
    _moveToLocation(
      AppConstants.defaultIndiaLocation,
      AppConstants.defaultZoom,
    );
  }

  void _onMapTap(LatLng position) {
    print("[MapScreen] Map tapped at $position");
    if (_currentRouteInfo == null) {
      Provider.of<MapService>(context, listen: false).addMarker(
        Marker(
          markerId: MarkerId(const Uuid().v4()),
          position: position,
          infoWindow: const InfoWindow(title: "Dropped Pin"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
      _showSnackBar(
        "Dropped pin at ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}",
      );
    } else {
      _showSnackBar("Clear current route to drop new pins.");
    }
  }

  Future<void> _handleRouteCalculated(
    RouteInfo routeInfo,
    String sourceAddress,
    String destinationAddress,
    LatLng sourceLatLng,
    LatLng destinationLatLng,
  ) async {
    print("[MapScreen] _handleRouteCalculated called.");
    setState(() {
      _currentRouteInfo = routeInfo;
      _currentSourceAddress = sourceAddress;
      _currentDestinationAddress = destinationAddress;
      _currentSourceLatLng = sourceLatLng;
      _currentDestinationLatLng = destinationLatLng;
      _showRouteSheet = true; // <-- show stacked sheet
    });

    final mapService = Provider.of<MapService>(context, listen: false);
    mapService.clearAll();
    print("[MapScreen] Cleared existing markers and polylines.");

    mapService.addMarker(
      Marker(
        markerId: const MarkerId("origin"),
        position: sourceLatLng,
        infoWindow: InfoWindow(title: sourceAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    mapService.addMarker(
      Marker(
        markerId: const MarkerId("destination"),
        position: destinationLatLng,
        infoWindow: InfoWindow(title: destinationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    print("[MapScreen] Added origin and destination markers.");

    mapService.addPolyline(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: routeInfo.polylineCoordinates,
      ),
    );
    print(
      "[MapScreen] Added polyline with ${routeInfo.polylineCoordinates.length} points.",
    );

    await _zoomToFitRoute(sourceLatLng, destinationLatLng);
    print("[MapScreen] Zoomed to fit route.");

    // Close the search screen (if it is still on the stack)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handlePlaceSelectedAndMoveMap(LatLng latLng, String? placeName) {
    print(
      "[MapScreen] _handlePlaceSelectedAndMoveMap called for $placeName at $latLng",
    );
    _moveToLocation(latLng, AppConstants.selectedPlaceZoom);
    final mapService = Provider.of<MapService>(context, listen: false);
    mapService.addMarker(
      Marker(
        markerId: MarkerId(const Uuid().v4()),
        position: latLng,
        infoWindow: InfoWindow(title: placeName ?? "Selected Place"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  Future<void> _zoomToFitRoute(LatLng origin, LatLng destination) async {
    final GoogleMapController controller = await _controller.future;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _clearMapAndRouteInfo() {
    print("[MapScreen] Clearing map and route info.");
    setState(() {
      _currentRouteInfo = null;
      _currentSourceAddress = null;
      _currentDestinationAddress = null;
      _currentSourceLatLng = null;
      _currentDestinationLatLng = null;
      _showRouteSheet = false; // <-- hide stacked sheet
    });
    Provider.of<MapService>(context, listen: false).clearAll();

    _showSnackBar("Map and route cleared.");
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ... [All previous imports and code remain unchanged until build()]

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          title: _CustomSearchAppBar(
            onTap: () {
              print(
                "[MapScreen] Search bar tapped, navigating to RouteSearchScreen.",
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RouteSearchScreen(
                        onRouteCalculated: _handleRouteCalculated,
                        onPlaceSelectedAndMoveMap:
                            _handlePlaceSelectedAndMoveMap,
                        initialSourceAddress: _currentSourceAddress,
                        initialDestinationAddress: _currentDestinationAddress,
                        initialSourceLatLng: _currentSourceLatLng,
                        initialDestinationLatLng: _currentDestinationLatLng,
                      ),
                ),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            // ---- Google Map -------------------------------------------------
            Consumer<MapService>(
              builder: (context, mapService, child) {
                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: AppConstants.defaultIndiaLocation,
                    zoom: AppConstants.defaultZoom,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  markers: mapService.markers,
                  polylines: mapService.polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    print("[MapScreen] GoogleMap controller completed.");
                  },
                  onTap: _onMapTap,
                  padding: EdgeInsets.only(
                    top: AppBar().preferredSize.height + 10,
                  ),
                );
              },
            ),

            // ---- Stacked Draggable Bottom Sheet -------------------------------
            if (_showRouteSheet && _currentRouteInfo != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: screenHeight, // Critical: give bounded height
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.2,
                    minChildSize: 0.2,
                    maxChildSize: 0.95,
                    expand: false,
                    snap: true,
                    snapSizes: const [0.2, 0.5, 0.95],
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drag handle
                              Container(
                                height: 4,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Metrics Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetricItem(
                                    Icons.alt_route,
                                    _currentRouteInfo!.distance,
                                    "Distance",
                                  ),
                                  _buildMetricItem(
                                    Icons.timer,
                                    _currentRouteInfo!.duration,
                                    "Duration",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Start Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showSnackBar(
                                      "Starting navigation to ${_currentDestinationAddress ?? "destination"}!",
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Start",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Clear Route Button
                              TextButton(
                                onPressed: _clearMapAndRouteInfo,
                                child: const Text(
                                  "Clear Route",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),

                              // Extra space for scroll
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "myLocation",
              onPressed: () {
                print("[MapScreen] My Location FAB pressed.");
                if (_currentLocation != null) {
                  _moveToLocation(
                    _currentLocation!,
                    AppConstants.currentLocationZoom,
                  );
                } else {
                  _showSnackBar(
                    "Current location not available. Please enable permissions.",
                  );
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Colors.black,
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "directions",
              onPressed: () {
                print(
                  "[MapScreen] Directions FAB pressed, navigating to RouteSearchScreen.",
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RouteSearchScreen(
                          onRouteCalculated: _handleRouteCalculated,
                          onPlaceSelectedAndMoveMap:
                              _handlePlaceSelectedAndMoveMap,
                          initialSourceAddress: _currentSourceAddress,
                          initialDestinationAddress: _currentDestinationAddress,
                          initialSourceLatLng: _currentSourceLatLng,
                          initialDestinationLatLng: _currentDestinationLatLng,
                        ),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.directions),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build metric items (moved here to avoid external widget dependency)
  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Custom Search AppBar Widget (unchanged)
class _CustomSearchAppBar extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomSearchAppBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Search here",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const Icon(Icons.mic, color: Colors.blue),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
