// memory_gallery_map.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:latlong2/latlong.dart';


class GalleryItem {
  final double lat;
  final double lng;
  final String image;
  final int participantCount; 

  GalleryItem({
    required this.lat,
    required this.lng,
    required this.image,
    required this.participantCount,
  });
}


/// A widget that displays a map with clustered markers for gallery items.
class MemoryGalleryMap extends StatefulWidget {
  final List<GalleryItem> items;
  final void Function(GalleryItem)? onMarkerTap; // <-- Added callback

  const MemoryGalleryMap({
    super.key,
    required this.items,
    this.onMarkerTap,
  });


  @override
  _MemoryGalleryMapState createState() => _MemoryGalleryMapState();
}

class _MemoryGalleryMapState extends State<MemoryGalleryMap> {
  final MapController _mapController = MapController();
  

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('No items to display on the map.'));
    }

    // Calculate the bounds from the items.
    double minLat = widget.items.map((item) => item.lat).reduce(min);
    double maxLat = widget.items.map((item) => item.lat).reduce(max);
    double minLng = widget.items.map((item) => item.lng).reduce(min);
    double maxLng = widget.items.map((item) => item.lng).reduce(max);

    // Calculate center and an initial zoom level.
    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    double initialZoom = calculateZoomLevel(minLat, maxLat, minLng, maxLng);

    // Convert each GalleryItem to a Marker.
    final markers = widget.items.map((item) {
      return Marker(
        width: 50,
        height: 50,
        point: LatLng(item.lat, item.lng),
        child: GestureDetector(
          onTap: () {
            // Optionally, add logic to display details about the image.
            widget.onMarkerTap?.call(item);
          },
          child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // The marker image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(item.image),
                fit: BoxFit.cover,
                width: 50,
                height: 50,
              ),
            ),
            // A small overlay at the bottom-right showing participantCount
            Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '👋 ${item.participantCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
      ),
      // In flutter_map v8, use the `children` property instead of `layers`.
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.yourapp',
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            disableClusteringAtZoom: 16,
            size: const Size(40, 40),
            // If you need to specify fit bounds options, do so without const if necessary:
         //   fitBoundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50)),
            markers: markers,
            builder: (context, clusterMarkers) {
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: offBlack,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${clusterMarkers.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// A simple function to calculate an approximate zoom level from the bounds.
  double calculateZoomLevel(double minLat, double maxLat, double minLng, double maxLng) {
    const double maxZoom = 18.0;
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    // A basic formula to calculate zoom; you can adjust it as needed.
    double zoom = maxZoom - (log(latDiff + lngDiff + 0.0001) / log(2));
    return zoom.clamp(0.0, maxZoom);
  }
}
