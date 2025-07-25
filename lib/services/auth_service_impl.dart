import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'auth_service_interface.dart';
import 'shared_prefs_service.dart';

class AuthServiceImpl implements IAuthService {
  final AuthRepository _authRepository;
  final SharedPrefsService _prefsService;

  AuthServiceImpl({
    AuthRepository? authRepository,
    SharedPrefsService? prefsService,
  }) : _authRepository =
           authRepository ??
           AuthRepository(
             baseUrl: ApiConfig.baseUrl,
             prefsService: prefsService ?? SharedPrefsService(),
           ),
       _prefsService = prefsService ?? SharedPrefsService();

  @override
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      // First check if we have a user stored in SharedPreferences
      final userData = await _prefsService.getCurrentUser();
      if (userData != null) {
        return ApiResponse<UserModel>.success(
          data: UserModel.fromJson(jsonDecode(userData)),
        );
      }

      // If not in prefs but we have a token, try to get from API
      final token = await _prefsService.getAuthToken();
      if (token != null) {
        final user = await _authRepository.getUserProfile();
        if (user != null) {
          // Save the updated user data to prefs
          await _prefsService.setCurrentUser(jsonEncode(user.toJson()));
          return ApiResponse<UserModel>.success(data: user);
        }
      }

      // No user found
      return ApiResponse<UserModel>.error(message: 'User not authenticated');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return ApiResponse<UserModel>.error(
        message: 'Failed to get user: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UserModel>> signIn(LoginRequest request) async {
    try {
      final response = await _authRepository.signInWithEmailPassword(request);

      if (response.success &&
          response.userData != null &&
          response.token != null) {
        final user = UserModel.fromJson({
          ...response.userData!,
          'token': response.token,
        });

        // Save token and user data
        await _saveAuthData(user);
        return ApiResponse<UserModel>.success(data: user);
      } else {
        return ApiResponse<UserModel>.error(
          message: response.message ?? 'Failed to sign in',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return ApiResponse<UserModel>.error(
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UserModel>> signUp(RegisterRequest request) async {
    try {
      final response = await _authRepository.signUpWithEmailPassword(request);

      if (response.success &&
          response.userData != null &&
          response.token != null) {
        final user = UserModel.fromJson({
          ...response.userData!,
          'token': response.token,
        });

        // Save token and user data
        await _saveAuthData(user);
        return ApiResponse<UserModel>.success(data: user);
      } else {
        return ApiResponse<UserModel>.error(
          message: response.message ?? 'Failed to sign up',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign up error: $e');
      }
      return ApiResponse<UserModel>.error(
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<bool>> signOut() async {
    try {
      // Clear local storage
      await _prefsService.clearAuthToken();
      await _prefsService.clearCurrentUser();

      // Optionally call a backend endpoint to invalidate the token
      await _authRepository.signOut();

      return ApiResponse<bool>.success(data: true);
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      return ApiResponse<bool>.error(
        message: 'Failed to sign out: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _prefsService.getAuthToken();
    return token != null;
  }

  @override
  Future<ApiResponse<UserModel>> refreshToken() async {
    try {
      final token = await _prefsService.getAuthToken();
      if (token == null) {
        return ApiResponse<UserModel>.error(message: 'No auth token available');
      }

      // For now, just retrieve the user profile again
      // In a real implementation, you'd call a specific refresh token endpoint
      final user = await _authRepository.getUserProfile();

      if (user != null) {
        // Save the user data
        await _saveAuthData(user);
        return ApiResponse<UserModel>.success(data: user);
      } else {
        // Clear tokens as they might be expired or invalid
        await _prefsService.clearAuthToken();
        return ApiResponse<UserModel>.error(message: 'Failed to refresh token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Refresh token error: $e');
      }
      return ApiResponse<UserModel>.error(
        message: 'Failed to refresh token: ${e.toString()}',
      );
    }
  }

  // Helper method to save authentication data
  Future<void> _saveAuthData(UserModel user) async {
    if (user.token != null) {
      await _prefsService.setAuthToken(user.token!);
    }
    await _prefsService.setCurrentUser(jsonEncode(user.toJson()));
  }
}
