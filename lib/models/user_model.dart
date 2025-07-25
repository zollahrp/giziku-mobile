enum AuthProvider {
  email,
  google,
}

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
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      phoneNumber: json['phone_number'],
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      age: json['age'],
      gender: json['gender'],
      targetCalories: json['target_calories'],
      dateOfBirth: json['date_of_birth'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
      authProvider: _parseAuthProvider(json['auth_provider'] ?? 'email'),
      token: json['token'],
      refreshToken: json['refresh_token'],
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