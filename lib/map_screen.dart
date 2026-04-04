import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'mapped_success_screen.dart';

class MapScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  final String accessToken;

  const MapScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.accessToken,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController cropController = TextEditingController();
  final TextEditingController insuranceController = TextEditingController();
  final TextEditingController farmNameController = TextEditingController();

  LatLng? currentLocation;
  List<LatLng> landPoints = [];
  bool isMapping = false;

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // ✅ FIX: always cancel stream when screen is popped
    positionStream?.cancel();
    cropController.dispose();
    insuranceController.dispose();
    farmNameController.dispose();
    super.dispose();
  }

  // ─── LOCATION ────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Enable it in settings.'),
          ),
        );
      }
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  // ─── MAPPING ─────────────────────────────────────────────
  void startMapping() {
    landPoints.clear();
    setState(() => isMapping = true);

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((Position pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        currentLocation = point;
        if (landPoints.isEmpty ||
            const Distance().as(LengthUnit.Meter, landPoints.last, point) > 3) {
          landPoints.add(point);
        }
      });
    });
  }

  void stopMapping() {
    positionStream?.cancel();
    positionStream = null;
    setState(() => isMapping = false);
  }

  // ─── AREA CALCULATION (FIXED) ────────────────────────────
  // Uses Shoelace formula on projected Cartesian coordinates.
  // Converts lat/lng to meters using Haversine — accurate for farm-sized areas.
  double calculateAreaHectare(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    const double earthRadius = 6378137.0; // meters
    const double toRad = pi / 180.0;

    // Use centroid of points as local origin to minimize floating point error
    double originLat = 0, originLng = 0;
    for (final p in points) {
      originLat += p.latitude;
      originLng += p.longitude;
    }
    originLat /= points.length;
    originLng /= points.length;

    // Project each point to meters from origin using equirectangular approximation
    // Accurate for areas < ~100 km across (all farm fields qualify)
    List<double> x = [], y = [];
    for (final p in points) {
      final dLat = (p.latitude - originLat) * toRad;
      final dLng = (p.longitude - originLng) * toRad;
      final midLat = (p.latitude + originLat) / 2 * toRad;
      x.add(earthRadius * dLng * cos(midLat)); // meters east
      y.add(earthRadius * dLat);               // meters north
    }

    // Shoelace formula for polygon area in square meters
    double area = 0.0;
    final n = x.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += x[i] * y[j];
      area -= x[j] * y[i];
    }
    area = area.abs() / 2.0;

    return area / 10000.0; // m² → hectares
  }

  double get areaHectare => calculateAreaHectare(landPoints);
  double get areaAcre => areaHectare * 2.47105;

  // ─── SAVE ────────────────────────────────────────────────
  void saveLand() {
    if (cropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the crop name')),
      );
      return;
    }

    final farmName = farmNameController.text.trim().isEmpty
        ? "${widget.farmerName}'s Farm"
        : farmNameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MappedSuccessScreen(
          farmerId: widget.farmerId,
          accessToken: widget.accessToken,
          points: landPoints,
          hectare: areaHectare,
          acre: areaAcre,
          crop: cropController.text.trim(),
          insurance: insuranceController.text.trim(),
          farmName: farmName,
        ),
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────
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
                  ? "🚶 Walking — points being captured automatically"
                  : landPoints.isEmpty
                  ? "▶ Press START to begin mapping your land"
                  : "✅ ${landPoints.length} points captured — tap map to add more",
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: currentLocation!,
                zoom: 18,
                onTap: (_, LatLng point) {
                  // Allow manual taps when NOT auto-mapping
                  if (!isMapping) {
                    setState(() => landPoints.add(point));
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.mapping_app',
                ),
                MarkerLayer(
                  markers: [
                    // Current location
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 40),
                    ),
                    // Land boundary points
                    ...landPoints.map(
                          (p) => Marker(
                        point: p,
                        width: 16,
                        height: 16,
                        child: const Icon(Icons.circle,
                            size: 10, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                if (landPoints.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: landPoints,
                        color: Colors.green.withOpacity(0.25),
                        borderColor: Colors.green,
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Form — only shown once 3+ points exist
          if (landPoints.length >= 3)
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                children: [
                  // Area display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.area_chart,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "${areaHectare.toStringAsFixed(3)} ha  |  "
                              "${areaAcre.toStringAsFixed(3)} acres",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: farmNameController,
                    decoration: InputDecoration(
                      labelText: "🏡 Farm Name (optional)",
                      hintText: "${widget.farmerName}'s Farm",
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cropController,
                    decoration: const InputDecoration(
                      labelText: "🌾 Crop Name *",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: insuranceController,
                    decoration: const InputDecoration(
                      labelText: "🛡 Insurance ID (optional)",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text("Start"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: isMapping ? null : startMapping,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop, size: 18),
                label: const Text("Stop"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: isMapping ? stopMapping : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: landPoints.length >= 3 ? saveLand : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}