import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../models/recipe_model.dart';
import '../models/vitamins_model.dart';
import '../screens/recipe/recipe_detail_screen.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRecipeTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRecipeTap,
  });

  String _getFoodImage(String title, String? existingUrl) {
    if (existingUrl != null && existingUrl.isNotEmpty && !existingUrl.contains('pollinations.ai')) {
      return existingUrl;
    }
    final lower = title.toLowerCase();
    if (lower.contains('nasi goreng') || lower.contains('nasgor')) {
      return 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('ayam bakar') || lower.contains('panggang')) {
      return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('ayam') || lower.contains('chicken')) {
      return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('salmon') || lower.contains('ikan')) {
      return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('salad') || lower.contains('sayur')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('oat') || lower.contains('sarapan')) {
      return 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?q=80&w=600&auto=format&fit=crop';
    }
    if (lower.contains('telur') || lower.contains('egg')) {
      return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=600&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=600&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar on Left
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EAB57), Color(0xFF127236)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1EAB57).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble Container
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender label & time
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "${isUser ? 'Kamu' : 'Gizibot'} • ${message.time}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),

                // Main Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isUser ? Colors.transparent : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Attached Image (if any)
                      if (message.image != null && message.image!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageWidget(message.image!),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Message Content
                      if (message.text.isNotEmpty)
                        isUser
                            ? Text(
                                message.text,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : MarkdownBody(
                                data: message.text,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  strong: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  listBullet: const TextStyle(
                                    color: Color(0xFF1EAB57),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                      // Rich Food Recommendation Widget
                      if (message.hasWidget && message.widgetData != null) ...[
                        const SizedBox(height: 10),
                        _buildFoodRecommendationWidget(context, message.widgetData!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageStr) {
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
      );
    }
    try {
      String cleanBase64 = imageStr;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',')[1];
      }
      return Image.memory(
        base64Decode(cleanBase64),
        width: 200,
        height: 150,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildFoodRecommendationWidget(BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Rekomendasi Menu';
    final calories = data['calories'] ?? 300;
    final protein = data['protein'] ?? 20;
    final carbs = data['carbs'] ?? 30;
    final fat = data['fat'] ?? 10;
    final imageUrl = _getFoodImage(title, data['image']?.toString());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image with Flame Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFFDCFCE7),
                    child: const Center(
                      child: Icon(Icons.restaurant_rounded, color: Color(0xFF1EAB57), size: 36),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EAB57).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "$calories Kcal",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Macro badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildMacroChip("Pro", "${protein}g", const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                    _buildMacroChip("Karbo", "${carbs}g", const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                    _buildMacroChip("Lemak", "${fat}g", const Color(0xFFF43F5E), const Color(0xFFFFE4E6)),
                  ],
                ),
                const SizedBox(height: 10),

                // CTA Button: LIHAT RESEP
                GestureDetector(
                  onTap: () {
                    final recipe = RecipeModel(
                      id: "ai-${DateTime.now().millisecondsSinceEpoch}",
                      title: title,
                      description: "Menu rekomendasi gizi seimbang yang dirancang otomatis oleh Gizibot.",
                      imageUrl: imageUrl,
                      category: "Rekomendasi AI",
                      price: 25000,
                      calories: calories is num ? calories.toInt() : 300,
                      protein: protein is num ? protein.toInt() : 20,
                      carbs: carbs is num ? carbs.toInt() : 30,
                      fats: fat is num ? fat.toInt() : 10,
                      sugars: 5,
                      sodium: 350,
                      fiber: 4,
                      healthScore: 9,
                      healthyLevel: "Sangat Sehat",
                      healthInsight: "Kombinasi makronutrisi seimbang untuk mencukupi kebutuhan harian.",
                      nutritionPerServing: "1 Porsi",
                      vitamins: VitaminsModel(
                        vitaminA: "60%",
                        vitaminC: "80%",
                        iron: "70%",
                      ),
                      prepTime: 10,
                      cookTime: 15,
                      totalTime: 25,
                      ingredients: [
                        RecipeIngredient(name: "Bahan utama $title", amount: "1 porsi"),
                        RecipeIngredient(name: "Sayuran segar pelengkap", amount: "1 mangkuk kecil"),
                        RecipeIngredient(name: "Minyak zaitun / sehat", amount: "1 sdt"),
                        RecipeIngredient(name: "Bumbu & rempah alami", amount: "Secukupnya"),
                      ],
                      instructions: [
                        "Siapkan seluruh bahan baku segar dan bersihkan dengan air mengalir.",
                        "Masak bahan dengan metode rendah lemak (kukus, rebus, atau panggang).",
                        "Sajikan selagi hangat untuk menikmati cita rasa dan menjaga nutrisi maksimal.",
                      ],
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EAB57),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1EAB57).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "LIHAT RESEP",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
