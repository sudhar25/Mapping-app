import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class MappedSuccessScreen extends StatefulWidget {
  final String farmerId;   // We keep as String from your existing code
  final List<LatLng> points;
  final double hectare;
  final double acre;
  final String crop;
  final String insurance;
  final String farmName;
  final String accessToken;// ← ADD this param when calling this screen

  const MappedSuccessScreen({
    super.key,
    required this.farmerId,
    required this.accessToken,
    required this.points,
    required this.hectare,
    required this.acre,
    required this.crop,
    required this.insurance,
    this.farmName = 'My Farm',  // default if not passed
  });

  @override
  State<MappedSuccessScreen> createState() => _MappedSuccessScreenState();
}

class _MappedSuccessScreenState extends State<MappedSuccessScreen> {
  bool _isSaving = false;

  Future<void> _confirmAndSave() async {
    setState(() => _isSaving = true);

    try {
      final result = await ApiService.saveFarm(
        farmerId: int.parse(widget.farmerId),
        accessToken: widget.accessToken,
        points: widget.points,
        farmName: widget.farmName,
        cropType: widget.crop,
        insuranceId: widget.insurance,
      );

      if (!mounted) return;

      // ✅ Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Farm saved! Area: ${result['area_acres']?.toStringAsFixed(2) ?? widget.acre.toStringAsFixed(2)} acres',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;

      // ❌ Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 10),
            const Text(
              "Land Mapped Successfully",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                title: const Text("Farm Name"),
                subtitle: Text(widget.farmName),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Area"),
                subtitle: Text(
                  "${widget.hectare.toStringAsFixed(2)} ha  |  ${widget.acre.toStringAsFixed(2)} acres",
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Crop"),
                subtitle: Text(widget.crop),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Insurance ID"),
                subtitle: Text(widget.insurance),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Boundary Points"),
                subtitle: Text("${widget.points.length} GPS points captured"),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Confirm & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _confirmAndSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}