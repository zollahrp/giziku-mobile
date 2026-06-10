import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:giziku/screens/home_screen.dart';
import 'package:giziku/screens/profiles/edit_profile_screen.dart';
import 'package:giziku/screens/recipe_screen.dart';
import 'package:giziku/screens/profile_screen.dart';
import 'gizi_chatbot_screen.dart';
import 'scanner/scanner_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _screens = [
    HomeScreen(),
    RecipeScreen(),
    ScannerScreen(),
    GizikuChatbotScreen(),
    ProfileScreen(),
  ];

  Future<bool> checkProfileCompleted() async {
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
      if (!mounted) return false;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            title: const Text(
              'Profil Belum Lengkap',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                      builder: (_) => const EditProfileScreen(),
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen dibuild");
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: PhysicalModel(
            color: Colors.transparent,
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.3),
            child: CurvedNavigationBar(
              key: _bottomNavigationKey,
              index: _selectedIndex,
              height: 60,
              backgroundColor: Colors.transparent,
              color: const Color(0xFF2AD882),
              buttonBackgroundColor: const Color(0xFF2AD882),
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              items: const [
                Icon(Icons.home, size: 30, color: Colors.white),
                Icon(Icons.restaurant_menu, size: 30, color: Colors.white),
                Icon(
                  Icons.document_scanner_rounded,
                  size: 32,
                  color: Colors.white,
                ),
                Icon(Icons.chat_rounded, size: 30, color: Colors.white),
                Icon(Icons.person_outline, size: 30, color: Colors.white),
              ],
              onTap: (index) async {
                // PROFILE boleh dibuka kapan aja
                if (index == 4) {
                  setState(() {
                    _selectedIndex = index;
                  });

                  return;
                }

                final profileComplete = await checkProfileCompleted();

                if (!profileComplete) {
                  _bottomNavigationKey.currentState?.setPage(_selectedIndex);

                  return;
                }

                // ================= SCANNER =================
                if (index == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  );

                  _bottomNavigationKey.currentState?.setPage(_selectedIndex);

                  return;
                }

                // ================= NORMAL TAB =================
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
