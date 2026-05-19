import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:giziku/screens/profiles/edit_profile_screen.dart';

class ProfileChecker {
  static Future<bool> checkProfileCompleted(
    BuildContext context,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data() ?? {};

    bool isIncomplete(dynamic value) {
      if (value == null) return true;

      if (value is String && value.trim().isEmpty) {
        return true;
      }

      if (value is List && value.isEmpty) {
        return true;
      }

      return false;
    }

    final requiredFields = [
      data['name'],
      data['gender'],
      data['date_of_birth'],
      data['height'],
      data['weight'],
      data['daily_calories'],
      data['activity_level'],
      data['exercise_level'],
      data['body_goal'],
      data['food_type'],
    ];

    final profileComplete = !requiredFields.any(isIncomplete);

    if (!profileComplete) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            title: const Text(
              'Profil Belum Lengkap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            content: const Text(
              'Lengkapi profil terlebih dahulu untuk menggunakan fitur ini.',
              style: TextStyle(height: 1.5),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'Nanti',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const EditProfileScreen(),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                ),

                child: const Text(
                  'Lengkapi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }
}