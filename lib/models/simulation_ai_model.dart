import 'recipe_model.dart';
import 'vitamins_model.dart';

class SimulationAiModel {
  final String summary;

  final int dailyBudget;

  final String nutritionInsight;

  final String tips;

  final List<MealDay> mealPlan;

  SimulationAiModel({
    required this.summary,
    required this.dailyBudget,
    required this.nutritionInsight,
    required this.tips,
    required this.mealPlan,
  });

  factory SimulationAiModel.fromJson(Map<String, dynamic> json) {
    return SimulationAiModel(
      summary: json['summary'] ?? '',

      dailyBudget: json['daily_budget'] ?? 0,

      nutritionInsight: json['nutrition_insight'] ?? '',

      tips: json['tips'] ?? '',

      mealPlan: (json['meal_plan'] as List? ?? [])
          .map((e) => MealDay.fromJson(e))
          .toList(),
    );
  }
}

class MealDay {
  final int day;

  final List<MealItem> meals;

  MealDay({required this.day, required this.meals});

  factory MealDay.fromJson(Map<String, dynamic> json) {
    return MealDay(
      day: json['day'] ?? 0,

      meals: (json['meals'] as List? ?? [])
          .map((e) => MealItem.fromJson(e))
          .toList(),
    );
  }
}

class MealItem {
  final String mealType;

  final String title;

  final String description;

  final int estimatedCalories;

  final int estimatedPrice;

  final int calories;

  final int protein;
  final int carbs;
  final int fats;

  final int sugars;
  final int sodium;
  final int fiber;

  final int healthScore;

  final String healthyLevel;
  final String healthInsight;

  final String nutritionPerServing;

  final VitaminsModel vitamins;

  // TAMBAHAN
  final List<RecipeIngredient> ingredients;

  final List<String> instructions;

  final int prepTime;

  final int cookTime;

  final int totalTime;

  final String imageUrl;

  final String category;

  MealItem({
    required this.mealType,
    required this.title,
    required this.description,
    required this.estimatedCalories,
    required this.estimatedPrice,
    required this.calories,

    required this.protein,
    required this.carbs,
    required this.fats,

    required this.sugars,
    required this.sodium,
    required this.fiber,

    required this.healthScore,

    required this.healthyLevel,
    required this.healthInsight,

    required this.nutritionPerServing,

    required this.vitamins,

    required this.ingredients,
    required this.instructions,

    required this.prepTime,
    required this.cookTime,
    required this.totalTime,

    required this.imageUrl,
    required this.category,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      mealType: json['meal_type'] ?? '',

      title: json['title'] ?? '',

      description: json['description'] ?? '',

      estimatedCalories: json['estimated_calories'] ?? 0,

      estimatedPrice: json['estimated_price'] ?? 0,

      calories: json['calories'] ?? 0,

      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,

      sugars: json['sugars'] ?? 0,
      sodium: json['sodium'] ?? 0,
      fiber: json['fiber'] ?? 0,

      healthScore: json['health_score'] ?? 0,

      healthyLevel: json['healthy_level'] ?? '',

      healthInsight: json['health_insight'] ?? '',

      nutritionPerServing: json['nutrition_per_serving'] ?? '',

      vitamins: VitaminsModel.fromJson(json['vitamins'] ?? {}),

      // TAMBAHAN
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),

      instructions: List<String>.from(json['instructions'] ?? []),

      prepTime: json['prep_time'] ?? 0,

      cookTime: json['cook_time'] ?? 0,

      totalTime: json['total_time'] ?? 0,

      imageUrl: json['image_url'] ?? '',

      category: json['category'] ?? 'Healthy Food',
    );
  }
}
