import 'package:flutter/material.dart';
import 'package:giziku/screens/simulation/simulation_budget_screen.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);

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
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey[600],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Nutrition Intake',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutritionItem('88', '/120', 'Carbs', 0.73, Colors.white),
                _buildNutritionItem('24', '/70', 'Protein', 0.34, Colors.white),
                _buildNutritionItem(
                  '32',
                  '/52',
                  'Vitamin',
                  0.62,
                  const Color(0xFF2ECC71),
                ),
              ],
            ),
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
                        'Calendar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
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
                            DateFormat('E').format(date),
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
                'Recipe Today',
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
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return _buildRecipeCard(
                      title: data['title'] ?? '',
                      calories: "${data['estimated_calories']} Calories",
                      price: "Rp ${data['estimated_price']}",
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
    required String title,
    required String calories,
    required String price,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.red,
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          calories,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Color(0xFF2ECC71),
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: 110,

                      child: ElevatedButton(
                        onPressed: () {},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),

                          padding: const EdgeInsets.symmetric(vertical: 5),

                          elevation: 0,
                        ),

                        child: const Text(
                          'See Recipe',
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

        const Positioned(
          top: 20,
          right: 10,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 56,
              backgroundImage: AssetImage('assets/recipe_today.png'),
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
