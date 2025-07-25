import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../services/shared_prefs_service.dart';

class AuthRepository {
  final String baseUrl;
  final http.Client client;
  final SharedPrefsService _prefsService;

  AuthRepository({
    required this.baseUrl,
    http.Client? client,
    SharedPrefsService? prefsService,
  }) : client = client ?? http.Client(),
       _prefsService = prefsService ?? SharedPrefsService();

  /// Login
  Future<AuthResponse> signInWithEmailPassword(LoginRequest request) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      print('=== LOGIN RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: $data');

      if (response.statusCode == 200) {
        final accessToken = data['access'];
        final refreshToken = data['refresh'];
        final userData = data['data'];

        if (accessToken != null && userData != null) {
          // Save access token
          await _prefsService.setAuthToken(accessToken);

          // Save refresh token if available
          if (refreshToken != null) {
            await _prefsService.setRefreshToken(refreshToken);
          }

          try {
            // Pass complete response data to properly extract tokens
            final completeData = Map<String, dynamic>.from(data);
            completeData['data'] = userData;

            final user = UserModel.fromJson(completeData);
            await _prefsService.setCurrentUser(jsonEncode(user.toJson()));

            return AuthResponse(
              success: true,
              message: data['message'] ?? 'Login success',
              token: accessToken,
              userData: userData,
            );
          } catch (e) {
            print('Error parsing user data: $e');
            return AuthResponse.error(
              'Error parsing user data: ${e.toString()}',
            );
          }
        } else {
          return AuthResponse.error('Invalid token or user data');
        }
      } else {
        return AuthResponse.error(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      return AuthResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Registrasi
  Future<AuthResponse> signUpWithEmailPassword(RegisterRequest request) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      print('=== REGISTER RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final accessToken = data['access'];
        final refreshToken = data['refresh'];
        final userData = data['data'];

        if (accessToken != null && userData != null) {
          // Save access token
          await _prefsService.setAuthToken(accessToken);

          // Save refresh token if available
          if (refreshToken != null) {
            await _prefsService.setRefreshToken(refreshToken);
          }

          try {
            // Pass complete response data to properly extract tokens
            final completeData = Map<String, dynamic>.from(data);
            completeData['data'] = userData;

            final user = UserModel.fromJson(completeData);
            await _prefsService.setCurrentUser(jsonEncode(user.toJson()));

            return AuthResponse(
              success: true,
              message: data['message'] ?? 'Register success',
              token: accessToken,
              userData: userData,
            );
          } catch (e) {
            print('Error parsing user data: $e');
            return AuthResponse.error(
              'Error parsing user data: ${e.toString()}',
            );
          }
        } else {
          return AuthResponse.error('Invalid token or user data');
        }
      } else {
        return AuthResponse.error(data['message'] ?? 'Register failed');
      }
    } catch (e) {
      return AuthResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Logout
  Future<bool> signOut() async {
    try {
      // Clear all authentication data
      await _prefsService.clearAuthToken();
      await _prefsService.clearRefreshToken();
      await _prefsService.clearCurrentUser();
      print('User signed out successfully');
      return true;
    } catch (e) {
      print('Error signing out: ${e.toString()}');
      return false;
    }
  }

  /// Cek status login
  Future<bool> isLoggedIn() async {
    final token = await _prefsService.getAuthToken();
    return token != null;
  }

  /// Ambil profil user
  Future<UserModel?> getUserProfile() async {
    try {
      final token = await _prefsService.getAuthToken();
      if (token == null) return null;

      final response = await client.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final user = UserModel.fromJson(data);
          await _prefsService.setCurrentUser(jsonEncode(user.toJson()));
          return user;
        } catch (e) {
          print('Error parsing user profile data: $e');
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user profile: ${e.toString()}');
      return null;
    }
  }
}
