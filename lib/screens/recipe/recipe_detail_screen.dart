import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../models/recipe_model.dart';
import '../../repositories/product_repository.dart';

import 'package:flutter/rendering.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _showBottomBar = true;
  int _tabIndex = 0;
  List<ProductModel> _buyProducts = [];
  bool _isLoadingBuy = false;

  final Color primary = const Color(0xFF2ECC71);
  final Color secondary = const Color(0xFF27AE60);
  final Color softGreen = const Color(0xFFEAFBF1);
  final Color dark = const Color(0xFF1F2937);

  String getFoodImage(String title) {
    final lower = title.toLowerCase();

    // NASI
    if (lower.contains('nasi goreng')) {
      return 'assets/foods/nasi_goreng.jpg';
    }

    if (lower.contains('nasi')) {
      return 'assets/foods/nasi_putih.jpg';
    }

    // AYAM
    if (lower.contains('ayam bakar')) {
      return 'assets/foods/ayam_bakar.jpg';
    }

    if (lower.contains('ayam goreng')) {
      return 'assets/foods/ayam_goreng.jpg';
    }

    if (lower.contains('ayam')) {
      return 'assets/foods/ayam.jpg';
    }

    // TEMPE & TAHU
    if (lower.contains('tempe')) {
      return 'assets/foods/tempe.jpg';
    }

    if (lower.contains('tahu')) {
      return 'assets/foods/tahu.jpg';
    }

    // SAYUR
    if (lower.contains('brokoli')) {
      return 'assets/foods/brokoli.jpg';
    }

    if (lower.contains('salad')) {
      return 'assets/foods/salad.jpg';
    }

    if (lower.contains('sayur')) {
      return 'assets/foods/sayur.jpg';
    }

    // SEAFOOD
    if (lower.contains('ikan')) {
      return 'assets/foods/ikan.jpg';
    }

    if (lower.contains('udang')) {
      return 'assets/foods/udang.jpg';
    }

    // SARAPAN
    if (lower.contains('oat')) {
      return 'assets/foods/oatmeal.jpg';
    }

    if (lower.contains('roti')) {
      return 'assets/foods/roti.jpg';
    }

    if (lower.contains('telur')) {
      return 'assets/foods/telur.jpg';
    }

    // BUAH
    if (lower.contains('pisang')) {
      return 'assets/foods/pisang.jpg';
    }

    if (lower.contains('alpukat')) {
      return 'assets/foods/alpukat.jpg';
    }

    // MIE
    if (lower.contains('mie')) {
      return 'assets/foods/mie.jpg';
    }

    // DEFAULT
    return 'assets/foods/default.jpg';
  }

  @override
  void initState() {
    super.initState();
    double lastOffset = 0;

    @override
    void initState() {
      super.initState();

      _scrollController.addListener(() {
        final currentOffset = _scrollController.offset;

        /// scroll down
        if (currentOffset > lastOffset + 10) {
          if (_showBottomBar) {
            setState(() {
              _showBottomBar = false;
            });
          }
        }
        /// scroll up
        else if (currentOffset < lastOffset - 10) {
          if (!_showBottomBar) {
            setState(() {
              _showBottomBar = true;
            });
          }
        }

        lastOffset = currentOffset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyIngredients() async {
    setState(() => _isLoadingBuy = true);

    final repo = ProductRepository(apiUrl: "https://dummy.api.io");

    final ingredientNames = widget.recipe.ingredients
        .map((e) => e.name)
        .toList();

    final products = await repo.fetchProductsByIngredients(ingredientNames);

    setState(() {
      _buyProducts = products;
      _isLoadingBuy = false;
    });
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final active = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [primary, secondary])
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ingredientItem(String name, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),

            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 44,
            height: 44,

            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, secondary]),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  softWrap: true,

                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  amount,

                  softWrap: true,

                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionItem(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, secondary]),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey.shade700,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget nutritionBox(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget nutritionTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            flex: 2,

            child: Text(
              title,

              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            flex: 3,

            child: Text(
              value,

              textAlign: TextAlign.right,

              softWrap: true,

              overflow: TextOverflow.visible,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FFF9),

      body: Stack(
        children: [
          /// TOP GRADIENT
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),

              child: Column(
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),

                          child: Container(
                            width: 46,
                            height: 46,

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),

                              borderRadius: BorderRadius.circular(16),
                            ),

                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        Container(
                          width: 46,
                          height: 46,

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),

                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: const Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// IMAGE
                  Hero(
                    tag: r.title,

                    child: Container(
                      width: 240,
                      height: 240,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),

                      child: CircleAvatar(
                        radius: 120,
                        backgroundColor: Colors.white,

                        child: CircleAvatar(
                          radius: 112,
                          backgroundImage: AssetImage(getFoodImage(r.title)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// CONTENT
                  Container(
                    width: double.infinity,

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(24),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// CATEGORY
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFEAFBF1),

                              borderRadius: BorderRadius.circular(100),
                            ),

                            child: Text(
                              r.category,

                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF2ECC71),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          /// TITLE
                          Text(
                            r.title,

                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// DESCRIPTION
                          Text(
                            r.description,

                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              height: 1.7,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// STATS
                          Row(
                            children: [
                              _timeCard(
                                "Persiapan",
                                "${r.prepTime}menit",
                                Icons.timer_outlined,
                              ),

                              const SizedBox(width: 12),

                              _timeCard(
                                "Masak",
                                "${r.cookTime}menit",
                                Icons.local_fire_department_outlined,
                              ),

                              const SizedBox(width: 12),

                              _timeCard(
                                "Total",
                                "${r.totalTime}menit",
                                Icons.schedule_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// INFO CARD
                          Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  Icons.favorite_rounded,
                                  "Skor Kesehatan",
                                  "${r.healthScore}/10",
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: _infoCard(
                                  Icons.payments_outlined,
                                  "Estimated Harga",
                                  "Rp ${r.price.toStringAsFixed(0)}",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          /// HEALTH STATUS
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(26),
                            ),

                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),

                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.12),

                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),

                                        child: Text(
                                          "Skor Kesehatan ${r.healthScore}/10",

                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),

                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            0.12,
                                          ),

                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),

                                        child: Text(
                                          r.healthyLevel,

                                          textAlign: TextAlign.center,

                                          overflow: TextOverflow.ellipsis,

                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                /// MACROS
                                Row(
                                  children: [
                                    Expanded(
                                      child: nutritionBox(
                                        Icons.fitness_center,
                                        "Protein",
                                        "${r.protein}g",
                                        Colors.blue,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: nutritionBox(
                                        Icons.rice_bowl,
                                        "Karbo",
                                        "${r.carbs}g",
                                        Colors.green,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: nutritionBox(
                                        Icons.opacity,
                                        "Lemak",
                                        "${r.fats}g",
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                nutritionTile("Kalori", "${r.calories} kcal"),

                                nutritionTile("Gula", "${r.sugars} g"),

                                nutritionTile("Sodium", "${r.sodium} mg"),

                                nutritionTile("Serat", "${r.fiber} g"),

                                nutritionTile(
                                  "Takaran Saji",
                                  r.nutritionPerServing,
                                ),

                                const SizedBox(height: 14),

                                Divider(color: Colors.grey.shade200),

                                const SizedBox(height: 14),

                                nutritionTile("Vitamin A", r.vitamins.vitaminA),

                                nutritionTile("Vitamin C", r.vitamins.vitaminC),

                                nutritionTile("Zat Besi", r.vitamins.iron),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// AI INSIGHT
                          Container(
                            width: double.infinity,

                            padding: const EdgeInsets.all(22),

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.12),
                                  Colors.white,
                                ],
                              ),

                              borderRadius: BorderRadius.circular(28),
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: primary,
                                    ),

                                    const SizedBox(width: 10),

                                    const Text(
                                      "Giziku Nutrition Insight",

                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  r.healthInsight,

                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.grey.shade700,
                                    height: 1.7,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// TAB
                          Container(
                            padding: const EdgeInsets.all(6),

                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Row(
                              children: [
                                _tabButton("Bahan-Bahan", 0),

                                _tabButton("Instruksi", 1),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// TAB CONTENT
                          if (_tabIndex == 0)
                            ...r.ingredients.map(
                              (e) => _ingredientItem(e.name, e.amount),
                            ),

                          if (_tabIndex == 1)
                            ...r.instructions.asMap().entries.map(
                              (e) => _instructionItem(e.key, e.value),
                            ),

                          /// IMPORTANT
                          /// supaya gak ketutup floating button
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// FLOATING STICKY BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutExpo,

        offset: _showBottomBar ? Offset.zero : const Offset(0, 2),

        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,

          opacity: _showBottomBar ? 1 : 0,

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                onPressed: () {},

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),

                  elevation: 14,

                  shadowColor: Colors.black.withOpacity(0.15),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),

                child: const Text(
                  "Makan Makanan Ini",

                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
