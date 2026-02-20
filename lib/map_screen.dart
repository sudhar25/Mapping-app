import 'dart:async';
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
  StreamSubscription<Position>? positionStream;
  bool isMapping = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  void startMapping() {
    landPoints.clear();
    isMapping = true;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2, // add point every 2 meters
      ),
    ).listen((Position pos) {
      LatLng point = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = point;
        landPoints.add(point);
      });
    });
  }

  void stopMapping() {
    positionStream?.cancel();
    isMapping = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mapping completed")),
    );
  }

  void saveLand() {
    debugPrint("Farmer: ${widget.farmerId}");
    debugPrint("Total Points: ${landPoints.length}");

    for (var p in landPoints) {
      debugPrint("${p.latitude}, ${p.longitude}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Land saved (console only)")),
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
      appBar: AppBar(title: const Text("Walk & Map Land")),
      body: FlutterMap(
        options: MapOptions(
          center: currentLocation!,
          zoom: 17,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: isMapping ? null : startMapping,
              child: const Text("Start Mapping"),
            ),
            ElevatedButton(
              onPressed: isMapping ? stopMapping : null,
              child: const Text("Stop"),
            ),
            ElevatedButton(
              onPressed: landPoints.length >= 3 ? saveLand : null,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}