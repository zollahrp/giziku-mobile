class RecipeModel {
  final String? id;
  final String title;
  final String imageUrl;
  final String category;
  final int price;
  final int nutrition; 
  final String nutritionUnit; 
  final int prepTime; 
  final int cookTime; 
  final int totalTime; 
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  RecipeModel({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.nutrition,
    required this.nutritionUnit,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      category: json['category'],
      price: json['price'],
      nutrition: json['nutrition'],
      nutritionUnit: json['nutrition_unit'] ?? "g",
      prepTime: json['prep_time'],
      cookTime: json['cook_time'],
      totalTime: json['total_time'],
      description: json['description'],
      ingredients: (json['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),
      instructions: List<String>.from(json['instructions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'category': category,
      'price': price,
      'nutrition': nutrition,
      'nutrition_unit': nutritionUnit,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime,
      'description': description,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions,
    };
  }
}

class RecipeIngredient {
  final String name;
  final String amount;

  RecipeIngredient({
    required this.name,
    required this.amount,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}