class FoodScanModel {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final Map<String, dynamic> vitamins;
  final int healthScore;

  FoodScanModel({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.vitamins,
    required this.healthScore,
  });

  factory FoodScanModel.fromJson(Map<String, dynamic> json) {
    return FoodScanModel(
      foodName: json['foodName'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,
      vitamins: json['vitamins'] ?? {},
      healthScore: json['healthScore'] ?? 0,
    );
  }
}