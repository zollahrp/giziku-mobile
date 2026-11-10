import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/food_scan_model.dart';
import '../models/vitamins_model.dart';

class ScannerService {
  final dio = Dio();

  GenerativeModel get _geminiModel => GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    generationConfig: GenerationConfig(
      temperature: 0.2,
      responseMimeType: 'application/json',
    ),
  );

  /// ==========================================================
  /// 1. GIZIFY VISION PLATE SCANNER (Web-Aligned Prompt & Format)
  /// ==========================================================
  Future<FoodPlateScanResult> scanFoodPlate(
    File image, {
    String bodyGoal = "Menjaga Berat Badan",
  }) async {
    // Compress image to optimize upload speed and Gemini processing
    Uint8List? compressed;
    try {
      compressed = await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
    } catch (_) {
      compressed = await image.readAsBytes();
    }

    final bytes = compressed ?? await image.readAsBytes();

    final prompt = '''
Kamu adalah 'Gizify Vision', AI Computer Vision dan Ahli Gizi Klinis. Analisa piring makanan ini dengan presisi tinggi dan sains nutrisi yang realistis.
Deteksi SETIAP KOMPONEN MAKANAN secara terpisah. Untuk setiap item, berikan 'box' berupa array [ymin, xmin, ymax, xmax] dengan nilai persentase 0-1000. Lengkapi nutrisinya (Makro & Mikro). Untuk 'portion', berikan estimasi gram dan takaran (misal: '200g (1 piring sedang)'). 

ATURAN KRUSIAL: KALIBRASI PROTEIN & PORSI NYATA (JANGAN MELEBIH-LEBIHKAN PROTEIN):
Pengguna sangat memperhatikan akurasi protein dan mengeluh jika protein dilebih-lebihkan! Kamu WAJIB mengkalibrasi protein secara ketat sesuai data Tabel Komposisi Pangan Indonesia (TKPI) & standar nutrisi klinis:
- 1 butir telur ayam ras utuh (ceplok, dadar, atau rebus ~50-60g): HANYA mengandung 6g sampai 7g protein (BUKAN 15g atau 20g!).
- Nasi putih / nasi uduk / nasi goreng (1 piring sedang ~150-200g): HANYA mengandung 3g sampai 4g protein.
- Ayam suwir topping / taburan sedikit (10g - 25g): HANYA mengandung 3g sampai 6g protein! Daging ayam matang kadar proteinnya hanya sekitar 28-30% dari beratnya (15g ayam suwir = maksimal 4.5g protein). JANGAN samakan suwiran sedikit dengan 1 potong dada ayam utuh 100g!
- Dada ayam matang utuh (100g daging murni): baru mengandung ~30g protein.
- Paha ayam 1 potong sedang (dengan tulang): ~14g - 18g protein.
- Tahu 1 potong sedang (50g): ~4g protein.
- Tempe 1 potong sedang (50g): ~7g - 8g protein.
- Daging sapi 1 potong sedang (50g): ~11g - 13g protein.
- Udang kecil (5-6 ekor): ~7g protein.
- Kerupuk / Sambal / Minyak / Lalapan / Acar: protein mendekati 0g (0 - 1g).
CONTOH KALIBRASI NYATA: Nasi Goreng 1 piring dengan 1 butir telur + suwiran ayam sedikit total protein aslinya HANYA ~13g s/d 14.5g, SAMA SEKALI BUKAN 25g - 35g!

KONSISTENSI MATEMATIS TOTAL:
Nilai pada objek 'total' (calories, protein, carbs, fat) HARUS MERUPAKAN PENJUMLAHAN TEPAT (SUM) dari seluruh 'items' yang ada di piring. total.protein = sum(items.protein).

Target kesehatan user saat ini adalah: "$bodyGoal". 
Berdasarkan target tersebut, berikan 'ai_insight' di bagian 'total'. ATURAN BAHASA 'ai_insight': Gunakan bahasa Indonesia yang profesional, sopan, edukatif, dan obyektif. Gunakan sapaan "Anda". Berikan analisis nutrisi yang jelas dan terstruktur namun tetap memberikan dorongan positif. JANGAN gunakan bahasa gaul, santai, humor berlebihan, atau kata-kata informal (seperti 'nggak nyangka', 'banget', 'sih', 'nih'). Contoh: "Hidangan nasi goreng telur ini menyediakan energi yang cukup, dengan protein sekitar 14.5g dari telur dan suwiran ayam. Menambahkan sayuran hijau akan sangat membantu mengoptimalkan serat harian Anda."

Jika BUKAN makanan, kosongkan items [] dan beri kalori 0. 

Untuk 'name' pada objek 'total', berikan NAMA HIDANGAN DENGAN GAYA RESTORAN PROFESIONAL DAN AESTHETIC (misal: "Nasi Goreng Telur Gurih dengan Suwiran Ayam & Lalapan"). JANGAN gunakan kata-kata murah/warteg/generik seperti "Menu Lengkap", "Paket", "Komplit", atau "Hidangan". Gabungkan komponen utama dengan kata sambung "dengan" atau "&".

KEMBALIKAN HANYA DALAM FORMAT JSON VALID DENGAN STRUKTUR: 
{
  "items": [
    {"name": "Nasi Goreng", "box": [300, 200, 750, 700], "portion": "200g (1 piring sedang)", "calories": 330, "protein": 4.0, "carbs": 48.0, "fat": 13.0, "micronutrients": {"vitC": "0mg", "fiber": "1.5g", "calcium": "12mg", "iron": "1.2mg"}},
    {"name": "Telur Ceplok", "box": [350, 400, 600, 650], "portion": "55g (1 butir)", "calories": 90, "protein": 6.5, "carbs": 0.5, "fat": 7.0, "micronutrients": {"vitC": "0mg", "fiber": "0g", "calcium": "28mg", "iron": "0.9mg"}},
    {"name": "Ayam Suwir Taburan", "box": [400, 300, 550, 450], "portion": "15g (taburan topping)", "calories": 25, "protein": 4.0, "carbs": 0.0, "fat": 0.8, "micronutrients": {"vitC": "0mg", "fiber": "0g", "calcium": "2mg", "iron": "0.2mg"}}
  ],
  "total": {
    "name": "Nasi Goreng Telur dengan Suwiran Ayam Gurih",
    "portion": "1 Piring Penuh (± 270g)",
    "calories": 445,
    "protein": 14.5,
    "carbs": 48.5,
    "fat": 20.8,
    "score": 8,
    "micronutrients": {"vitC": "0mg", "fiber": "1.5g", "calcium": "42mg", "iron": "2.3mg"},
    "ai_insight": "Komposisi nutrisi pada hidangan ini menyediakan energi yang memadai dengan protein sekitar 14.5g dari telur dan suwiran ayam. Untuk target $bodyGoal, Anda dapat menambahkan lalapan segar atau tumis sayuran guna meningkatkan asupan serat harian."
  }
}
''';

    try {
      final response = await _geminiModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      String text = response.text ?? '';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();

      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return FoodPlateScanResult.fromJson(jsonMap);
    } catch (e) {
      // Fallback: try raw HTTP API if SDK throws model lookup errors
      return await _scanFoodPlateHttp(bytes, bodyGoal);
    }
  }

  Future<FoodPlateScanResult> _scanFoodPlateHttp(Uint8List bytes, String bodyGoal) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final prompt = '''
Kamu adalah 'Gizify Vision', AI Computer Vision dan Ahli Gizi Klinis. Analisa piring makanan ini dengan presisi tinggi dan sains nutrisi yang realistis.
Deteksi SETIAP KOMPONEN MAKANAN secara terpisah. Untuk setiap item, berikan 'box' berupa array [ymin, xmin, ymax, xmax] dengan nilai persentase 0-1000. Lengkapi nutrisinya (Makro & Mikro). Untuk 'portion', berikan estimasi gram dan takaran (misal: '200g (1 piring sedang)').

KEMBALIKAN HANYA DALAM FORMAT JSON VALID DENGAN STRUKTUR:
{
  "items": [
    {"name": "Nasi Goreng", "box": [300, 200, 750, 700], "portion": "200g", "calories": 330, "protein": 4.0, "carbs": 48.0, "fat": 13.0, "micronutrients": {"vitC": "0mg", "fiber": "1.5g", "calcium": "12mg", "iron": "1.2mg"}}
  ],
  "total": {
    "name": "Nasi Goreng",
    "portion": "1 Piring",
    "calories": 330,
    "protein": 4.0,
    "carbs": 48.0,
    "fat": 13.0,
    "score": 8,
    "micronutrients": {"vitC": "0mg", "fiber": "1.5g", "calcium": "12mg", "iron": "1.2mg"},
    "ai_insight": "Menu seimbang untuk $bodyGoal."
  }
}
''';

    final base64Image = base64Encode(bytes);
    final response = await dio.post(
      url,
      data: {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "temperature": 0.2,
        }
      },
    );

    final candidates = response.data['candidates'] as List;
    final textResult = candidates[0]['content']['parts'][0]['text'] as String;
    final cleanJson = textResult.replaceAll('```json', '').replaceAll('```', '').trim();
    final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
    return FoodPlateScanResult.fromJson(jsonMap);
  }

  /// ==========================================================
  /// 2. AI AUTO-FILL MANUAL NUTRITION (Web-Aligned Prompt)
  /// ==========================================================
  Future<ManualNutritionResult> autoGenerateManualNutrition(String foodName) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final prompt = '''
Berikan estimasi kandungan gizi dasar (per 100 gram) untuk makanan/minuman berikut: "$foodName". 
Balas HANYA dengan format JSON yang valid, tanpa markdown tambahan, tanpa penjelasan. 
Gunakan key berikut dan isi HANYA dengan angka (tanpa satuan, jika tidak tahu isi "0"): 
{ "baseCalories": "...", "basePro": "...", "baseCar": "...", "baseFat": "...", "baseVitC": "...", "baseFiber": "...", "baseCalcium": "...", "baseIron": "..." }
''';

    try {
      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);

      String text = response.text ?? '';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return ManualNutritionResult.fromJson(jsonMap);
    } catch (_) {
      // Fallback via direct HTTP
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

      final response = await dio.post(
        url,
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.2,
          }
        },
      );

      final candidates = response.data['candidates'] as List;
      final textResult = candidates[0]['content']['parts'][0]['text'] as String;
      final cleanJson = textResult.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
      return ManualNutritionResult.fromJson(jsonMap);
    }
  }

  /// ==========================================================
  /// 3. LEGACY SINGLE FOOD SCAN (Retained for compatibility)
  /// ==========================================================
  Future<FoodScanModel> scanFood(File image) async {
    final plateResult = await scanFoodPlate(image);
    return FoodScanModel(
      foodName: plateResult.total.name,
      isEdible: plateResult.isFoodItem,
      estimatedServing: plateResult.total.portion,
      calories: plateResult.total.calories,
      protein: plateResult.total.protein.round(),
      carbs: plateResult.total.carbs.round(),
      fats: plateResult.total.fat.round(),
      sugars: 0,
      sodium: 0,
      fiber: (num.tryParse(plateResult.total.micronutrients.fiber.replaceAll('g', '')) ?? 0).round(),
      nutritionPerServing: plateResult.total.portion,
      vitamins: VitaminsModel(
        vitaminA: '',
        vitaminC: plateResult.total.micronutrients.vitC,
        iron: plateResult.total.micronutrients.iron,
      ),
      healthScore: plateResult.total.score,
      healthInsight: plateResult.total.aiInsight,
      healthyLevel: plateResult.total.score >= 7 ? 'Sehat' : 'Cukup Sehat',
      fromPredict: false,
    );
  }
}
