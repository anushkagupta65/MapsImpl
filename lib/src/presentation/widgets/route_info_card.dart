// lib/presentation/widgets/expandable_route_details.dart
import 'package:flutter/material.dart';
import 'package:map_assessment/src/models/route_info.dart';

class ExpandableRouteDetails extends StatelessWidget {
  final RouteInfo routeInfo;
  final VoidCallback onStartNavigation;
  final VoidCallback onClearRoute;

  const ExpandableRouteDetails({
    super.key,
    required this.routeInfo,
    required this.onStartNavigation,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      expand: true,
      snap: true,
      snapSizes: const [0.2, 0.5, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      Icons.alt_route,
                      routeInfo.distance,
                      "Distance",
                    ),
                    _buildMetricItem(
                      Icons.timer,
                      routeInfo.duration,
                      "Duration",
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStartNavigation,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      "Start",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Clear Route Button
                TextButton(
                  onPressed: onClearRoute,
                  child: const Text(
                    "Clear Route",
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                // Extra space for scroll when expanded
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

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
