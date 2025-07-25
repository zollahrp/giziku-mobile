import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String AUTH_TOKEN_KEY = 'auth_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String USER_DATA_KEY = 'user_data';

  // Simpan token autentikasi
  Future<bool> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    print('Saving auth token: $token');
    return prefs.setString(AUTH_TOKEN_KEY, token);
  }

  // Simpan refresh token
  Future<bool> setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    print('Saving refresh token: $token');
    return prefs.setString(REFRESH_TOKEN_KEY, token);
  }

  // Ambil token autentikasi
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AUTH_TOKEN_KEY);
    print('Retrieved auth token: $token');
    return token;
  }

  // Ambil refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(REFRESH_TOKEN_KEY);
  }

  // Hapus token autentikasi
  Future<bool> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(AUTH_TOKEN_KEY);
  }

  // Hapus refresh token
  Future<bool> clearRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(REFRESH_TOKEN_KEY);
  }

  // Simpan data user saat ini (dalam bentuk JSON string)
  Future<bool> setCurrentUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(USER_DATA_KEY, userJson);
  }

  // Ambil data user saat ini
  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_DATA_KEY);
  }

  // Hapus data user saat ini
  Future<bool> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(USER_DATA_KEY);
  }

  // Hapus semua data shared preferences
  Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  // Hapus semua data autentikasi (token dan user)
  Future<void> clearAllAuthData() async {
    await clearAuthToken();
    await clearRefreshToken();
    await clearCurrentUser();
    print('All auth data cleared');
  }
}
