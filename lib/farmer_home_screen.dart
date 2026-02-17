import 'package:flutter/material.dart';
import 'map_screen.dart';

class FarmerHomeScreen extends StatelessWidget {
  final String farmerId;

  const FarmerHomeScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmer Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Farmer Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // TEMP data (replace with DB fetch)
            Card(
              child: ListTile(
                title: const Text("Name: Ramesh Patil"),
                subtitle: const Text("Village: Nashik"),
                trailing: Text("ID: $farmerId"),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Start Land Mapping"),
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
