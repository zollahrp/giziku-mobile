import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/food_scan_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScannerService {
  final model = GenerativeModel(
    model: 'models/gemini-3.1-flash-lite',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    generationConfig: GenerationConfig(temperature: 0.2),
  );

  Future<FoodScanModel> scanFood(File image) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      quality: 40,
      minWidth: 512,
      minHeight: 512,
    );

    final bytes = compressed!;
    final prompt = '''
Kamu adalah AI nutritionist profesional.

Analisis makanan dari gambar.

ATURAN:
- Gunakan Bahasa Indonesia.
- Return JSON valid saja.
- Jangan gunakan markdown.
- Jangan tambahkan penjelasan.

FORMAT:

{
  "foodName": "",
  "isEdible": true,
  "estimatedServing": "",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fats": 0,
  "sugars": 0,
  "sodium": 0,
  "fiber": 0,

  "nutritionPerServing": "",

  "vitamins": {
    "vitaminA": "",
    "vitaminC": "",
    "iron": ""
  },

  "healthScore": 0,
  "healthInsight": "",
  "healthyLevel": ""
}

KETENTUAN:
- Estimasi nutrisi harus realistis.
- Jika gambar blur, tetap berikan estimasi terbaik.
- Health score dari 1-10.
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
