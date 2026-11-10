import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/recipe_model.dart';
import '../../models/vitamins_model.dart';
import 'package:gizify/screens/recipe/recipe_detail_screen.dart';

import 'package:intl/intl.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String getFoodImage(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('nasi goreng')) {
      return 'assets/foods/nasi_goreng.jpg';
    }

    if (lower.contains('nasi')) {
      return 'assets/foods/nasi_putih.jpg';
    }

    if (lower.contains('ayam bakar')) {
      return 'assets/foods/ayam_bakar.jpg';
    }

    if (lower.contains('ayam goreng')) {
      return 'assets/foods/ayam_goreng.jpg';
    }

    if (lower.contains('ayam')) {
      return 'assets/foods/ayam.jpg';
    }

    if (lower.contains('tempe')) {
      return 'assets/foods/tempe.jpg';
    }

    if (lower.contains('tahu')) {
      return 'assets/foods/tahu.jpg';
    }

    if (lower.contains('brokoli')) {
      return 'assets/foods/brokoli.jpg';
    }

    if (lower.contains('salad')) {
      return 'assets/foods/salad.jpg';
    }

    if (lower.contains('sayur')) {
      return 'assets/foods/sayur.jpg';
    }

    if (lower.contains('ikan')) {
      return 'assets/foods/ikan.jpg';
    }

    if (lower.contains('udang')) {
      return 'assets/foods/udang.jpg';
    }

    if (lower.contains('oat')) {
      return 'assets/foods/oatmeal.jpg';
    }

    if (lower.contains('roti')) {
      return 'assets/foods/roti.jpg';
    }

    if (lower.contains('telur')) {
      return 'assets/foods/telur.jpg';
    }

    if (lower.contains('pisang')) {
      return 'assets/foods/pisang.jpg';
    }

    if (lower.contains('alpukat')) {
      return 'assets/foods/alpukat.jpg';
    }

    if (lower.contains('mie')) {
      return 'assets/foods/mie.jpg';
    }

    return 'assets/foods/default.jpg';
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('saved_recipes')
              .orderBy('saved_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/gizifylogo.png', width: 80),

                        const SizedBox(height: 12),

                        const Text(
                          "Resep Tersimpan\nUntuk Kamu",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Semua resep hasil simulasi yang sudah kamu simpan akan muncul di sini.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// SEARCH
                  _buildSearchBar(),

                  const SizedBox(height: 26),

                  /// TITLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Resep Tersimpan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAFBF1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            "${docs.length} Resep",
                            style: const TextStyle(
                              color: Color(0xFF2ECC71),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// EMPTY STATE
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAFBF1),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Icon(
                                Icons.bookmark_border_rounded,
                                size: 48,
                                color: Color(0xFF2ECC71),
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Belum Ada Resep",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Resep yang kamu simpan dari hasil simulasi akan muncul di halaman ini.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  /// LIST RESEP
                  else
                    ListView.builder(
                      itemCount: docs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        final recipe = RecipeModel(
                          id: data['id'] ?? '',
                          title: data['title'] ?? '',
                          description: data['description'] ?? '',
                          imageUrl: data['image_url'] ?? '',
                          category: data['category'] ?? '',
                          price:
                              (data['estimated_price'] as num?)?.toInt() ?? 0,
                          calories:
                              (data['estimated_calories'] as num?)?.toInt() ??
                              0,
                          protein: (data['protein'] as num?)?.toInt() ?? 0,
                          carbs: (data['carbs'] as num?)?.toInt() ?? 0,
                          fats: (data['fats'] as num?)?.toInt() ?? 0,
                          sugars: (data['sugars'] as num?)?.toInt() ?? 0,
                          sodium: (data['sodium'] as num?)?.toInt() ?? 0,
                          fiber: (data['fiber'] as num?)?.toInt() ?? 0,
                          healthScore:
                              (data['health_score'] as num?)?.toInt() ?? 0,
                          healthyLevel: data['healthy_level'] ?? '',
                          healthInsight: data['health_insight'] ?? '',
                          nutritionPerServing:
                              data['nutrition_per_serving'] ?? '',
                          vitamins: VitaminsModel.fromJson(
                            data['vitamins'] ?? {},
                          ),
                          prepTime: (data['prep_time'] as num?)?.toInt() ?? 0,
                          cookTime: (data['cook_time'] as num?)?.toInt() ?? 0,
                          totalTime: (data['total_time'] as num?)?.toInt() ?? 0,
                          ingredients: (data['ingredients'] as List? ?? [])
                              .map((e) => RecipeIngredient.fromJson(e))
                              .toList(),
                          instructions: List<String>.from(
                            data['instructions'] ?? [],
                          ),
                        );

                        final Timestamp? savedAt = data['saved_at'];

                        String savedText = "Disimpan baru saja";

                        if (savedAt != null) {
                          final date = savedAt.toDate();

                          final now = DateTime.now();

                          final difference = now.difference(date).inDays;

                          if (difference == 0) {
                            savedText = "Disimpan hari ini";
                          } else if (difference == 1) {
                            savedText = "Disimpan kemarin";
                          } else {
                            savedText =
                                "Disimpan ${date.day}/${date.month}/${date.year}";
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: _buildRecipeCard(recipe, savedText),
                        );
                      },
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Cari resep tersimpan...',
            hintStyle: TextStyle(fontFamily: 'Poppins'),
            suffixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe, String savedText) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: Image.asset(
                getFoodImage(recipe.title),
                width: 105,
                height: 105,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            /// CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TOP ROW
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFBF1),
                          borderRadius: BorderRadius.circular(100),
                        ),

                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            color: Color(0xFF2ECC71),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Icon(
                        Icons.bookmark_rounded,
                        size: 18,
                        color: Colors.green.shade400,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// TITLE
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// INFO
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _buildMiniTag(
                        Icons.local_fire_department_rounded,
                        "${recipe.calories} kcal",
                        Colors.orange,
                      ),

                      _buildMiniTag(
                        Icons.star_rounded,
                        "${recipe.healthScore}/10",
                        Colors.amber,
                      ),

                      _buildMiniTag(
                        Icons.payments_outlined,
                        formatRupiah(recipe.price),
                        const Color(0xFF2ECC71),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// FOOTER
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          savedText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),

          const SizedBox(width: 4),

          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
