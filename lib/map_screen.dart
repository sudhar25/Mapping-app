import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final String farmerId;

  const MapScreen({super.key, required this.farmerId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLocation;
  List<LatLng> landPoints = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _saveLand() {
    // SEND THIS TO BACKEND API
    print("Farmer ID: ${widget.farmerId}");
    for (var p in landPoints) {
      print("${p.latitude}, ${p.longitude}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Land saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Your Land"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: landPoints.length >= 3 ? _saveLand : null,
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: currentLocation!,
          zoom: 16,
          onTap: (_, point) {
            setState(() => landPoints.add(point));
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.mapping_app',
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.blue, size: 40),
              ),
              ...landPoints.map(
                    (p) => Marker(
                  point: p,
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 20),
                ),
              )
            ],
          ),

          if (landPoints.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: landPoints,
                  color: Colors.green.withOpacity(0.3),
                  borderColor: Colors.green,
                  borderStrokeWidth: 3,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
