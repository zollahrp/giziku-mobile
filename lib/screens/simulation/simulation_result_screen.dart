import 'package:flutter/material.dart';
import '/models/simulation_ai_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SimulationResultScreen extends StatelessWidget {
  final int budget;
  final int days;
  final int people;

  final SimulationAiModel aiResult;

  const SimulationResultScreen({
    super.key,
    required this.budget,
    required this.days,
    required this.people,
    required this.aiResult,
  });

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

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

  Future<void> saveMealPlan(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // PILIH TANGGAL MULAI
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (selectedDate == null) return;

    // SIMPAN SEMUA HARI
    for (int i = 0; i < aiResult.mealPlan.length; i++) {
      final mealDay = aiResult.mealPlan[i];

      final scheduledDate = selectedDate.add(
        Duration(days: i),
      );

      final formattedDate =
          "${scheduledDate.year}-"
          "${scheduledDate.month.toString().padLeft(2, '0')}-"
          "${scheduledDate.day.toString().padLeft(2, '0')}";

      for (final meal in mealDay.meals) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_meals')
            .add({
          'date': formattedDate,

          'day': mealDay.day,

          'meal_type': meal.mealType,

          'title': meal.title,

          'description': meal.description,

          'estimated_calories':
              meal.estimatedCalories,

          'estimated_price':
              meal.estimatedPrice,

          'created_at': Timestamp.now(),
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Menu berhasil dijadwalkan 🎉",
        ),
      ),
    );

    // BALIK KE HOME
    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Gagal menyimpan menu",
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final budgetPerDay = budget ~/ days;
    final budgetPerPerson = budget ~/ people;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF2ECC71),
                        size: 20,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF2ECC71),
                          size: 18,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "Hasil Rencana Menu",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Title
              const Text(
                "Rencana Makananmu\nSudah Siap",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Giziku telah membuat rekomendasi makanan berdasarkan budget dan kebutuhanmu.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_menu, color: Colors.white),

                        SizedBox(width: 10),

                        Text(
                          "Ringkasan Plan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: buildSummaryItem(
                            "Budget",
                            "Rp ${formatRupiah(budget)}",
                          ),
                        ),

                        Expanded(
                          child: buildSummaryItem("Durasi", "$days Hari"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: buildSummaryItem("Orang", "$people Orang"),
                        ),

                        Expanded(
                          child: buildSummaryItem(
                            "Per Hari",
                            "Rp ${formatRupiah(budgetPerDay)}",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // AI Insight
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Color(0xFF2ECC71)),

                        SizedBox(width: 10),

                        Text(
                          "Insight Giziku",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      aiResult.summary,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      aiResult.nutritionInsight,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recommendation Card
              const SizedBox(height: 18),

              // Recommendation Section
              const Text(
                "Rekomendasi Menu",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              Column(
                children: [
                  ...List.generate(
                    aiResult.mealPlan.length > 3 ? 3 : aiResult.mealPlan.length,
                    (index) {
                      final day = aiResult.mealPlan[index];

                      return buildDayCard(day);
                    },
                  ),

                  if (aiResult.mealPlan.length > 3)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.85,

                                padding: const EdgeInsets.all(24),

                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAF8),

                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                ),

                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 6,

                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,

                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      "Semua Rencana Makanan",

                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: aiResult.mealPlan.length,

                                        itemBuilder: (context, index) {
                                          final day = aiResult.mealPlan[index];

                                          return buildDayCard(day);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },

                        child: const Text(
                          "Lihat Lainnya",

                          style: TextStyle(
                            color: Color(0xFF2ECC71),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // Nutrition Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFF2ECC71)),

                        const SizedBox(width: 10),

                        const Text(
                          "Estimasi Nutrisi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            "Seimbang",
                            style: TextStyle(
                              color: Color(0xFF2ECC71),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildNutritionItem("Protein", "85g"),

                        buildNutritionItem("Karbo", "210g"),

                        buildNutritionItem("Lemak", "55g"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Button
              Row(
  children: [

    // BATAL
    Expanded(
      child: SizedBox(
        height: 58,

        child: OutlinedButton(
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          },

          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFF2ECC71),
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          child: const Text(
            "Batal",
            style: TextStyle(
              color: Color(0xFF2ECC71),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),

    const SizedBox(width: 16),

    // SIMPAN
    Expanded(
      flex: 2,
      child: SizedBox(
        height: 58,

        child: ElevatedButton(
          onPressed: () async {
            await saveMealPlan(context);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          child: const Text(
            "Simpan Menu",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  ],
),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSummaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildDayCard(day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Hari ${day.day}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          ...day.meals.map<Widget>((meal) {
            return Container(
              margin: const EdgeInsets.only(bottom: 18),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(getFoodImage(meal.title)),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          meal.mealType,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          meal.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          meal.description,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 18,
                              color: Colors.orange,
                            ),

                            const SizedBox(width: 6),

                            Text("${meal.estimatedCalories} kcal"),

                            const SizedBox(width: 14),

                            const Icon(
                              Icons.payments_rounded,
                              size: 18,
                              color: Color(0xFF2ECC71),
                            ),

                            const SizedBox(width: 6),

                            Text("Rp ${formatRupiah(meal.estimatedPrice)}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildRecipeCard({
    required String title,
    required String calories,
    required String price,
    required String image,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 270,
          margin: const EdgeInsets.only(right: 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 18,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    calories,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF2ECC71),
                    size: 18,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    price,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: 120,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Lihat Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 18,
          right: 8,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(image),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNutritionItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2ECC71),
          ),
        ),

        const SizedBox(height: 6),

        Text(title, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
