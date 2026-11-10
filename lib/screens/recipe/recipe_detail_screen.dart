import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gizify/data/dummy_recipes.dart';
import 'package:gizify/models/recipe_model.dart';
import 'package:gizify/screens/recipe_screen.dart'; // for cityPriceIndex

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel? recipe;
  final Map<String, dynamic>? recipeMap;
  final String? recipeId;
  final String selectedCurrency;
  final String userLocation;

  const RecipeDetailScreen({
    super.key,
    this.recipe,
    this.recipeMap,
    this.recipeId,
    this.selectedCurrency = "IDR",
    this.userLocation = "Jakarta",
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late Map<String, dynamic> _data;
  final Set<int> _checkedIngredients = {};
  bool _isBookmarked = false;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _initRecipeData();
    _checkBookmarkStatus();
  }

  void _initRecipeData() {
    if (widget.recipeMap != null) {
      _data = Map<String, dynamic>.from(widget.recipeMap!);
    } else if (widget.recipe != null) {
      final r = widget.recipe!;
      _data = {
        'id': r.id ?? 'recipe_${DateTime.now().millisecondsSinceEpoch}',
        'title': r.title,
        'category': r.category,
        'calories': r.calories,
        'rating': 4.8,
        'reviews': 45,
        'author': 'Gizify',
        'date': 'Hari Ini',
        'matchScore': 95,
        'description': r.description,
        'prepTime': "${r.prepTime} Menit",
        'cookTime': "${r.cookTime} Menit",
        'servings': "1 Porsi",
        'priceIdr': r.price,
        'origin': 'Indonesia',
        'location': widget.userLocation,
        'equipments': ['Wajan', 'Pisau', 'Timbangan Makanan'],
        'nutrition': {
          'kalori': r.calories,
          'protein': "${r.protein}g",
          'lemak': "${r.fats}g",
          'karbohidrat': "${r.carbs}g",
          'serat': "${r.fiber}g",
          'gula': "${r.sugars}g",
          'natrium': "${r.sodium}mg",
        },
        'ingredients': [
          {
            'section': 'Bahan Utama',
            'items': r.ingredients.map((e) => "${e.amount} ${e.name}".trim()).toList(),
          }
        ],
        'instructions': r.instructions,
        'image': r.imageUrl.isNotEmpty ? r.imageUrl : '',
      };
    } else if (widget.recipeId != null) {
      final found = dummyRecipesData.firstWhere(
        (r) => r['id'] == widget.recipeId,
        orElse: () => dummyRecipesData[0],
      );
      _data = Map<String, dynamic>.from(found);
    } else {
      _data = Map<String, dynamic>.from(dummyRecipesData[0]);
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final uid = currentUser?.uid;
    final recipeId = _data['id']?.toString() ?? _data['title'].toString();
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(recipeId)
          .get();

      if (doc.exists && mounted) {
        setState(() => _isBookmarked = true);
      }
    } catch (e) {
      debugPrint("Error checking bookmark: $e");
    }
  }

  Future<void> _toggleBookmark() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masuk untuk menyimpan resep"), backgroundColor: Colors.orange),
      );
      return;
    }

    final recipeId = _data['id']?.toString() ?? _data['title'].toString();
    setState(() => _isBookmarked = !_isBookmarked);

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(recipeId);

    try {
      if (!_isBookmarked) {
        await docRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Resep dihapus dari favorit"),
              backgroundColor: Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        final toSave = Map<String, dynamic>.from(_data);
        toSave['savedAt'] = FieldValue.serverTimestamp();
        await docRef.set(toSave);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Resep disimpan ke favorit!"),
              backgroundColor: Color(0xFF1EAB57),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
    }
  }

  Future<void> _rateRecipe(int star) async {
    setState(() => _userRating = star);

    final uid = currentUser?.uid;
    final recipeId = _data['id']?.toString() ?? _data['title'].toString();
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('ratings')
            .doc(recipeId)
            .set({
          'rating': star,
          'ratedAt': FieldValue.serverTimestamp(),
          'recipeTitle': _data['title'],
        });
      } catch (e) {
        debugPrint("Error saving rating: $e");
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terima kasih atas penilaian $star bintang Anda!"),
          backgroundColor: const Color(0xFF1EAB57),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  double _getCityMultiplier(String city) {
    final norm = city.toLowerCase().trim();
    for (final entry in cityPriceIndex.entries) {
      if (norm.contains(entry.key)) {
        return (entry.value['multiplier'] as num).toDouble();
      }
    }
    return 1.0;
  }

  String _getDynamicPrice() {
    int baseIdr = (_data['priceIdr'] as num?)?.toInt() ?? 0;
    if (baseIdr == 0 && _data['totalBudget'] != null) {
      final raw = _data['totalBudget'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      baseIdr = int.tryParse(raw) ?? 30000;
    }
    if (baseIdr == 0) baseIdr = 30000;

    final multiplier = _getCityMultiplier(widget.userLocation);
    final adjustedIdr = ((baseIdr * multiplier) / 500).round() * 500;

    if (widget.selectedCurrency == "MYR") {
      final myr = (adjustedIdr / 3500).toStringAsFixed(2);
      return "RM $myr";
    } else if (widget.selectedCurrency == "USD") {
      final usd = (adjustedIdr / 16000).toStringAsFixed(2);
      return "\$ $usd";
    } else {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(adjustedIdr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _data['title']?.toString() ?? '';
    final String description = _data['description']?.toString() ?? '';
    final String imageUrl = _data['image']?.toString() ?? '';
    final String author = _data['author']?.toString() ?? 'Gizify';
    final String date = _data['date']?.toString() ?? 'Hari Ini';
    final num rating = _data['rating'] as num? ?? 4.8;
    final num reviews = _data['reviews'] as num? ?? 50;
    final int? matchScore = (_data['matchScore'] as num?)?.toInt();

    final String prepTime = _data['prepTime']?.toString() ?? '10 Menit';
    final String cookTime = _data['cookTime']?.toString() ?? '15 Menit';
    final String servings = _data['servings']?.toString() ?? '1 Porsi';
    final String? origin = _data['origin']?.toString();
    final String priceStr = _getDynamicPrice();

    final List ingredientsList = _data['ingredients'] as List? ?? [];
    final List instructionsList = _data['instructions'] as List? ?? [];
    final List equipmentsList = _data['equipments'] as List? ?? [];
    final Map<String, dynamic> nutrition = Map<String, dynamic>.from(_data['nutrition'] as Map? ?? {});

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 14),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Share Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.share_rounded, color: Color(0xFF475569), size: 16),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tautan resep disalin ke papan klip!"),
                  backgroundColor: Color(0xFF1EAB57),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // Bookmark Button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isBookmarked ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isBookmarked ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isBookmarked ? const Color(0xFF1EAB57) : const Color(0xFF475569),
                  size: 16,
                ),
              ),
              onPressed: _toggleBookmark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Match Score Pill
            if (matchScore != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1EAB57), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "$matchScore% Cocok dengan Target Gizimu",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF047857),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Recipe Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                fontFamily: 'Poppins',
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),

            // 3. Author & Rating Bar
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 18, color: Color(0xFF1EAB57)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        "$rating ($reviews)",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF92400E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Description Paragraph
            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),
            const SizedBox(height: 18),

            // 5. Big Hero Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                      )
                    : Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Meta Stats Card (Prep, Cook, Servings, Budget, Origin)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetaStatItem("PERSIAPAN", prepTime, Icons.timer_outlined),
                      _buildMetaDivider(),
                      _buildMetaStatItem("WAKTU MASAK", cookTime, Icons.soup_kitchen_rounded),
                      _buildMetaDivider(),
                      _buildMetaStatItem("PORSI", servings, Icons.restaurant_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (origin != null) ...[
                        _buildMetaStatItem("ASAL KULINER", origin, Icons.public_rounded),
                        _buildMetaDivider(),
                      ],
                      _buildMetaStatItem("ESTIMASI BIAYA", priceStr, Icons.account_balance_wallet_rounded, isHighlight: true),
                      _buildMetaDivider(),
                      _buildMetaStatItem("PASAR ACUAN", widget.userLocation, Icons.place_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. Nutrition & Macro Cards
            if (nutrition.isNotEmpty) ...[
              const Text(
                "Informasi Nilai Gizi",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              _buildNutritionDashboard(nutrition),
              const SizedBox(height: 24),
            ],

            // 8. Equipments Badges
            if (equipmentsList.isNotEmpty) ...[
              const Text(
                "Peralatan yang Dibutuhkan",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: equipmentsList.map((eq) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF1EAB57)),
                        const SizedBox(width: 6),
                        Text(
                          eq.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // 9. Ingredients (with Interactive Checkboxes!)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bahan-Bahan",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  "${_checkedIngredients.length} terceklis",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1EAB57),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Ketuk bahan untuk menandai yang sudah siap atau selesai dimasak.",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),

            ..._buildGroupedIngredients(ingredientsList),

            const SizedBox(height: 24),

            // 10. Cooking Instructions
            const Text(
              "Langkah-Langkah Memasak",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            ..._buildInstructionsList(instructionsList),

            const SizedBox(height: 32),

            // 11. Interactive Rating Card
            _buildRatingFeedbackCard(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildMetaStatItem(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: isHighlight ? const Color(0xFF1EAB57) : const Color(0xFF64748B)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isHighlight ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildMetaDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildNutritionDashboard(Map<String, dynamic> nut) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildNutriTile("Kalori", "${nut['kalori'] ?? nut['calories'] ?? 0} kkal", const Color(0xFFF97316))),
              const SizedBox(width: 8),
              Expanded(child: _buildNutriTile("Protein", "${nut['protein'] ?? '0g'}", const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _buildNutriTile("Karbohidrat", "${nut['karbohidrat'] ?? nut['carbs'] ?? '0g'}", const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildNutriTile("Lemak", "${nut['lemak'] ?? nut['fats'] ?? '0g'}", const Color(0xFFEC4899))),
            ],
          ),
          if (nut['serat'] != null || nut['natrium'] != null || nut['gula'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (nut['serat'] != null)
                  Expanded(child: _buildNutriSubTile("Serat", "${nut['serat']}")),
                if (nut['gula'] != null)
                  Expanded(child: _buildNutriSubTile("Gula", "${nut['gula']}")),
                if (nut['natrium'] != null)
                  Expanded(child: _buildNutriSubTile("Natrium", "${nut['natrium']}")),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutriTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutriSubTile(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedIngredients(List ingredientsList) {
    int itemGlobalIndex = 0;
    List<Widget> widgets = [];

    for (var group in ingredientsList) {
      final sectionTitle = group['section']?.toString() ?? 'Bahan';
      final List items = group['items'] as List? ?? [];

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1EAB57),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              ...items.map((item) {
                final currentIdx = itemGlobalIndex++;
                final bool isChecked = _checkedIngredients.contains(currentIdx);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedIngredients.remove(currentIdx);
                      } else {
                        _checkedIngredients.add(currentIdx);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFF1EAB57) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isChecked ? const Color(0xFF1EAB57) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChecked ? FontWeight.w500 : FontWeight.w700,
                              color: isChecked ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildInstructionsList(List instructionsList) {
    return List.generate(instructionsList.length, (idx) {
      final stepText = instructionsList[idx].toString();

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF1EAB57),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${idx + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stepText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRatingFeedbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Text(
            "Sudah Mencoba Resep Ini?",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Beri penilaian bintang untuk membantu anggota Gizify lainnya.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (starIdx) {
              final starNum = starIdx + 1;
              final isFilled = starNum <= _userRating;

              return IconButton(
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 32,
                ),
                onPressed: () => _rateRecipe(starNum),
              );
            }),
          ),
        ],
      ),
    );
  }
}
