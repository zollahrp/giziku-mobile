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

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);

        // Simpan token ke SharedPreferences jika login berhasil
        if (authResponse.success && authResponse.token != null) {
          await _prefsService.setAuthToken(authResponse.token!);

          // Jika API juga mengembalikan data user
          if (authResponse.userData != null) {
            final user = UserModel.fromJson(authResponse.userData!);
            await _prefsService.setCurrentUser(jsonEncode(user.toJson()));
          }
        }

        return authResponse;
      } else {
        return AuthResponse.error(data['message'] ?? 'Failed to sign in');
      }
    } catch (e) {
      return AuthResponse.error('Network error: ${e.toString()}');
    }
  }

  // Sign up dengan email dan password
  Future<AuthResponse> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);

        // Simpan token ke SharedPreferences jika registrasi berhasil
        if (authResponse.success && authResponse.token != null) {
          await _prefsService.setAuthToken(authResponse.token!);

          // Jika API juga mengembalikan data user
          if (authResponse.userData != null) {
            final user = UserModel.fromJson(authResponse.userData!);
            await _prefsService.setCurrentUser(jsonEncode(user.toJson()));
          }
        }

        return authResponse;
      } else {
        return AuthResponse.error(data['message'] ?? 'Failed to sign up');
      }
    } catch (e) {
      return AuthResponse.error('Network error: ${e.toString()}');
    }
  }

  // Logout
  Future<bool> signOut() async {
    try {
      // Hapus token dari SharedPreferences
      await _prefsService.clearAuthToken();
      await _prefsService.clearCurrentUser();

      // Opsional: Jika API memerlukan endpoint logout
      // final token = await _prefsService.getAuthToken();
      // await client.post(
      //   Uri.parse('$baseUrl/auth/logout'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      return true;
    } catch (e) {
      print('Error signing out: ${e.toString()}');
      return false;
    }
  }

  // Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await _prefsService.getAuthToken();
    return token != null;
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      final token = await _prefsService.getAuthToken();
      if (token == null) {
        return null;
      }

      final response = await client.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);

        // Update cached user data
        await _prefsService.setCurrentUser(jsonEncode(user.toJson()));

        return user;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user profile: ${e.toString()}');
      return null;
    }
  }
}
