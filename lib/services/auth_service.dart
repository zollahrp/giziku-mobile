import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'google_auth_service.dart';
import 'shared_prefs_service.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository;
  final GoogleAuthService _googleAuthService;
  final SharedPrefsService _prefsService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthService({
    required AuthRepository authRepository,
    required GoogleAuthService googleAuthService,
    SharedPrefsService? prefsService,
  }) : _authRepository = authRepository,
       _googleAuthService = googleAuthService,
       _prefsService = prefsService ?? SharedPrefsService() {
    // Auto-load user data jika tersedia di local storage
    _loadUserFromPrefs();
  }

  // Inisialisasi - cek apakah user sudah login
  Future<void> init() async {
    await _loadUserFromPrefs();
  }

  // Load user dari SharedPreferences
  Future<void> _loadUserFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userJson = await _prefsService.getCurrentUser();
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      _errorMessage = 'Error loading user data';
      print('Error loading user data: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login dengan email dan password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginRequest = LoginRequest(email: email, password: password);
      final response = await _authRepository.signInWithEmailPassword(
        loginRequest,
      );

      if (response.success) {
        await _loadUserFromPrefs();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to sign in';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during sign in';
      print('Sign in error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register dengan email dan password
  Future<bool> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final registerRequest = RegisterRequest(
        name: name,
        email: email,
        password: password,
      );
      final response = await _authRepository.signUpWithEmailPassword(
        registerRequest,
      );

      if (response.success) {
        await _loadUserFromPrefs();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to sign up';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration';
      print('Sign up error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login dengan Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _googleAuthService.signInWithGoogle();

      if (response.success) {
        await _loadUserFromPrefs();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to sign in with Google';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during Google sign in';
      print('Google sign in error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from repository
      await _authRepository.signOut();

      // Sign out from Google if using Google Sign-In
      if (_currentUser?.authProvider == AuthProvider.google) {
        await _googleAuthService.signOut();
      }

      // Clear user data
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Error signing out';
      print('Sign out error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh user profile data
  Future<void> refreshUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.getUserProfile();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      _errorMessage = 'Error refreshing user profile';
      print('Error refreshing user profile: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset error
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}
