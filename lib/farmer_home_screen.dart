import 'package:flutter/material.dart';
import 'map_screen.dart';

class FarmerHomeScreen extends StatelessWidget {
  final String farmerId;

  const FarmerHomeScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // light green background
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              "assets/images/logo.jpeg", // <-- your logo
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text("Farmer Dashboard"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer info card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Farmer Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("👨‍🌾 Name: Ramesh Patil"),
                    const SizedBox(height: 6),
                    const Text("📍 Village: Nashik"),
                    const SizedBox(height: 6),
                    Text("🆔 Farmer ID: $farmerId"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Guidance note
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "📌 Mapping Instructions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("• Walk around your land boundary"),
                    Text("• Tap the map at each corner point"),
                    Text("• Minimum 3 points required"),
                    Text("• Press SAVE after completing the boundary"),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Start mapping button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text(
                  "Start Land Mapping",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(farmerId: farmerId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}