import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../models/product_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBuyIngredients();
  }

  Future<void> _loadBuyIngredients() async {
    setState(() => _isLoadingBuy = true);
    final repo = ProductRepository(apiUrl: "https://dummy.api.io"); // Ganti ke endpoint API kamu
    final ingredientNames = widget.recipe.ingredients.map((e) => e.name).toList();
    final products = await repo.fetchProductsByIngredients(ingredientNames);
    setState(() {
      _buyProducts = products;
      _isLoadingBuy = false;
    });
  }

  Widget _infoRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2ECC71), size: 20),
        const SizedBox(width: 8),
        Text(
          "$title ",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF8C8C8C),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }

  Widget _timeInfo(String label, int min, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "$min min",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF8C8C8C),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _tabIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? const Color(0xFF2ECC71) : const Color(0xFFF7FDFC),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF2ECC71),
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buyIngredientsSection() {
    if (_isLoadingBuy) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: CircularProgressIndicator(),
      ));
    }

    if (_buyProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            "No ingredients found",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _buyProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, idx) {
          final prod = _buyProducts[idx];
          return Container(
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: Image.network(
                    prod.imageUrl,
                    height: 60, width: double.infinity, fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prod.title,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text("Exp: ${prod.expiredDate}", style: const TextStyle(fontSize: 10, color: Color(0xFF8C8C8C))),
                      const SizedBox(height: 2),
                      Text("Rp ${prod.price.toStringAsFixed(0)}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(prod.location.address, style: const TextStyle(fontSize: 10, color: Color(0xFF8C8C8C))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Image & brief info
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button & Image
                  Column(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 38, height: 38,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(120),
                        child: Image.network(
                          r.imageUrl,
                          width: 120, height: 120, fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            width: 120, height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Category, Price, Nutrition
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Category", r.category, Icons.category_rounded),
                          const SizedBox(height: 16),
                          _infoRow("Price", "Rp. ${r.price.toStringAsFixed(0)}", Icons.attach_money),
                          const SizedBox(height: 16),
                          _infoRow("Nutrition", "${r.nutrition} ${r.nutritionUnit}", Icons.restaurant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body section
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 18),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Prep/Cook/Total time
                    Row(
                      children: [
                        _timeInfo("Prep Time", r.prepTime, const Color(0xFF2ECC71)),
                        const SizedBox(width: 16),
                        _timeInfo("Cook Time", r.cookTime, const Color(0xFF36C1F4)),
                        const SizedBox(width: 16),
                        _timeInfo("Total Time", r.totalTime, const Color(0xFF14C89B)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      r.description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF8C8C8C),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Tabs: Ingredients / Instructions
                    Row(
                      children: [
                        _tabButton("Ingridients", 0),
                        const SizedBox(width: 10),
                        _tabButton("Instructions", 1),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tab content + buy ingredients (ListView agar tidak overflow)
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (_tabIndex == 0)
                            ...r.ingredients.map((ing) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add, size: 20, color: Color(0xFF2ECC71)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          ing.name,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Color(0xFF222222),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ing.amount,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Color(0xFF8C8C8C),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          if (_tabIndex == 1)
                            ...r.instructions.asMap().entries.map((entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2ECC71),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "${entry.key + 1}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Color(0xFF222222),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          // Buy Ingredients Section
                          const SizedBox(height: 10),
                          _buyIngredientsSection(),
                        ],
                      ),
                    ),
                    // Add To Eat Button
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Add To Eat",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}