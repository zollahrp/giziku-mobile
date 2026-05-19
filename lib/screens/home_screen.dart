import 'package:flutter/material.dart';
import 'package:giziku/screens/nutrition_detail_screen.dart';
import 'package:giziku/screens/simulation/simulation_budget_screen.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giziku/screens/recipe/recipe_detail_screen.dart';
import 'package:giziku/models/recipe_model.dart';
import 'package:giziku/screens/recipe/recipe_detail_screen.dart';
import 'package:giziku/models/vitamins_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  final user = FirebaseAuth.instance.currentUser;

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
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    final String name = user?.displayName ?? "Guest User";
    final String email = user?.email ?? "No Email";
    final String photo = user?.photoURL ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(formattedDate, name, email, photo),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildActiveSimulationCard(),
              ),
              const SizedBox(height: 15),
              _buildNutritionSection(),
              const SizedBox(height: 15),
              _buildDateSelector(),
              const SizedBox(height: 15),
              _buildRecipeTodaySection(),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String formattedDate,
    String name,
    String email,
    String photo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                ),

                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFC857),

                  backgroundImage: photo.isNotEmpty
                      ? NetworkImage(photo)
                      : null,

                  child: photo.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Jaga nutrisi kamu hari ini ya',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE7FCF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_outlined,
                color: Color(0xFF2ECC71),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSimulationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71),
        borderRadius: BorderRadius.circular(15),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('scheduled_meals')
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final bool hasMealPlan = docs.isNotEmpty;

          int totalBudget = 0;

          for (var doc in docs) {
            totalBudget += (doc['estimated_price'] ?? 0) as int;
          }

          final uniqueDates = docs
              .map((e) => e['date'].toString())
              .toSet()
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SimulationItem(
                    label: "Budget",
                    value: hasMealPlan
                        ? "Rp ${NumberFormat('#,###', 'id_ID').format(totalBudget)}"
                        : "-",
                  ),

                  _SimulationItem(
                    label: "Hari",
                    value: hasMealPlan ? "$uniqueDates Hari" : "-",
                  ),

                  _SimulationItem(
                    label: "Menu",
                    value: hasMealPlan ? "${docs.length} Item" : "-",
                  ),
                ],
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  // KALAU BELUM ADA MENU
                  if (!hasMealPlan) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimulationBudgetScreen(),
                      ),
                    );

                    return;
                  }

                  // KALAU SUDAH ADA MENU
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),

                        title: const Text(
                          "Rencana Menu Aktif",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        content: const Text(
                          "Kamu sudah memiliki rencana menu.\n\nJika membuat simulasi baru, maka semua menu sebelumnya akan dihapus.",
                          style: TextStyle(height: 1.5),
                        ),

                        actions: [
                          // TUTUP
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            child: const Text(
                              "Batal",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                          // HAPUS & BUAT BARU
                          ElevatedButton(
                            onPressed: () async {
                              final batch = FirebaseFirestore.instance.batch();

                              for (var doc in docs) {
                                batch.delete(doc.reference);
                              }

                              await batch.commit();

                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SimulationBudgetScreen(),
                                ),
                              );
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            child: const Text(
                              "Buat Baru",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),

                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        hasMealPlan ? 'Rencana Menu Aktif' : 'Mulai Simulasi',

                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        width: 18,
                        height: 18,

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(9),
                        ),

                        child: Center(
                          child: Icon(
                            hasMealPlan
                                ? Icons.restaurant
                                : Icons.arrow_forward_ios,

                            color: const Color(0xFF2ECC71),

                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNutritionSection() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),

      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

        final int targetCalories = (userData['daily_calories'] ?? 0);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('daily_nutrition')
              .doc(today)
              .snapshots(),

          builder: (context, nutritionSnapshot) {
            final nutritionData =
                nutritionSnapshot.data?.data() as Map<String, dynamic>?;

            final int calories = (nutritionData?['calories'] ?? 0);

            final int protein = (nutritionData?['protein'] ?? 0);

            final int carbs = (nutritionData?['carbs'] ?? 0);

            final int fats = (nutritionData?['fats'] ?? 0);

            final double progress = targetCalories > 0
                ? calories / targetCalories
                : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NutritionDetailScreen(),
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,

                            decoration: BoxDecoration(
                              color: const Color(0xFFE8FFF1),
                              borderRadius: BorderRadius.circular(16),
                            ),

                            child: const Icon(
                              Icons.monitor_heart_rounded,
                              color: Color(0xFF2ECC71),
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Text(
                              "Nutrisi Harian Kamu",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ================= KALORI =================
                      Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FFF9),
                          borderRadius: BorderRadius.circular(22),
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Kalori Hari Ini",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),

                                const Spacer(),

                                Text(
                                  "$calories / $targetCalories kcal",

                                  style: const TextStyle(
                                    color: Color(0xFF2ECC71),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),

                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 10,

                                backgroundColor: Colors.green.shade100,

                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactNutrition(
                              "Protein",
                              "${protein}g",
                              Icons.fitness_center,
                              Colors.blue,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _buildCompactNutrition(
                              "Karbo",
                              "${carbs}g",
                              Icons.rice_bowl,
                              Colors.orange,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _buildCompactNutrition(
                              "Lemak",
                              "${fats}g",
                              Icons.opacity,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactNutrition(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 20),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionItem(
    String value,
    String total,
    String label,
    double percent,
    Color progressColor,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              total,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          width: 75.0,
          lineHeight: 4.0,
          percent: percent,
          backgroundColor: Colors.grey[700],
          progressColor: progressColor,
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(10),
        ),
      ],
    );
  }

  Widget _buildMacroChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),

          const SizedBox(width: 4),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final startDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    final weekDates = List.generate(
      7,
      (index) => startDate.add(Duration(days: index)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kalender',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(selectedDate),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FFF1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// WEEK VIEW
            SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: weekDates.length,
                itemBuilder: (context, index) {
                  final date = weekDates[index];

                  final isSelected =
                      date.day == selectedDate.day &&
                      date.month == selectedDate.month &&
                      date.year == selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 56,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2ECC71)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E', 'id_ID').format(date),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeTodaySection() {
    final formattedDate =
        "${selectedDate.year}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('scheduled_meals')
          .where('date', isEqualTo: formattedDate)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Menu Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // KALAU BELUM ADA MENU
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                      const Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Color(0xFF2ECC71),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Belum Ada Menu",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Belum ada jadwal makanan untuk tanggal ini.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            // KALAU ADA MENU
            else
              SizedBox(
                height: 350,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final recipe = RecipeModel(
                      id: data['id'] ?? '',
                      title: data['title'] ?? '',
                      description: data['description'] ?? '',
                      imageUrl: data['image_url'] ?? '',
                      category: data['category'] ?? '',

                      price: (data['estimated_price'] as num?)?.toInt() ?? 0,

                      calories:
                          (data['estimated_calories'] as num?)?.toInt() ?? 0,
                      protein: (data['protein'] as num?)?.toInt() ?? 0,
                      carbs: (data['carbs'] as num?)?.toInt() ?? 0,
                      fats: (data['fats'] as num?)?.toInt() ?? 0,
                      sugars: (data['sugars'] as num?)?.toInt() ?? 0,
                      sodium: (data['sodium'] as num?)?.toInt() ?? 0,
                      fiber: (data['fiber'] as num?)?.toInt() ?? 0,

                      healthScore: (data['health_score'] as num?)?.toInt() ?? 0,
                      healthyLevel: data['healthy_level'] ?? '',
                      healthInsight: data['health_insight'] ?? '',
                      nutritionPerServing: data['nutrition_per_serving'] ?? '',

                      vitamins: VitaminsModel.fromJson(data['vitamins'] ?? {}),

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

                    return _buildRecipeCard(
                      recipe: recipe,
                      title: data['title'] ?? '',
                      calories: "${data['estimated_calories']} Calories",
                      price: "Rp ${data['estimated_price']}",
                      image: getFoodImage(data['title'] ?? ''),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard({
    required RecipeModel recipe,
    required String title,
    required String calories,
    required String price,
    required String image,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 330,

          width: 260,

          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),

          margin: const EdgeInsets.only(right: 50),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),

                blurRadius: 12,

                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // TITLE
                    Padding(
                      padding: const EdgeInsets.only(right: 85),

                      child: Text(
                        title,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontFamily: 'Poppins',

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // CALORIES
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,

                          color: Colors.red,

                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            calories,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 10,

                              color: Colors.grey,

                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // PRICE
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Color(0xFF2ECC71),
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            price,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),

                    // =====================
                    // HEALTH SCORE
                    // =====================
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "Health Score ${recipe.healthScore}/10",
                        style: const TextStyle(
                          color: Color(0xFF2ECC71),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    // =====================
                    // HEALTHY LEVEL
                    // =====================
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        recipe.healthyLevel,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    // =====================
                    // MINI MACRO
                    // =====================
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _buildMacroChip(
                          Icons.fitness_center,
                          "${recipe.protein}g",
                          Colors.blue,
                        ),

                        const SizedBox(width: 6),

                        _buildMacroChip(
                          Icons.rice_bowl,
                          "${recipe.carbs}g",
                          Colors.green,
                        ),

                        const SizedBox(width: 6),

                        _buildMacroChip(
                          Icons.opacity,
                          "${recipe.fats}g",
                          Colors.red,
                        ),
                      ],
                    ),

                    // =====================
                    // AI INSIGHT
                    // =====================
                    const SizedBox(height: 10),

                    Text(
                      recipe.healthInsight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 12),
                    // BUTTON
                    SizedBox(
                      width: 110,
                      height: 36,

                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),

                          padding: EdgeInsets.zero,

                          elevation: 0,
                        ),

                        child: const Text(
                          'Lihat Resep',

                          style: TextStyle(
                            fontFamily: 'Poppins',

                            fontSize: 13,

                            fontWeight: FontWeight.w600,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),
            ],
          ),
        ),

        Positioned(
          top: 20,
          right: 10,

          child: Container(
            width: 120,
            height: 120,

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
              radius: 60,
              backgroundColor: Colors.white,

              child: CircleAvatar(
                radius: 56,
                backgroundImage: AssetImage(image),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulationItem extends StatelessWidget {
  final String label;
  final String value;

  const _SimulationItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
