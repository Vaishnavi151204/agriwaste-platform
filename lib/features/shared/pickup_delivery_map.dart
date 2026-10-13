import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickupDeliveryMap extends StatelessWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;

  const PickupDeliveryMap({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  @override
  Widget build(BuildContext context) {
    final hasPickup = pickupLat != null && pickupLng != null;
    final hasDelivery = deliveryLat != null && deliveryLng != null;

    if (!hasPickup && !hasDelivery) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No map locations available'),
        ),
      );
    }

    final points = <LatLng>[];
    if (hasPickup) points.add(LatLng(pickupLat!, pickupLng!));
    if (hasDelivery) points.add(LatLng(deliveryLat!, deliveryLng!));

    final center = points.length == 2
        ? LatLng(
      (points[0].latitude + points[1].latitude) / 2,
      (points[0].longitude + points[1].longitude) / 2,
    )
        : points.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: points.length == 2 ? 11.5 : 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.agriwaste.platform',
            ),
            if (points.length == 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (hasPickup)
                  Marker(
                    point: LatLng(pickupLat!, pickupLng!),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.agriculture, color: Colors.green, size: 36),
                  ),
                if (hasDelivery)
                  Marker(
                    point: LatLng(deliveryLat!, deliveryLng!),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.home, color: Colors.blue, size: 36),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}