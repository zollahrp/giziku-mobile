import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/simulation_ai_model.dart';

class SimulationService {
  final model = GenerativeModel(
    model: 'models/gemini-3.1-flash-lite',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    generationConfig: GenerationConfig(temperature: 0.4),
  );

  Future<SimulationAiModel> generateMealPlan({
    required int budget,
    required int days,
    required int people,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data() ?? {};

    final allergies = List<String>.from(userData['allergies'] ?? []);

    final favoriteFoods = userData['favorite_foods'] ?? '';

    final dislikedFoods = userData['disliked_foods'] ?? '';

    final bodyGoal = userData['body_goal'] ?? '';

    final calories = userData['daily_calories'] ?? 2000;

    final diseases = List<String>.from(userData['chronic_disease'] ?? []);

    final foodTypes = List<String>.from(userData['food_type'] ?? []);

    final prompt =
        '''
Kamu adalah AI nutrition planner profesional.

Buatkan meal plan sehat, hemat, realistis, variatif, dan sesuai profil user.

DATA USER:
- Budget: Rp$budget
- Durasi: $days hari
- Jumlah orang: $people orang

PROFILE USER::
- Target tubuh: $bodyGoal
- Kebutuhan kalori: $calories kcal
- Alergi: ${allergies.join(', ')}
- Makanan favorit: $favoriteFoods
- Makanan tidak disukai: $dislikedFoods
- Riwayat penyakit: ${diseases.join(', ')}
- Preferensi makanan: ${foodTypes.join(', ')}

ATURAN:
- Gunakan Bahasa Indonesia
- Fokus makanan Indonesia
- Budget realistis
- Makanan sederhana dan mudah dibuat
- Variasikan menu setiap hari
- Berikan resep lengkap untuk setiap menu

- Jangan gunakan makanan yang mengandung alergi user
- Hindari makanan yang tidak disukai
- Prioritaskan makanan favorit jika memungkinkan
- Sesuaikan menu dengan target tubuh user
- Sesuaikan menu dengan kondisi kesehatan user

- Gunakan estimasi nutrisi realistis seperti aplikasi kesehatan profesional
- health_score wajib 1-10
- healthy_level wajib:
  "Sangat Sehat"
  "Cukup Sehat"
  "Kurang Sehat"
  "Tidak Sehat"

- nutrition_per_serving wajib format seperti:
  "Ayam bakar (220Kcal, 18P, 12F, 8C) per porsi"

- vitamins wajib berisi:
  vitaminA
  vitaminC
  iron

- Setiap hari wajib ada:
  - Sarapan
  - Makan Siang
  - Makan Malam

- Hitung estimasi kalori
- Hitung estimasi harga

- ingredients wajib berupa array
- instructions wajib berupa array
- prep_time, cook_time, total_time wajib integer


- Return HANYA JSON valid
- Jangan gunakan markdown
- Jangan tambahkan teks selain JSON

FORMAT JSON:
{
  "summary": "",
  "daily_budget": 0,
  "nutrition_insight": "",
  "tips": "",

  "meal_plan": [
    {
      "day": 1,

      "meals": [
        {
  "meal_type": "Sarapan",

  "title": "",

  "description": "",

  "category": "",

  "image_url": "",

  "estimated_calories": 0,

  "estimated_price": 0,

  "prep_time": 0,

  "cook_time": 0,

  "total_time": 0,

  "health_score": 0,

  "healthy_level": "",

  "health_insight": "",

  "nutrition_per_serving": "",

  "protein": 0,

  "carbs": 0,

  "fats": 0,

  "sugars": 0,

  "sodium": 0,

  "fiber": 0,

  "vitamins": {
    "vitaminA": "",
    "vitaminC": "",
    "iron": ""
  },

  "ingredients": [
    {
      "name": "",
      "amount": ""
    }
  ],

  "instructions": [
    "",
    ""
  ]
}
      ]
    }
  ]
}
''';

    final response = await model.generateContent([Content.text(prompt)]);

    String text = response.text ?? '';

    text = text.replaceAll('```json', '');
    text = text.replaceAll('```', '');
    text = text.trim();

    print(text);

    final jsonMap = jsonDecode(text);

    return SimulationAiModel.fromJson(jsonMap);
  }
}
