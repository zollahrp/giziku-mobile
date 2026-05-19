import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/food_scan_model.dart';

class ScannerResultScreen extends StatelessWidget {
  final FoodScanModel result;
  final File imageFile;

  const ScannerResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  Widget nutritionCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Text(
                    "Hasil AI Scanner",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// FOOD IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.file(
                  imageFile,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              /// FOOD NAME
              Text(
                result.foodName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              /// STATUS CARD
              /// STATUS SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    /// EDIBLE STATUS
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: result.isEdible
                                ? const Color(0xFF2AD882).withOpacity(0.12)
                                : Colors.red.withOpacity(0.10),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: Icon(
                            result.isEdible
                                ? Icons.verified_rounded
                                : Icons.close_rounded,

                            color: result.isEdible
                                ? const Color(0xFF2AD882)
                                : Colors.red,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                result.isEdible
                                    ? "Layak Dikonsumsi"
                                    : "Tidak Layak Konsumsi",

                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                result.isEdible
                                    ? "AI mendeteksi makanan masih aman dikonsumsi"
                                    : "AI mendeteksi kualitas makanan kurang baik",

                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Divider(color: Colors.grey.shade200, height: 1),

                    const SizedBox(height: 18),

                    /// HEALTH LEVEL
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2AD882).withOpacity(0.12),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFF2AD882),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                result.healthyLevel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Berdasarkan nutrisi dan kandungan makanan",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// HEALTH SCORE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2AD882).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Health Score ${result.healthScore}/10",
                  style: const TextStyle(
                    color: Color(0xFF2AD882),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// MACRO GRID
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  nutritionCard(
                    Icons.local_fire_department,
                    "Kalori",
                    "${result.calories}",
                    Colors.orange,
                  ),

                  nutritionCard(
                    Icons.fitness_center,
                    "Protein",
                    "${result.protein}g",
                    Colors.blue,
                  ),

                  nutritionCard(
                    Icons.rice_bowl,
                    "Karbo",
                    "${result.carbs}g",
                    Colors.green,
                  ),

                  nutritionCard(
                    Icons.opacity,
                    "Lemak",
                    "${result.fats}g",
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// DETAIL CARD
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informasi Nutrisi",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    infoTile("Takaran Saji", result.estimatedServing),

                    infoTile("Gula", "${result.sugars} g"),

                    infoTile("Sodium", "${result.sodium} mg"),

                    infoTile("Serat", "${result.fiber} g"),

                    infoTile("Vitamin A", result.vitamins.vitaminA),

                    infoTile("Vitamin C", result.vitamins.vitaminC),

                    infoTile("Zat Besi", result.vitamins.iron),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              /// AI INSIGHT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2AD882).withOpacity(0.18),
                      Colors.greenAccent.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Insight",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      result.healthInsight,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) return;

                    final today = DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.now());

                    final docRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('daily_nutrition')
                        .doc(today);

                    await FirebaseFirestore.instance.runTransaction((
                      transaction,
                    ) async {
                      final snapshot = await transaction.get(docRef);

                      if (!snapshot.exists) {
                        transaction.set(docRef, {
                          'calories': result.calories,
                          'protein': result.protein,
                          'carbs': result.carbs,
                          'fats': result.fats,
                          'updated_at': FieldValue.serverTimestamp(),
                        });
                      } else {
                        final data = snapshot.data()!;

                        transaction.update(docRef, {
                          'calories': (data['calories'] ?? 0) + result.calories,
                          'protein': (data['protein'] ?? 0) + result.protein,
                          'carbs': (data['carbs'] ?? 0) + result.carbs,
                          'fats': (data['fats'] ?? 0) + result.fats,
                          'updated_at': FieldValue.serverTimestamp(),
                        });
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nutrisi berhasil ditambahkan!"),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AD882),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),

                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_rounded, color: Colors.white),

                      SizedBox(width: 12),

                      Text(
                        "Makan Makanan Ini",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
