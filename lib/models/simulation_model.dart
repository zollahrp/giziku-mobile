class SimulationRequest {
  final int? userId;
  final int budget;
  final int people;
  final int days;

  SimulationRequest({
    this.userId,
    required this.budget,
    required this.people,
    required this.days,
  });

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user': userId,
      'budget': budget,
      'people': people,
      'days': days,
    };
  }
}

class SimulationResponse {
  final bool success;
  final String message;
  final SimulationResult? data;

  SimulationResponse({required this.success, required this.message, this.data});

  factory SimulationResponse.fromJson(Map<String, dynamic> json) {
    return SimulationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'No message provided',
      data: json['data'] != null
          ? SimulationResult.fromJson(json['data'])
          : null,
    );
  }

  factory SimulationResponse.error(String errorMessage) {
    return SimulationResponse(
      success: false,
      message: errorMessage,
      data: null,
    );
  }
}

class SimulationResult {
  final int id;
  final int budget;
  final int days;
  final int people;
  final List<NutritionRecommendation>? nutritionRecommendations;
  final List<RecipeRecommendation>? recipeRecommendations;
  final DateTime createdAt;

  SimulationResult({
    required this.id,
    required this.budget,
    required this.days,
    required this.people,
    this.nutritionRecommendations,
    this.recipeRecommendations,
    required this.createdAt,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    List<NutritionRecommendation> nutritionList = [];
    if (json['nutrition_recommendations'] != null) {
      nutritionList = List<NutritionRecommendation>.from(
        json['nutrition_recommendations'].map(
          (x) => NutritionRecommendation.fromJson(x),
        ),
      );
    }

    List<RecipeRecommendation> recipeList = [];
    if (json['recipe_recommendations'] != null) {
      recipeList = List<RecipeRecommendation>.from(
        json['recipe_recommendations'].map(
          (x) => RecipeRecommendation.fromJson(x),
        ),
      );
    }

    return SimulationResult(
      id: json['id'],
      budget: json['budget'],
      days: json['days'],
      people: json['people'],
      nutritionRecommendations: nutritionList,
      recipeRecommendations: recipeList,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class NutritionRecommendation {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;

  NutritionRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
  });

  factory NutritionRecommendation.fromJson(Map<String, dynamic> json) {
    return NutritionRecommendation(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      dailyCalories: (json['daily_calories'] ?? 0).toDouble(),
      dailyProtein: (json['daily_protein'] ?? 0).toDouble(),
      dailyCarbs: (json['daily_carbs'] ?? 0).toDouble(),
      dailyFat: (json['daily_fat'] ?? 0).toDouble(),
    );
  }
}

class RecipeRecommendation {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double estimatedCost;

  RecipeRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.estimatedCost,
  });

  factory RecipeRecommendation.fromJson(Map<String, dynamic> json) {
    return RecipeRecommendation(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
    );
  }
}
