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

  factory SimulationAiModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return SimulationAiModel(

      summary:
          json['summary'] ?? '',

      dailyBudget:
          json['daily_budget'] ?? 0,

      nutritionInsight:
          json['nutrition_insight'] ?? '',

      tips:
          json['tips'] ?? '',

      mealPlan:
          (json['meal_plan'] as List? ?? [])
              .map(
                (e) => MealDay.fromJson(e),
              )
              .toList(),
    );
  }
}

class MealDay {

  final int day;

  final List<MealItem> meals;

  MealDay({
    required this.day,
    required this.meals,
  });

  factory MealDay.fromJson(
    Map<String, dynamic> json,
  ) {

    return MealDay(

      day:
          json['day'] ?? 0,

      meals:
          (json['meals'] as List? ?? [])
              .map(
                (e) => MealItem.fromJson(e),
              )
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

  MealItem({
    required this.mealType,
    required this.title,
    required this.description,
    required this.estimatedCalories,
    required this.estimatedPrice,
  });

  factory MealItem.fromJson(
    Map<String, dynamic> json,
  ) {

    return MealItem(

      mealType:
          json['meal_type'] ?? '',

      title:
          json['title'] ?? '',

      description:
          json['description'] ?? '',

      estimatedCalories:
          json['estimated_calories'] ?? 0,

      estimatedPrice:
          json['estimated_price'] ?? 0,
    );
  }
}