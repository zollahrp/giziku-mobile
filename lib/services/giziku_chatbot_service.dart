import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GizikuChatbotService {
  final model = GenerativeModel(
    model: 'models/gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    generationConfig: GenerationConfig(temperature: 0.5),
  );

  final user = FirebaseAuth.instance.currentUser;

  Future<String> sendMessage(String userMessage) async {
    try {
      // ================= USER PROFILE =================

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // ================= DAILY NUTRITION =================

      final nutritionSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('daily_nutrition')
          .limit(30)
          .get();

      final nutritionHistory = nutritionSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          "date": doc.id,
          "calories": data['calories'] ?? 0,
          "protein": data['protein'] ?? 0,
          "carbs": data['carbs'] ?? 0,
          "fats": data['fats'] ?? 0,
          "updated_at": data['updated_at'] != null
              ? (data['updated_at'] as Timestamp).toDate().toIso8601String()
              : null,
        };
      }).toList();

      // ================= PROFILE DATA =================

      final profileData = {
        "name": userData['name'] ?? '',
        "age": userData['age'] ?? 0,
        "gender": userData['gender'] ?? '',
        "weight": userData['weight'] ?? 0,
        "height": userData['height'] ?? 0,
        "daily_calories": userData['daily_calories'] ?? 2000,
        "body_goal": userData['body_goal'] ?? '',
        "activity_level": userData['activity_level'] ?? '',
        "allergies": userData['allergies'] ?? [],
        "chronic_disease": userData['chronic_disease'] ?? [],
      };

      // ================= CONVERT JSON =================

      final nutritionJson = jsonEncode(nutritionHistory);

      final profileJson = jsonEncode(profileData);

      // ================= AI PROMPT =================

      final prompt =
          """
Kamu adalah GiziBot, AI nutrition assistant modern milik aplikasi Giziku.

PERSONALITY:
- Professional
- Smart
- Modern
- Friendly
- Calm
- Natural seperti AI assistant modern
- Jangan terlalu formal
- Jangan terlalu kaku
- Jangan terlalu banyak emoji
- Gunakan Bahasa Indonesia modern
- Jawaban harus clean dan enak dibaca

STYLE JAWABAN:
- Singkat tapi insightful
- Gunakan formatting yang rapi
- Boleh gunakan bullet point seperlunya
- Jangan terlalu panjang kecuali diminta
- Jangan terdengar seperti robot lama

KAMU HANYA BOLEH MENJAWAB:
- nutrisi
- kalori
- protein
- carbs
- fats
- pola makan
- meal tracking
- progress nutrisi
- insight kesehatan
- konsumsi harian
- konsumsi mingguan
- perbandingan target kalori
- analisis nutrisi
- rekomendasi makanan sehat
- evaluasi pola makan
- diet
- bulking
- cutting

JIKA DI LUAR TOPIK:
Jawab dengan sopan bahwa kamu hanya fokus pada nutrisi dan kesehatan pengguna di aplikasi Giziku.

ATURAN PENTING:
- Gunakan data user asli
- Jangan mengarang data
- Jika data tidak ada, bilang data belum tersedia
- Boleh menghitung total mingguan atau rata-rata
- Boleh memberi insight berdasarkan pola makan user
- Fokus pada data nutrisi yang tersedia

PROFILE USER:
$profileJson

DATA DAILY NUTRITION USER:
$nutritionJson

PERTANYAAN USER:
$userMessage
""";

      // ================= GENERATE AI =================

      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text;

      if (text == null || text.isEmpty) {
        return "Maaf, saya gagal menganalisis data nutrisi Anda.";
      }

      return text.trim();
    } catch (e) {
      print("GIZIBOT ERROR: $e");

      return "Terjadi kesalahan saat mengambil data nutrisi.";
    }
  }
}
