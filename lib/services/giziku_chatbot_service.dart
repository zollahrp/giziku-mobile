import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GiziBotResponse {
  final String text;
  final bool hasWidget;
  final Map<String, dynamic>? widgetData;

  GiziBotResponse({
    required this.text,
    this.hasWidget = false,
    this.widgetData,
  });
}

class GizifyChatbotService {
  String get _apiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static const String systemInstruction = """
Kamu adalah Gizibot, asisten nutrisi AI eksklusif untuk aplikasi Gizify. Gunakan bahasa Indonesia santai, asik, pakai kata "Kamu" atau "Mu", sedikit humoris dan berikan semangat.

FLEKSIBILITAS BAHASA:
Kamu fasih dwibahasa (Bahasa Indonesia dan Bahasa Inggris). Kamu bisa memahami pertanyaan baik dalam Bahasa Indonesia maupun Bahasa Inggris dengan sangat baik. Pengguna bebas bertanya menggunakan bahasa apa pun. Jika pengguna bertanya cara mengubah bahasa aplikasi, jelaskan dengan ramah bahwa mereka dapat mengatur preferensi bahasa kapan saja di menu "Profil Saya" (My Profile).

BATASAN SANGAT PENTING:
1. KUNCI TOPIK: Kamu HANYA BOLEH menjawab pertanyaan seputar makanan, gizi, diet, resep, kalori, dan kesehatan. Jika user bertanya di luar ranah ini (seperti matematika, coding, politik, dsb), tolak dengan sopan tapi kocak, dan arahkan kembali ke nutrisi.
2. ANTI-EMOJI: DILARANG KERAS menggunakan emoji apapun dalam balasanmu. Gunakan tanda baca standar saja.
3. MATA AI: Jika mendapat kiriman gambar/foto, identifikasilah sebagai makanan dan hitung gizinya.

ATURAN FORMAT BALASAN (WAJIB JSON):
Kamu HANYA BOLEH merespon dalam format JSON murni.
Struktur JSON WAJIB seperti ini:
{
  "text": "Pesan balasanmu di sini (pastikan 100% tanpa emoji, gunakan \\n\\n untuk enter)",
  "hasWidget": true/false,
  "widgetData": null atau { "title": "Nama Makanan", "calories": 300, "protein": 20, "carbs": 30, "fat": 10, "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=600&auto=format&fit=crop" }
}

Jika user meminta saran makanan/resep, set "hasWidget" menjadi true dan isi "widgetData" dengan estimasi gizinya.
""";

  /// Send message history to Gemini and receive structured GiziBotResponse
  Future<GiziBotResponse> sendChat({
    required List<ChatMessage> messages,
    String locale = "id",
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      return GiziBotResponse(
        text: "API Key Gemini belum terpasang di file konfigurasi .env.",
        hasWidget: false,
        widgetData: null,
      );
    }

    // =================================================================
    // 1. FILTER HISTORY SESUAI ATURAN GEMINI (PERSIS WEB)
    // =================================================================
    final List<Map<String, dynamic>> formattedHistory = [];
    String lastRole = "";

    for (final m in messages) {
      final role = m.sender == 'user' ? 'user' : 'model';

      // RULES 1: Jangan biarkan bot bicara duluan di memory API
      if (formattedHistory.isEmpty && role == 'model') continue;

      // RULES 2: Role harus selang-seling (User -> Model -> User)
      if (role == lastRole) continue;

      final List<Map<String, dynamic>> parts = [];
      if (m.text.trim().isNotEmpty) {
        parts.add({'text': m.text.trim()});
      }

      // Kalau user kirim gambar (base64)
      if (m.image != null && role == 'user' && m.image!.isNotEmpty) {
        try {
          String base64Data = m.image!;
          String mimeType = 'image/jpeg';

          if (base64Data.contains(',')) {
            final header = base64Data.split(',')[0];
            base64Data = base64Data.split(',')[1];
            if (header.contains(':') && header.contains(';')) {
              mimeType = header.split(';')[0].split(':')[1];
            }
          }

          parts.add({
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Data,
            }
          });
        } catch (e) {
          debugPrint("Error parsing image base64: $e");
        }
      }

      if (parts.isNotEmpty) {
        formattedHistory.add({'role': role, 'parts': parts});
        lastRole = role;
      }
    }

    // Pastikan turn terakhir adalah 'user'
    while (formattedHistory.isNotEmpty && formattedHistory.last['role'] != 'user') {
      formattedHistory.removeLast();
    }

    // Fallback jika history kosong
    if (formattedHistory.isEmpty) {
      formattedHistory.add({
        'role': 'user',
        'parts': [
          {'text': 'Halo GiziBot!'}
        ]
      });
    }

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': formattedHistory,
      'generationConfig': {
        'response_mime_type': 'application/json',
      }
    };

    // Model persis 100% sama dengan route.ts di web dashboard: gemini-3.1-flash-lite
    final models = [
      'gemini-3.1-flash-lite',
    ];

    for (final modelName in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final contentParts = candidates[0]['content']?['parts'] as List<dynamic>?;
            if (contentParts != null && contentParts.isNotEmpty) {
              String textResult = contentParts[0]['text']?.toString() ?? '';
              textResult = textResult
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();

              try {
                final parsedJson = jsonDecode(textResult);
                return GiziBotResponse(
                  text: parsedJson['text']?.toString() ?? textResult,
                  hasWidget: parsedJson['hasWidget'] == true,
                  widgetData: parsedJson['widgetData'] != null
                      ? Map<String, dynamic>.from(parsedJson['widgetData'] as Map)
                      : null,
                );
              } catch (_) {
                return GiziBotResponse(
                  text: textResult,
                  hasWidget: false,
                  widgetData: null,
                );
              }
            }
          }
        } else {
          debugPrint("Gemini $modelName HTTP ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        debugPrint("Error calling Gemini $modelName: $e");
      }
    }

    // Fallback response if all API endpoints fail
    return GiziBotResponse(
      text: "Saat ini Gizibot sedang menyesuaikan koneksi dengan server AI. Silakan tanyakan kembali seputar gizi, resep, atau target kalorimu ya!",
      hasWidget: false,
      widgetData: null,
    );
  }

  /// Backward-compatible single message method
  Future<String> sendMessage(String userMessage) async {
    final res = await sendChat(
      messages: [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: 'user',
          text: userMessage,
          time: 'now',
        ),
      ],
    );
    return res.text;
  }
}
