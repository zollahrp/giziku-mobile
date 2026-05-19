import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NutritionDetailScreen extends StatelessWidget {
  const NutritionDetailScreen({super.key});

  Widget nutritionTile(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        centerTitle: true,

        title: const Text(
          "Nutrisi Harian",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('daily_nutrition')
            .doc(today)
            .snapshots(),

        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final calories = data?['calories'] ?? 0;
          final protein = data?['protein'] ?? 0;
          final carbs = data?['carbs'] ?? 0;
          final fats = data?['fats'] ?? 0;
          final sugars = data?['sugars'] ?? 0;
          final sodium = data?['sodium'] ?? 0;
          final fiber = data?['fiber'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2ECC71),
                        Color(0xFF27AE60),
                      ],
                    ),

                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kalori Hari Ini",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "$calories kcal",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value: (calories / 2200).clamp(0.0, 1.0),
                        minHeight: 10,

                        backgroundColor: Colors.white24,

                        valueColor: const AlwaysStoppedAnimation(
                          Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Target Harian 2200 kcal",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Detail Nutrisi",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                nutritionTile(
                  Icons.fitness_center,
                  "Protein",
                  "${protein} g",
                  Colors.blue,
                ),

                nutritionTile(
                  Icons.rice_bowl,
                  "Karbohidrat",
                  "${carbs} g",
                  Colors.orange,
                ),

                nutritionTile(
                  Icons.opacity,
                  "Lemak",
                  "${fats} g",
                  Colors.red,
                ),

                nutritionTile(
                  Icons.cake,
                  "Gula",
                  "${sugars} g",
                  Colors.pink,
                ),

                nutritionTile(
                  Icons.water_drop,
                  "Sodium",
                  "${sodium} mg",
                  Colors.teal,
                ),

                nutritionTile(
                  Icons.grass,
                  "Serat",
                  "${fiber} g",
                  Colors.green,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}