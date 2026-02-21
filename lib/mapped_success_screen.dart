import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MappedSuccessScreen extends StatelessWidget {
  final String farmerId;
  final List<LatLng> points;
  final double hectare;
  final double acre;
  final String crop;
  final String insurance;

  const MappedSuccessScreen({
    super.key,
    required this.farmerId,
    required this.points,
    required this.hectare,
    required this.acre,
    required this.crop,
    required this.insurance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Mapped Successfully"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                color: Colors.green, size: 80),
            const SizedBox(height: 10),
            const Text(
              "Land Mapped Successfully",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                title: Text("Area"),
                subtitle: Text(
                    "${hectare.toStringAsFixed(2)} ha | ${acre.toStringAsFixed(2)} acre"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Crop"),
                subtitle: Text(crop),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Insurance ID"),
                subtitle: Text(insurance),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Confirm & Save"),
              onPressed: () {
                // 🔹 SEND THIS TO DB / ML
                // points -> polygon
                // hectare / acre -> features

                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}