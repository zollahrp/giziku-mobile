import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthProvider { email, google }

class UserModel {
  // ================= AUTH =================
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;

  // ================= BASIC INFORMATION =================
  final String? gender;
  final String? dateOfBirth;

  // ================= BODY ANALYSIS =================
  final double? height;
  final double? weight;

  final String? activityLevel;
  final String? exerciseLevel;

  // ================= NUTRITION PREFERENCES =================
  final List<String>? foodType;
  final String? favoriteFoods;
  final String? dislikedFoods;
  final List<String>? allergies;

  // ================= HEALTH =================
  final List<String>? chronicDisease;
  // ================= EATING HABIT & KITCHEN =================
  final String? eatingPattern;
  final String? macroFocus;
  final String? waterIntake;
  final String? cookingSkill;
  final List<String>? kitchenEquipments;
  final String? location;
  final String? role;

  // ================= FITNESS TARGET =================
  final String? bodyGoal;

  // ================= SYSTEM CALCULATED =================
  final int? age;

  final double? bmi;
  final String? bmiCategory;

  final double? idealWeight;

  final int? dailyCalories;

  final int? proteinNeed;
  final int? carbNeed;
  final int? fatNeed;

  final int? sugarLimit;
  final int? sodiumLimit;

  // ================= SYSTEM =================
  final DateTime createdAt;
  final DateTime updatedAt;

  final AuthProvider authProvider;

  // ================= TOKEN =================
  final String? token;
  final String? refreshToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,

    this.photoUrl,
    this.phoneNumber,

    this.gender,
    this.dateOfBirth,

    this.height,
    this.weight,

    this.activityLevel,
    this.exerciseLevel,

    this.foodType,
    this.favoriteFoods,
    this.dislikedFoods,
    this.allergies,

    this.chronicDisease,

    this.eatingPattern,
    this.macroFocus,
    this.waterIntake,
    this.cookingSkill,
    this.kitchenEquipments,
    this.location,
    this.role,

    this.bodyGoal,

    this.age,

    this.bmi,
    this.bmiCategory,

    this.idealWeight,

    this.dailyCalories,

    this.proteinNeed,
    this.carbNeed,
    this.fatNeed,

    this.sugarLimit,
    this.sodiumLimit,

    required this.createdAt,
    required this.updatedAt,

    required this.authProvider,

    this.token,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    List<String> parseFoodTypes(dynamic ft, dynamic dtList, dynamic dtStr) {
      if (ft is List) return List<String>.from(ft.map((e) => e.toString()));
      if (dtList is List) return List<String>.from(dtList.map((e) => e.toString()));
      if (dtStr is String && dtStr.isNotEmpty) return [dtStr];
      return [];
    }

    List<String> parseDiseases(dynamic cd, dynamic cdCamel, dynamic mh) {
      if (cd is List) return List<String>.from(cd.map((e) => e.toString()));
      if (cdCamel is List) return List<String>.from(cdCamel.map((e) => e.toString()));
      if (mh is String && mh.isNotEmpty) return [mh];
      return [];
    }

    final macros = json['macros'] is Map ? (json['macros'] as Map) : null;
    final carb = parseInt(json['carb_need'] ?? json['carbNeed'] ?? macros?['car']);
    final fat = parseInt(json['fat_need'] ?? json['fatNeed'] ?? macros?['fat']);
    final protein = parseInt(json['protein_need'] ?? json['proteinNeed'] ?? macros?['pro']);

    return UserModel(
      // ================= AUTH =================
      id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      email: json['email'] ?? '',

      photoUrl: json['photo_url'] ?? json['photoURL'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],

      // ================= BASIC =================
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] ?? json['birthDate'] ?? json['dateOfBirth'],

      // ================= BODY =================
      height: parseDouble(json['height']),
      weight: parseDouble(json['weight']),

      activityLevel: json['activity_level'] ?? json['activity'] ?? json['activityLevel'],
      exerciseLevel: json['exercise_level'] ?? json['exercise'] ?? json['exerciseLevel'],

