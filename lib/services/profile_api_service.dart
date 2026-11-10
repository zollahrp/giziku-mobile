import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gizify/models/user_profile.dart';

class ProfileApiService {
  // Base URL untuk API - ganti dengan URL API Anda
  final String baseUrl = 'https://api.example.com';
  
  // Token untuk autentikasi - nanti akan diambil dari shared preferences/auth service
  String? authToken;
  
  // Constructor
  ProfileApiService({this.authToken});

  // Set token jika diperlukan setelah login
  void setToken(String token) {
    authToken = token;
  }

  // Headers untuk request API
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
  }

  // Get profile user
  Future<UserProfile> getUserProfile() async {
    // Untuk testing sementara, gunakan data dummy
    await Future.delayed(const Duration(seconds: 1)); // Simulasi network delay
    
    // Data dummy
    final dummyData = {
      'name': 'Jenny Perdana',
      'email': 'bagasakhfan02@gmail.com',
      'phone_number': '08123456789',
      'birth_date': '01/01/1995',
      'height': 165,
      'weight': 55,
      'photo_url': null,
    };
    
    return UserProfile.fromJson(dummyData);
    
    /* 
    // Implementasi sebenarnya dengan API
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
    */
  }

  // Update profile user
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    // Untuk testing sementara, gunakan data dummy
    await Future.delayed(const Duration(seconds: 2)); // Simulasi network delay
    
    // Return updated profile
    return profile;
    
    /*
    // Implementasi sebenarnya dengan API
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile'),
        headers: _getHeaders(),
        body: json.encode(profile.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
    */
  }

  // Upload foto profil
  Future<String> uploadProfilePhoto(String filePath) async {
    // Untuk testing sementara, gunakan data dummy
    await Future.delayed(const Duration(seconds: 2)); // Simulasi network delay
    
    return 'https://example.com/photos/dummy-profile.jpg';
    
    /*
    // Implementasi sebenarnya dengan API
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/profile/photo'),
      );
      
      // Set headers
      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
      });
      
      // Tambahkan file
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      
      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['photo_url'];
      } else {
        throw Exception('Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
    */
  }
}
