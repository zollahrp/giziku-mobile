import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

class RecipeRepository {
  final String baseUrl;

  RecipeRepository({required this.baseUrl});

  Future<List<RecipeModel>> getAllRecipes() async {
    final response = await http.get(Uri.parse('$baseUrl/recipes'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RecipeModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<RecipeModel> getRecipeDetail(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/$id'));
    if (response.statusCode == 200) {
      return RecipeModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load recipe');
    }
  }
}