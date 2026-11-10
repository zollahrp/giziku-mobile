import 'package:flutter/material.dart';
import 'package:gizify/models/user_profile.dart';
import 'package:gizify/services/profile_api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileApiService _apiService = ProfileApiService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch user profile
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final profile = await _apiService.getUserProfile();
      _userProfile = profile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? birthDate,
    double? height,
    double? weight,
  }) async {
    if (_userProfile == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProfile = _userProfile!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        height: height,
        weight: weight,
      );
      
      final result = await _apiService.updateUserProfile(updatedProfile);
      _userProfile = result;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Upload profile photo
  Future<bool> uploadProfilePhoto(String filePath) async {
    if (_userProfile == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final photoUrl = await _apiService.uploadProfilePhoto(filePath);
      _userProfile = _userProfile!.copyWith(photoUrl: photoUrl);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
