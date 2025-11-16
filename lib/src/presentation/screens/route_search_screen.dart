// lib/presentation/screens/route_search_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:map_assessment/src/data/directions_api.dart';
import 'package:map_assessment/src/data/places_api.dart';
import 'package:map_assessment/src/models/route_info.dart';
import 'package:map_assessment/src/presentation/widgets/custom_autocomplete.dart';

class RouteSearchScreen extends StatefulWidget {
  final Function(RouteInfo, String, String, LatLng, LatLng) onRouteCalculated;
  final Function(LatLng, String?) onPlaceSelectedAndMoveMap;
  final String? initialSourceAddress;
  final String? initialDestinationAddress;
  final LatLng? initialSourceLatLng;
  final LatLng? initialDestinationLatLng;

  const RouteSearchScreen({
    super.key,
    required this.onRouteCalculated,
    required this.onPlaceSelectedAndMoveMap,
    this.initialSourceAddress,
    this.initialDestinationAddress,
    this.initialSourceLatLng,
    this.initialDestinationLatLng,
  });

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final PlacesApi _placesApi = PlacesApi();
  final DirectionsApi _directionsApi = DirectionsApi();

  LatLng? _sourceLatLng;
  LatLng? _destinationLatLng;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    print("[RouteSearchScreen] Initializing RouteSearchScreen.");
    if (widget.initialSourceAddress != null) {
      _sourceController.text = widget.initialSourceAddress!;
      _sourceLatLng = widget.initialSourceLatLng;
    }
    if (widget.initialDestinationAddress != null) {
      _destinationController.text = widget.initialDestinationAddress!;
      _destinationLatLng = widget.initialDestinationLatLng;
    }
  }

  void _onPlaceSelected(
    Prediction prediction,
    TextEditingController controller,
    bool isSource,
  ) async {
    print("[RouteSearchScreen] Place selected: ${prediction.description}");
    controller.text = prediction.description ?? '';
    final placeId = prediction.placeId;
    if (placeId != null) {
      try {
        final latLng = await _placesApi.getLatLngFromPlaceId(placeId);
        if (latLng != null) {
          if (isSource) {
            _sourceLatLng = latLng;
          } else {
            _destinationLatLng = latLng;
          }
          widget.onPlaceSelectedAndMoveMap(
            latLng,
            prediction.structuredFormatting?.mainText,
          );
          print("[RouteSearchScreen] MapScreen notified about selected place.");
        }
      } catch (e) {
        _showSnackBar(
          "Failed to get coordinates for selected place: ${e.toString()}",
        );
        print("[RouteSearchScreen] Error getting LatLng: $e");
      }
    }
  }

  Future<void> _triggerRouteCalculation() async {
    print("[RouteSearchScreen] Show Route button pressed.");
    String originAddress = _sourceController.text.trim();
    String destinationAddress = _destinationController.text.trim();

    if (originAddress.isEmpty || destinationAddress.isEmpty) {
      _showSnackBar("Please enter both starting point and destination.");
      return;
    }

    // Attempt to get LatLngs for typed addresses if not already obtained via autocomplete
    try {
      if (_sourceLatLng == null) {
        print(
          "[RouteSearchScreen] Source LatLng is null, attempting to resolve from text: $originAddress",
        );
        final LatLng? resolvedLatLng = await _placesApi.getLatLngFromPlaceId(
          originAddress,
        );
        if (resolvedLatLng == null)
          throw Exception("Could not resolve source location.");
        _sourceLatLng = resolvedLatLng;
      }
      if (_destinationLatLng == null) {
        print(
          "[RouteSearchScreen] Destination LatLng is null, attempting to resolve from text: $destinationAddress",
        );
        final LatLng? resolvedLatLng = await _placesApi.getLatLngFromPlaceId(
          destinationAddress,
        );
        if (resolvedLatLng == null)
          throw Exception("Could not resolve destination location.");
        _destinationLatLng = resolvedLatLng;
      }
    } catch (e) {
      _showSnackBar(
        "Please select valid locations from suggestions or ensure full addresses: ${e.toString()}",
      );
      print("[RouteSearchScreen] Error resolving LatLngs for typed text: $e");
      return;
    }

    if (_sourceLatLng == null || _destinationLatLng == null) {
      _showSnackBar(
        "Could not determine precise coordinates for one or both locations. Please try again.",
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });
    print("[RouteSearchScreen] Loading route...");

    try {
      final routeInfo = await _directionsApi.getDirections(
        originAddress,
        destinationAddress,
      );
      print(
        "[RouteSearchScreen] Directions API call successful. Calling onRouteCalculated.",
      );
      await widget.onRouteCalculated(
        routeInfo,
        originAddress,
        destinationAddress,
        _sourceLatLng!,
        _destinationLatLng!,
      );
      print("[RouteSearchScreen] onRouteCalculated completed. Popping screen.");
    } catch (e) {
      _showSnackBar("Failed to calculate route: ${e.toString()}");
      print("[RouteSearchScreen] Error calculating route: $e");
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
      print("[RouteSearchScreen] _isLoadingRoute set to false.");
    }
  }

  void _swapLocations() {
    print("[RouteSearchScreen] Swapping locations.");
    setState(() {
      String tempAddress = _sourceController.text;
      LatLng? tempLatLng = _sourceLatLng;

      _sourceController.text = _destinationController.text;
      _sourceLatLng = _destinationLatLng;

      _destinationController.text = tempAddress;
      _destinationLatLng = tempLatLng;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print("[RouteSearchScreen] Back button pressed.");
            Navigator.pop(context);
          },
        ),
        title: const Text("Plan Your Route"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomAutoCompleteTextField(
                  controller: _sourceController,
                  hintText: "Your location",
                  prefixIcon: const Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 14,
                  ),
                  onPlaceSelected:
                      (prediction) =>
                          _onPlaceSelected(prediction, _sourceController, true),
                ),
                const SizedBox(height: 10),
                CustomAutoCompleteTextField(
                  controller: _destinationController,
                  hintText: "Choose destination",
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPlaceSelected:
                      (prediction) => _onPlaceSelected(
                        prediction,
                        _destinationController,
                        false,
                      ),
                  suffixIcon:
                      (_sourceController.text.isNotEmpty ||
                              _destinationController.text.isNotEmpty)
                          ? const Icon(Icons.swap_vert)
                          : null,
                  onSuffixIconTap: _swapLocations,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24.0,
            left: 16.0,
            right: 16.0,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingRoute ? null : _triggerRouteCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child:
                    _isLoadingRoute
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Show Route",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
