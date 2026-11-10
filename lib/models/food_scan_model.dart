import 'vitamins_model.dart';

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
  final bool fromPredict;

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
    this.fromPredict = false,
  });

  factory FoodScanModel.fromJson(Map<String, dynamic> json) {
    return FoodScanModel(
      foodName: json['foodName'] ?? '',
      isEdible: json['isEdible'] ?? true,
      estimatedServing: json['estimatedServing'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fats: json['fats'] ?? 0,
      sugars: json['sugars'] ?? 0,
      sodium: json['sodium'] ?? 0,
      fiber: json['fiber'] ?? 0,
      nutritionPerServing: json['nutritionPerServing'] ?? '',
      vitamins: VitaminsModel.fromJson(json['vitamins'] ?? {}),
      healthScore: json['healthScore'] ?? 0,
      healthInsight: json['healthInsight'] ?? '',
      healthyLevel: json['healthyLevel'] ?? '',
      fromPredict: json['fromPredict'] ?? false,
    );
  }
}

/// ====================================================
/// GIZIFY VISION PLATE & MANUAL MODELS (Web-Aligned)
/// ====================================================

class FoodMicronutrients {
  final String vitC;
  final String fiber;
  final String calcium;
  final String iron;

  const FoodMicronutrients({
    this.vitC = "0mg",
    this.fiber = "0g",
    this.calcium = "0mg",
    this.iron = "0mg",
  });

  factory FoodMicronutrients.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FoodMicronutrients();
    return FoodMicronutrients(
      vitC: json['vitC']?.toString() ?? "0mg",
      fiber: json['fiber']?.toString() ?? "0g",
      calcium: json['calcium']?.toString() ?? "0mg",
      iron: json['iron']?.toString() ?? "0mg",
    );
  }

  Map<String, dynamic> toJson() => {
    'vitC': vitC,
    'fiber': fiber,
    'calcium': calcium,
    'iron': iron,
  };
}

class FoodPlateItem {
  String name;
  List<int> box; // [ymin, xmin, ymax, xmax] 0-1000
  String portion;
  int calories;
  double protein;
  double carbs;
  double fat;
  FoodMicronutrients micronutrients;

  FoodPlateItem({
    required this.name,
    required this.box,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.micronutrients,
  });

  factory FoodPlateItem.fromJson(Map<String, dynamic> json) {
    List<int> parsedBox = [0, 0, 0, 0];
    if (json['box'] is List) {
      parsedBox = (json['box'] as List).map((e) => (num.tryParse(e.toString()) ?? 0).toInt()).toList();
      while (parsedBox.length < 4) {
        parsedBox.add(0);
      }
    }

    return FoodPlateItem(
      name: json['name']?.toString() ?? 'Komponen Makanan',
      box: parsedBox,
      portion: json['portion']?.toString() ?? '1 porsi',
      calories: (num.tryParse(json['calories']?.toString() ?? '0') ?? 0).toInt(),
      protein: (num.tryParse(json['protein']?.toString() ?? '0') ?? 0).toDouble(),
      carbs: (num.tryParse(json['carbs']?.toString() ?? '0') ?? 0).toDouble(),
      fat: (num.tryParse(json['fat']?.toString() ?? '0') ?? 0).toDouble(),
      micronutrients: FoodMicronutrients.fromJson(json['micronutrients'] as Map<String, dynamic>?),
    );
  }
}

class FoodPlateTotal {
  String name;
  String portion;
  int calories;
  double protein;
  double carbs;
  double fat;
  int score;
  FoodMicronutrients micronutrients;
  String aiInsight;

  FoodPlateTotal({
    required this.name,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.score = 8,
    required this.micronutrients,
    this.aiInsight = '',
  });

  factory FoodPlateTotal.fromJson(Map<String, dynamic> json) {
    return FoodPlateTotal(
      name: json['name']?.toString() ?? 'Menu Piring',
      portion: json['portion']?.toString() ?? '1 Porsi',
      calories: (num.tryParse(json['calories']?.toString() ?? '0') ?? 0).toInt(),
      protein: (num.tryParse(json['protein']?.toString() ?? '0') ?? 0).toDouble(),
      carbs: (num.tryParse(json['carbs']?.toString() ?? '0') ?? 0).toDouble(),
      fat: (num.tryParse(json['fat']?.toString() ?? '0') ?? 0).toDouble(),
      score: (num.tryParse(json['score']?.toString() ?? '8') ?? 8).toInt(),
      micronutrients: FoodMicronutrients.fromJson(json['micronutrients'] as Map<String, dynamic>?),
      aiInsight: json['ai_insight']?.toString() ?? json['aiInsight']?.toString() ?? '',
    );
  }
}

class FoodPlateScanResult {
  final List<FoodPlateItem> items;
  final FoodPlateTotal total;
  final bool isFoodItem;

  FoodPlateScanResult({
    required this.items,
    required this.total,
    this.isFoodItem = true,
  });

  factory FoodPlateScanResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems.map((e) => FoodPlateItem.fromJson(e as Map<String, dynamic>)).toList();
    final totalObj = FoodPlateTotal.fromJson(json['total'] as Map<String, dynamic>? ?? {});

    final isFood = totalObj.calories > 0 || itemsList.isNotEmpty;

    return FoodPlateScanResult(
      items: itemsList,
      total: totalObj,
      isFoodItem: isFood,
    );
  }
}

class ManualNutritionResult {
  final String baseCalories;
  final String basePro;
  final String baseCar;
  final String baseFat;
  final String baseVitC;
  final String baseFiber;
  final String baseCalcium;
  final String baseIron;

  ManualNutritionResult({
    this.baseCalories = "",
    this.basePro = "",
    this.baseCar = "",
    this.baseFat = "",
    this.baseVitC = "",
    this.baseFiber = "",
    this.baseCalcium = "",
    this.baseIron = "",
  });

  factory ManualNutritionResult.fromJson(Map<String, dynamic> json) {
    return ManualNutritionResult(
      baseCalories: json['baseCalories']?.toString() ?? "",
      basePro: json['basePro']?.toString() ?? "",
      baseCar: json['baseCar']?.toString() ?? "",
      baseFat: json['baseFat']?.toString() ?? "",
      baseVitC: json['baseVitC']?.toString() ?? "",
      baseFiber: json['baseFiber']?.toString() ?? "",
      baseCalcium: json['baseCalcium']?.toString() ?? "",
      baseIron: json['baseIron']?.toString() ?? "",
    );
  }
}
