import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/food_scan_model.dart';

class ScannerResultScreen extends StatelessWidget {
  final FoodScanModel result;
  final File imageFile;

  const ScannerResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
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
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(30),
                child: Image.file(
                  imageFile,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                result.foodName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              nutritionTile(
                Icons.local_fire_department,
                "Calories",
                "${result.calories} kcal",
                Colors.orange,
              ),

              nutritionTile(
                Icons.fitness_center,
                "Protein",
                "${result.protein} g",
                Colors.blue,
              ),

              nutritionTile(
                Icons.rice_bowl,
                "Carbs",
                "${result.carbs} g",
                Colors.green,
              ),

              nutritionTile(
                Icons.opacity,
                "Fats",
                "${result.fats} g",
                Colors.red,
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2AD882)
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(24),
                ),
                child: Text(
                  "Health Score: ${result.healthScore}/10",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2AD882),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}