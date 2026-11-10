import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'shared_prefs_service.dart';

import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SharedPrefsService _prefsService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final FirestoreService _firestoreService = FirestoreService();

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

  String _mapFirebaseAuthError(
    firebase_auth.FirebaseAuthException e, {
    required String defaultMsg,
  }) {
    debugPrint('FirebaseAuthException: code=${e.code}, message=${e.message}');
    final code = e.code.toLowerCase();
    final msg = e.message ?? '';

    if (code.contains('requests-from-referer') ||
        code.contains('blocked') ||
        msg.contains('blocked')) {
      return 'Akses API diblokir untuk port web ini (HTTP Referrer Blocked).\n\n'
          'Solusi:\n'
          '• Jika tes di Web, jalankan perintah:\n'
          '  flutter run -d chrome --web-port=3000\n'
          '• Atau jalankan di Android Emulator / Device fisik.\n'
          '• Atau tambahkan port Anda di Google Cloud Console > Credentials > API Key.';
    }
    if (code == 'user-not-found' ||
        code == 'invalid-credential' ||
        code == 'wrong-password') {
      return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
    }
    if (code == 'invalid-email') {
      return 'Format alamat email tidak valid.';
    }
    if (code == 'email-already-in-use') {
      return 'Email ini sudah terdaftar. Silakan masuk dengan akun tersebut.';
    }
    if (code == 'weak-password') {
      return 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter dengan kombinasi huruf dan angka.';
    }
    if (code == 'user-disabled') {
      return 'Akun ini telah dinonaktifkan oleh administrator.';
    }
    if (code == 'too-many-requests') {
      return 'Terlalu banyak percobaan gagal. Mohon tunggu beberapa saat sebelum mencoba lagi.';
    }
    if (code == 'network-request-failed') {
      return 'Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke internet.';
    }
    if (code == 'operation-not-allowed') {
      return 'Metode masuk ini belum diaktifkan di pengaturan Firebase.';
    }
    if (code == 'popup-closed-by-user') {
      return 'Jendela login Google ditutup sebelum selesai.';
    }

    if (msg.isNotEmpty && msg != 'Error' && !msg.toLowerCase().contains('unknown')) {
      return msg;
    }

    return '$defaultMsg (${e.code})';
  }

  // LOGIN EMAIL DENGAN FIREBASE
  Future<bool> signInWithEmailPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Gagal mendapatkan data akun.';
        return false;
      }

      // Ambil atau buat data profil di Firestore (dengan fallback aman)
      UserModel? userModel;
      try {
        userModel = await _firestoreService.getUser(user.uid);
        if (userModel == null) {
          userModel = UserModel(
            id: user.uid,
            name: user.displayName ?? (email.split('@').first),
            email: user.email ?? email,
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authProvider: AuthProvider.email,
          );
          await _firestoreService.saveUser(userModel);
        }
      } catch (firestoreErr) {
        debugPrint('Firestore getUser warning: $firestoreErr');
        userModel ??= UserModel(
          id: user.uid,
          name: user.displayName ?? (email.split('@').first),
          email: user.email ?? email,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          authProvider: AuthProvider.email,
        );
      }

      _currentUser = userModel;
      await _prefsService.setCurrentUser(jsonEncode(userModel.toJson()));
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e, defaultMsg: 'Gagal masuk');
      return false;
    } catch (e) {
      debugPrint('General Login Error: $e');
      _errorMessage = 'Terjadi kesalahan saat masuk: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTER EMAIL DENGAN FIREBASE
  Future<bool> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Gagal membuat akun';
        return false;
      }

      await user.updateDisplayName(name);

      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email.trim(),
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        authProvider: AuthProvider.email,
      );

      await _firestoreService.saveUser(userModel);
      _currentUser = userModel;
      await _prefsService.setCurrentUser(jsonEncode(userModel.toJson()));
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e, defaultMsg: 'Gagal mendaftar');
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // RESET PASSWORD
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e, defaultMsg: 'Gagal mengirim instruksi reset sandi');
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
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
      firebase_auth.UserCredential userCredential;
      if (kIsWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await firebase_auth.FirebaseAuth.instance
            .signInWithPopup(googleProvider);
      } else {
        await _googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _errorMessage = 'Login dengan Google dibatalkan.';
          return false;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await firebase_auth.FirebaseAuth.instance
            .signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Gagal mendapatkan data akun Google.';
        return false;
      }

      UserModel? userModel;
      try {
        userModel = await _firestoreService.getUser(user.uid);
        if (userModel == null) {
          userModel = UserModel(
            id: user.uid,
            name: user.displayName ??
                (user.email?.split('@').first ?? 'Pengguna Gizify'),
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authProvider: AuthProvider.google,
          );
          await _firestoreService.saveUser(userModel);
        }
      } catch (firestoreErr) {
        debugPrint('Firestore google sync warning: $firestoreErr');
        userModel ??= UserModel(
          id: user.uid,
          name: user.displayName ??
              (user.email?.split('@').first ?? 'Pengguna Gizify'),
          email: user.email ?? '',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          authProvider: AuthProvider.google,
        );
      }

      _currentUser = userModel;
      await _prefsService.setCurrentUser(jsonEncode(userModel.toJson()));
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage =
          _mapFirebaseAuthError(e, defaultMsg: 'Gagal masuk dengan Google');
      return false;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      _errorMessage = 'Terjadi kesalahan saat login Google: ${e.toString()}';
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

      await firebase_auth.FirebaseAuth.instance.signOut();

      await _prefsService.clearCurrentUser();

      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Error signing out';

      print('Sign out error: ${e.toString()}');
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

  // RESET ERROR
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}
