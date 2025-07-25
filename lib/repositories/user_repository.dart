import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserRepository {
  final String apiUrl;

  UserRepository({required this.apiUrl});

  Future<UserModel> fetchUserProfile() async {
    final response = await http.get(Uri.parse('$apiUrl/profile'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to load user profile');
    }
  }
}