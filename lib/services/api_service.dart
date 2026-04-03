import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants.dart';

class ApiService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Saves the mapped farm to the backend.
  /// Returns true on success, throws an exception with message on failure.
  static Future<Map<String, dynamic>> saveFarm({
    required int farmerId,
    required List<LatLng> points,
    required String farmName,
    required String cropType,
    required String insuranceId,
  }) async {
    final uri = Uri.parse('$_baseUrl/farmer/save-farm');

    // Convert LatLng list to list of {lat, lng} maps
    final boundaryPoints = points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    final body = jsonEncode({
      'farmer_id': farmerId,
      'farm_name': farmName,
      'crop_type': cropType,
      'insurance_id': insuranceId,
      'boundary_points': boundaryPoints,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data; // success — contains farm_id, area_acres, etc.
      } else {
        throw Exception(data['detail'] ?? 'Failed to save farm');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}