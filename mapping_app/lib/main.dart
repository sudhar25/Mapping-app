import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const CropSureApp());
}
class CropSureApp extends StatelessWidget {
  const CropSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropSure Land Mapping',
      debugShowCheckedModeBanner: false,
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLocation;
  final List<LatLng> landPoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }


  void _addPoint(LatLng point) {
    setState(() {
      landPoints.add(point);
    });
  }

  void _saveLand() {
    DateTime now = DateTime.now();

    for (var point in landPoints) {
      print({
        "latitude": point.latitude,
        "longitude": point.longitude,
        "timestamp": now.toIso8601String()
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Land coordinates saved (console)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Farmer Land"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: landPoints.length >= 3 ? _saveLand : null,
          )
        ],
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          center: currentLocation!,
          zoom: 17,
          onTap: (tapPosition, point) => _addPoint(point),
        ),
        children: [
          TileLayer(
            urlTemplate:
            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),

          // Farmer location
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.blue, size: 40),
              ),
            ],
          ),

          // Land boundary points
          MarkerLayer(
            markers: landPoints
                .map(
                  (point) => Marker(
                point: point,
                width: 20,
                height: 20,
                child: const Icon(Icons.location_on,
                    color: Colors.red, size: 20),
              ),
            )
                .toList(),
          ),

          // Polygon
          if (landPoints.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: landPoints,
                  color: Colors.green.withOpacity(0.3),
                  borderStrokeWidth: 3,
                  borderColor: Colors.green,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
