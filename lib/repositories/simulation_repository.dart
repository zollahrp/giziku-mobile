import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/simulation_model.dart';
import '../services/shared_prefs_service.dart';

class SimulationRepository {
  final String baseUrl;
  final http.Client client;
  final SharedPrefsService _prefsService;

  SimulationRepository({
    required this.baseUrl,
    http.Client? client,
    SharedPrefsService? prefsService,
  }) : client = client ?? http.Client(),
       _prefsService = prefsService ?? SharedPrefsService();

  Future<SimulationResponse> createSimulation(SimulationRequest request) async {
    try {
      // Get the auth token for the request header
      final token = await _prefsService.getAuthToken();
      if (token == null) {
        return SimulationResponse.error('No authentication token available');
      }

      final response = await client.post(
        Uri.parse('$baseUrl/api/gizi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      print('=== SIMULATION API RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return SimulationResponse(
            success: true,
            message: data['message'] ?? 'Simulation created successfully',
            data: data['data'] != null
                ? SimulationResult.fromJson(data['data'])
                : null,
          );
        } catch (e) {
          print('Error parsing simulation response: $e');
          return SimulationResponse.error(
            'Error parsing response: ${e.toString()}',
          );
        }
      } else {
        return SimulationResponse.error(
          data['message'] ?? 'Failed to create simulation',
        );
      }
    } catch (e) {
      print('Network error during simulation creation: $e');
      return SimulationResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<SimulationResponse> getSimulationById(int id) async {
    try {
      // Get the auth token for the request header
      final token = await _prefsService.getAuthToken();
      if (token == null) {
        return SimulationResponse.error('No authentication token available');
      }

      final response = await client.get(
        Uri.parse('$baseUrl/api/gizi/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        try {
          return SimulationResponse(
            success: true,
            message: data['message'] ?? 'Simulation retrieved successfully',
            data: data['data'] != null
                ? SimulationResult.fromJson(data['data'])
                : null,
          );
        } catch (e) {
          print('Error parsing simulation response: $e');
          return SimulationResponse.error(
            'Error parsing response: ${e.toString()}',
          );
        }
      } else {
        return SimulationResponse.error(
          data['message'] ?? 'Failed to retrieve simulation',
        );
      }
    } catch (e) {
      print('Network error retrieving simulation: $e');
      return SimulationResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<List<SimulationResult>> getUserSimulations() async {
    try {
      // Get the auth token for the request header
      final token = await _prefsService.getAuthToken();
      if (token == null) {
        return [];
      }

      final response = await client.get(
        Uri.parse('$baseUrl/api/gizi/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        try {
          final List<dynamic> simulationsJson = data['data'];
          return simulationsJson
              .map((json) => SimulationResult.fromJson(json))
              .toList();
        } catch (e) {
          print('Error parsing simulations list: $e');
          return [];
        }
      } else {
        print('Failed to retrieve user simulations: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Network error retrieving user simulations: $e');
      return [];
    }
  }
}
