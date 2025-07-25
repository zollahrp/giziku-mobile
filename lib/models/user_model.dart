enum AuthProvider { email, google }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final double? height; // in cm
  final double? weight; // in kg
  final int? age;
  final String? gender;
  final int? targetCalories;
  final String? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthProvider authProvider;
  final String? token; // Authentication token
  final String? refreshToken; // Refresh token

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.targetCalories,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.authProvider,
    this.token,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract tokens from response, handling different response formats
    String? accessToken = json['token'] ?? json['access'];
    String? refreshToken = json['refresh_token'] ?? json['refresh'];

    // If we have a nested data structure with user info
    Map<String, dynamic> userData = json;
    if (json.containsKey('data') && json['data'] is Map) {
      userData = Map<String, dynamic>.from(json['data']);
      // Keep tokens from parent JSON if not in userData
      if (!userData.containsKey('token') && !userData.containsKey('access')) {
        userData['token'] = accessToken;
      }
      if (!userData.containsKey('refresh_token') &&
          !userData.containsKey('refresh')) {
        userData['refresh_token'] = refreshToken;
      }
    }

    print('User data being processed: $userData');
    print('Access token: $accessToken');
    print('Refresh token: $refreshToken');

    return UserModel(
      id: userData['id']?.toString() ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      photoUrl: userData['photo_url'],
      phoneNumber: userData['phone_number'],
      height: userData['height'] != null
          ? (userData['height'] as num).toDouble()
          : null,
      weight: userData['weight'] != null
          ? (userData['weight'] as num).toDouble()
          : null,
      age: userData['age'] != null ? (userData['age'] as num).toInt() : null,
      gender: userData['gender'],
      targetCalories: userData['target_calories'] != null
          ? (userData['target_calories'] as num).toInt()
          : null,
      dateOfBirth: userData['date_of_birth'],
      createdAt: userData['created_at'] != null
          ? DateTime.parse(userData['created_at'])
          : DateTime.now(),
      updatedAt: userData['updated_at'] != null
          ? DateTime.parse(userData['updated_at'])
          : DateTime.now(),
      authProvider: _parseAuthProvider(userData['auth_provider'] ?? 'email'),
      token: accessToken,
      refreshToken: refreshToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'target_calories': targetCalories,
      'date_of_birth': dateOfBirth,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'auth_provider': authProvider.toString().split('.').last,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
    };
  }

  static AuthProvider _parseAuthProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'email':
        return AuthProvider.email;
      case 'google':
        return AuthProvider.google;
      default:
        return AuthProvider.email;
    }
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    double? height,
    double? weight,
    int? age,
    String? gender,
    int? targetCalories,
    String? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    AuthProvider? authProvider,
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      targetCalories: targetCalories ?? this.targetCalories,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authProvider: authProvider ?? this.authProvider,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
