import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'shared_prefs_service.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SharedPrefsService _prefsService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthService({
    required AuthRepository authRepository,
    SharedPrefsService? prefsService,
  }) : _authRepository = authRepository,
       _prefsService = prefsService ?? SharedPrefsService() {
    _loadUserFromPrefs();
  }

  // INIT
  Future<void> init() async {
    await _loadUserFromPrefs();
  }

  // LOAD USER LOCAL
  Future<void> _loadUserFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userJson =
          await _prefsService.getCurrentUser();

      if (userJson != null) {
        _currentUser =
            UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      _errorMessage =
          'Error loading user data';

      print(
        'Error loading user data: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGIN EMAIL
  Future<bool> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      final response =
          await _authRepository
              .signInWithEmailPassword(
        loginRequest,
      );

      if (response.success) {
        await _loadUserFromPrefs();
        return true;
      } else {
        _errorMessage =
            response.message ??
            'Failed to sign in';

        return false;
      }
    } catch (e) {
      _errorMessage =
          'An error occurred during sign in';

      print(
        'Sign in error: ${e.toString()}',
      );

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTER EMAIL
  Future<bool> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final registerRequest =
          RegisterRequest(
        name: name,
        email: email,
        password: password,
      );

      final response =
          await _authRepository
              .signUpWithEmailPassword(
        registerRequest,
      );

      if (response.success) {
        await _loadUserFromPrefs();
        return true;
      } else {
        _errorMessage =
            response.message ??
            'Failed to sign up';

        return false;
      }
    } catch (e) {
      _errorMessage =
          'An error occurred during registration';

      print(
        'Sign up error: ${e.toString()}',
      );

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // GOOGLE SIGN IN
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        _errorMessage =
            'Google sign in canceled';

        return false;
      }

      final GoogleSignInAuthentication
      googleAuth =
          await googleUser.authentication;

      final credential =
          firebase_auth
              .GoogleAuthProvider
              .credential(
        accessToken:
            googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebase_auth
              .FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final user =
          userCredential.user;

      if (user == null) {
        _errorMessage =
            'Failed to get user data';

        return false;
      }

      final userModel = UserModel(
        id: user.uid,
        name:
            user.displayName ?? '',
        email:
            user.email ?? '',
        photoUrl:
            user.photoURL,
        authProvider:
            AuthProvider.google,
        createdAt:
            DateTime.now(),
        updatedAt:
            DateTime.now(),
      );

      _currentUser = userModel;

      await _prefsService
          .setCurrentUser(
        jsonEncode(
          userModel.toJson(),
        ),
      );

      return true;
    } catch (e) {
      _errorMessage =
          'Google sign in error: ${e.toString()}';

      print(
        'Google sign in error: ${e.toString()}',
      );

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    _isLoading = true;

    notifyListeners();

    try {
      await _googleSignIn.signOut();

      await firebase_auth
          .FirebaseAuth.instance
          .signOut();

      await _prefsService
          .clearCurrentUser();

      _currentUser = null;
    } catch (e) {
      _errorMessage =
          'Error signing out';

      print(
        'Sign out error: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REFRESH PROFILE
  Future<void> refreshUserProfile() async {
    _isLoading = true;

    notifyListeners();

    try {
      final user =
          await _authRepository
              .getUserProfile();

      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      _errorMessage =
          'Error refreshing user profile';

      print(
        'Error refreshing user profile: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // RESET ERROR
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}