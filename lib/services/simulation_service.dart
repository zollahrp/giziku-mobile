import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/simulation_ai_model.dart';

class SimulationService {

  final model = GenerativeModel(
    model: 'models/gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    generationConfig: GenerationConfig(
      temperature: 0.4,
    ),
  );

  Future<SimulationAiModel> generateMealPlan({
    required int budget,
    required int days,
    required int people,
  }) async {

    final prompt = '''
Kamu adalah AI nutrition planner profesional.

Buatkan meal plan sehat, hemat, realistis, dan variatif.

DATA USER:
- Budget: Rp$budget
- Durasi: $days hari
- Jumlah orang: $people orang

ATURAN:
- Gunakan Bahasa Indonesia
- Fokus makanan Indonesia
- Budget realistis
- Makanan sederhana dan mudah dibuat
- Variasikan menu setiap hari
- Setiap hari wajib ada:
  - Sarapan
  - Makan Siang
  - Makan Malam
- Hitung estimasi kalori dan harga
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
          "estimated_calories": 0,
          "estimated_price": 0
        },

        {
          "meal_type": "Makan Siang",
          "title": "",
          "description": "",
          "estimated_calories": 0,
          "estimated_price": 0
        },

        {
          "meal_type": "Makan Malam",
          "title": "",
          "description": "",
          "estimated_calories": 0,
          "estimated_price": 0
        }
      ]
    }
  ]
}
''';

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    String text = response.text ?? '';

    text = text.replaceAll('```json', '');
    text = text.replaceAll('```', '');
    text = text.trim();

    print(text);

    final jsonMap = jsonDecode(text);

    return SimulationAiModel.fromJson(
      jsonMap,
    );
  }
}