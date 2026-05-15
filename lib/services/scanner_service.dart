import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/api_keys.dart';
import '../models/food_scan_model.dart';

class ScannerService {
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: ApiKeys.geminiApiKey,
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
