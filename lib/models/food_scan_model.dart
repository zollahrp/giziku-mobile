class FoodScanModel {
  final String foodName;
  final bool isEdible;
  final String estimatedServing;

  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  final int sugars;
  final int sodium;
  final int fiber;

  final String nutritionPerServing;

  final VitaminsModel vitamins;

  final int healthScore;

  final String healthInsight;
  final String healthyLevel;

  FoodScanModel({
    required this.foodName,
    required this.isEdible,
    required this.estimatedServing,

    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,

    required this.sugars,
    required this.sodium,
    required this.fiber,

    required this.nutritionPerServing,

    required this.vitamins,

    required this.healthScore,

    required this.healthInsight,
    required this.healthyLevel,
  });

  factory FoodScanModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FoodScanModel(
      foodName: json['foodName'] ?? '',

      isEdible: json['isEdible'] ?? true,

      estimatedServing:
          json['estimatedServing'] ?? '',

      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,

      sugars: json['sugars'] ?? 0,
      sodium: json['sodium'] ?? 0,
      fiber: json['fiber'] ?? 0,

      nutritionPerServing:
          json['nutritionPerServing'] ?? '',

      vitamins: VitaminsModel.fromJson(
        json['vitamins'] ?? {},
      ),

      healthScore: json['healthScore'] ?? 0,

      healthInsight:
          json['healthInsight'] ?? '',

      healthyLevel:
          json['healthyLevel'] ?? '',
    );
  }
}

class VitaminsModel {
  final String vitaminA;
  final String vitaminC;
  final String iron;

  VitaminsModel({
    required this.vitaminA,
    required this.vitaminC,
    required this.iron,
  });

  factory VitaminsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VitaminsModel(
      vitaminA: json['vitaminA'] ?? '',
      vitaminC: json['vitaminC'] ?? '',
      iron: json['iron'] ?? '',
    );
  }
}