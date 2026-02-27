import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'mapped_success_screen.dart';

class MapScreen extends StatefulWidget {
  final String farmerId;

  const MapScreen({super.key, required this.farmerId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controllers
  final TextEditingController cropController = TextEditingController();
  final TextEditingController insuranceController = TextEditingController();

  // Mapping state
  LatLng? currentLocation;
  List<LatLng> landPoints = [];
  bool isMapping = false;

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ================= LOCATION =================
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  // ================= MAPPING =================
  void startMapping() {
    landPoints.clear();
    isMapping = true;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      LatLng point = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = point;

        // ✅ ADD POINTS WHILE WALKING
        if (landPoints.isEmpty ||
            Distance().as(
              LengthUnit.Meter,
              landPoints.last,
              point,
            ) >
                3) {
          landPoints.add(point);
        }
      });
    });
  }

  void stopMapping() {
    positionStream?.cancel();
    isMapping = false;
    setState(() {});
  }

  // ================= AREA =================
  double calculateAreaHectare(List<LatLng> points) {
    if (points.length < 3) return 0;

    const double earthRadius = 6378137;
    double area = 0;

    for (int i = 0; i < points.length; i++) {
      LatLng p1 = points[i];
      LatLng p2 = points[(i + 1) % points.length];

      area += (p2.longitude - p1.longitude) *
          (2 +
              sin(p1.latitude * pi / 180) +
              sin(p2.latitude * pi / 180));
    }

    area = area * earthRadius * earthRadius / 2;
    return area.abs() / 10000;
  }

  double get areaHectare => calculateAreaHectare(landPoints);
  double get areaAcre => areaHectare * 2.47105;

  // ================= SAVE =================
  void saveLand() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MappedSuccessScreen(
          farmerId: widget.farmerId,
          points: landPoints,
          hectare: areaHectare,
          acre: areaAcre,
          crop: cropController.text,
          insurance: insuranceController.text,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Walk & Map Land"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              isMapping
                  ? "🚶 Walk or tap map to add points"
                  : "▶ Tap map for first point or press START",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // MAP
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: currentLocation!,
                zoom: 17,
                onTap: (_, LatLng point) {
                  if (!isMapping) {
                    setState(() {
                      landPoints.add(point);
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.mapping_app',
                ),

                // Current location
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 40),
                    ),

                    // ✅ Land points markers
                    ...landPoints.map(
                          (p) => Marker(
                        point: p,
                        width: 20,
                        height: 20,
                        child: const Icon(Icons.circle,
                            size: 10, color: Colors.red),
                      ),
                    ),
                  ],
                ),

                // Polygon
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
          ),

          if (landPoints.length >= 3)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    "Area: ${areaHectare.toStringAsFixed(2)} ha | "
                        "${areaAcre.toStringAsFixed(2)} acre",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cropController,
                    decoration: const InputDecoration(
                      labelText: "🌾 Crop Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: insuranceController,
                    decoration: const InputDecoration(
                      labelText: "🛡 Insurance ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: isMapping ? null : startMapping,
              child: const Text("Start"),
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