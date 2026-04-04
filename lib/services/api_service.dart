import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants.dart';

class ApiService {
  static const String _baseUrl = AppConstants.baseUrl;

  // ─── REGISTER ────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String password,
    required String phone,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    final body = jsonEncode({
      'email': email,
      'full_name': fullName,
      'password': password,
      'phone': phone,
      'role': 'FARMER',   // farmers always register as FARMER
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data; // { user: {...}, tokens: { access_token, refresh_token } }
      } else {
        throw Exception(data['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Register error: $e');
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    final body = jsonEncode({
      'email': email,
      'password': password,
      'role': 'FARMER',
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // { user: { id, full_name, email, role }, tokens: {...} }
      } else {
        throw Exception(data['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // ─── SAVE FARM ───────────────────────────────────────────
  static Future<Map<String, dynamic>> saveFarm({
    required int farmerId,
    required String accessToken,       // ← now uses real JWT
    required List<LatLng> points,
    required String farmName,
    required String cropType,
    required String insuranceId,
  }) async {
    final uri = Uri.parse('$_baseUrl/farmer/save-farm');

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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // ← real JWT token
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Failed to save farm');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}