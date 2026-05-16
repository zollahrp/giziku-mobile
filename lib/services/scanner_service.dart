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
Kamu adalah AI nutritionist dan food analyzer profesional.

Analisis makanan dari gambar ini.

Tugas kamu:
1. Identifikasi nama makanan utama secara spesifik dalam Bahasa Indonesia.
2. Estimasi total nutrisi secara realistis berdasarkan porsi pada gambar.
3. Tentukan apakah makanan masih layak dimakan atau tidak berdasarkan visual.
4. Berikan estimasi per serving/porsi.
5. Gunakan nilai nutrisi realistis seperti aplikasi kesehatan profesional.
6. Jika gambar blur atau makanan tidak jelas, tetap berikan estimasi terbaik.

ATURAN:
- Gunakan Bahasa Indonesia.
- Return HANYA JSON valid.
- Jangan gunakan markdown.
- Jangan jelaskan apapun.
- Jangan tambahkan teks selain JSON.

FORMAT JSON:

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

CONTOH nutritionPerServing:
"Tahu goreng (35Kcal, 2P, 3F, 1C) per potong"

CONTOH healthyLevel:
"Sangat Sehat"
"Cukup Sehat"
"Kurang Sehat"
"Tidak Sehat"

CONTOH healthInsight:
"Makanan tinggi protein namun cukup tinggi minyak."

Health score dari 1-10.
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