      // ================= FOOD =================
      foodType: parseFoodTypes(json['food_type'], json['dietTypes'], json['dietType']),
      favoriteFoods: json['favorite_foods'] ?? json['favoriteFoods'],
      dislikedFoods: json['disliked_foods'] ?? json['dislikedFoods'],
      allergies: json['allergies'] != null
          ? List<String>.from((json['allergies'] as List).map((e) => e.toString()))
          : [],
      // ================= HEALTH =================
      chronicDisease: parseDiseases(json['chronic_disease'], json['chronicDisease'], json['medicalHistory']),
      // ================= HABIT =================
      eatingPattern: json['eating_pattern'] ?? json['eatingPattern'] ?? json['mealsPerDay'],
      macroFocus: json['macroFocus'] ?? json['macro_focus'],
      waterIntake: json['waterIntake'] ?? json['water_intake'],
      cookingSkill: json['cookingSkill'] ?? json['cooking_skill'],
      kitchenEquipments: json['kitchenEquipments'] is List
          ? List<String>.from(json['kitchenEquipments'])
          : (json['kitchen_equipments'] is List
              ? List<String>.from(json['kitchen_equipments'])
              : null),
      location: json['location'],
      role: json['role'] ?? 'BASIC',

      // ================= GOAL =================
      bodyGoal: json['body_goal'] ?? json['bodyGoal'],

      // ================= SYSTEM =================
      age: parseInt(json['age']),

      bmi: parseDouble(json['bmi']),

      bmiCategory: json['bmi_category'] ?? json['bmiStatus'] ?? json['bmiCategory'],

      idealWeight: parseDouble(json['ideal_weight'] ?? json['idealWeight']),

      dailyCalories: parseInt(json['daily_calories'] ?? json['calories'] ?? json['dailyCalories']),

      proteinNeed: protein,
      carbNeed: carb,
      fatNeed: fat,

      sugarLimit: parseInt(json['sugar_limit'] ?? json['sugarLimit']),
      sodiumLimit: parseInt(json['sodium_limit'] ?? json['sodiumLimit']),

      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),

      authProvider: _parseAuthProvider(json['auth_provider'] ?? 'email'),

      token: json['token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ================= AUTH =================
      'id': id,
      'uid': id,
      'name': name,
      'email': email,

      'photo_url': photoUrl,
      'photoURL': photoUrl,
      'phone_number': phoneNumber,

      // ================= BASIC =================
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'birthDate': dateOfBirth,

      // ================= BODY =================
      'height': height != null ? (height! % 1 == 0 ? height!.toInt().toString() : height!.toString()) : null,
      'weight': weight != null ? (weight! % 1 == 0 ? weight!.toInt().toString() : weight!.toString()) : null,

      'activity_level': activityLevel,
      'activity': activityLevel,
      'exercise_level': exerciseLevel,
      'exercise': exerciseLevel,

      // ================= FOOD =================
      'food_type': foodType,
      'dietTypes': foodType,
      'dietType': (foodType != null && foodType!.isNotEmpty) ? foodType!.first : null,
      'favorite_foods': favoriteFoods,
      'favoriteFoods': favoriteFoods,
      'disliked_foods': dislikedFoods,
      'dislikedFoods': dislikedFoods,
      'allergies': allergies,

      // ================= HEALTH =================
      'chronic_disease': chronicDisease,
      'medicalHistory': (chronicDisease != null && chronicDisease!.isNotEmpty) ? chronicDisease!.first : null,

      // ================= HABIT =================
      'eating_pattern': eatingPattern,
      'mealsPerDay': eatingPattern,
      'macroFocus': macroFocus,
      'waterIntake': waterIntake,
      'cookingSkill': cookingSkill,
      'kitchenEquipments': kitchenEquipments,
      'location': location,
      'role': role,

      // ================= GOAL =================
      'body_goal': bodyGoal,
      'bodyGoal': bodyGoal,

      // ================= SYSTEM =================
      'age': age,

      'bmi': bmi?.toString(),
      'bmi_category': bmiCategory,
      'bmiStatus': bmiCategory,

      'ideal_weight': idealWeight?.toString(),
      'idealWeight': idealWeight?.toString(),

      'daily_calories': dailyCalories,
      'calories': dailyCalories?.toString(),

      'protein_need': proteinNeed,
      'carb_need': carbNeed,
      'fat_need': fatNeed,

      'macros': {
        'car': carbNeed ?? 0,
        'fat': fatNeed ?? 0,
        'pro': proteinNeed ?? 0,
      },

      'sugar_limit': sugarLimit,
      'sodium_limit': sodiumLimit,

      // ================= SYSTEM =================
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),

      'auth_provider': authProvider.toString().split('.').last,

      // ================= TOKEN =================
      'token': token,
      'refresh_token': refreshToken,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static AuthProvider _parseAuthProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return AuthProvider.google;

      case 'email':
      default:
        return AuthProvider.email;
    }
  }
}
