import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../models/recipe_model.dart';
import '../../repositories/product_repository.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _tabIndex = 0;
  List<ProductModel> _buyProducts = [];
  bool _isLoadingBuy = false;

  final Color primary = const Color(0xFF2ECC71);
  final Color secondary = const Color(0xFF27AE60);
  final Color softGreen = const Color(0xFFEAFBF1);
  final Color dark = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _loadBuyIngredients();
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
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
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
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
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
                    tag: r.imageUrl,

                    child: Container(
                      width: 240,
                      height: 240,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),

                        child: Image.network(r.imageUrl, fit: BoxFit.cover),
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
                                "Prep",
                                "${r.prepTime}m",
                                Icons.timer_outlined,
                              ),

                              const SizedBox(width: 12),

                              _timeCard(
                                "Cook",
                                "${r.cookTime}m",
                                Icons.local_fire_department_outlined,
                              ),

                              const SizedBox(width: 12),

                              _timeCard(
                                "Total",
                                "${r.totalTime}m",
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
                                  "Health Score",
                                  "${r.healthScore}/10",
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: _infoCard(
                                  Icons.payments_outlined,
                                  "Estimated Price",
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
                                    Container(
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
                                        "Health Score ${r.healthScore}/10",
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        r.healthyLevel,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
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
                                      "AI Nutrition Insight",
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
                                _tabButton("Ingredients", 0),

                                _tabButton("Instructions", 1),
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

                          const SizedBox(height: 34),

                          /// BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 60,

                            child: ElevatedButton(
                              onPressed: () {},

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2ECC71),

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),

                              child: const Text(
                                "Add To Eat 🍃",

                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
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
    );
  }
}
