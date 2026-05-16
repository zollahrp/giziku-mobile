import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/food_scan_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScannerService {
  final model = GenerativeModel(
    model: 'models/gemini-2.5-flash',

    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',

    generationConfig: GenerationConfig(temperature: 0.2),
  );

  Future<FoodScanModel> scanFood(File image) async {
    final bytes = await image.readAsBytes();

    final prompt = '''
Analyze this food image.

Return ONLY valid JSON.

{
  "foodName": "",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fats": 0,
  "vitamins": {
    "vitaminA": "",
    "vitaminC": "",
    "iron": ""
  },
  "healthScore": 0
}

Estimate realistic nutrition values.
Do not use markdown.
Do not explain anything.
''';

    final response = await model.generateContent([
      Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]),
    ]);

    String text = response.text ?? '';

    // Hapus markdown json kalau ada
    text = text.replaceAll('```json', '');
    text = text.replaceAll('```', '');
    text = text.trim();

    final jsonMap = jsonDecode(text);

    return FoodScanModel.fromJson(jsonMap);
  }
}
