import 'package:flutter/material.dart';
import 'package:gizify/screens/home_screen.dart';
import 'package:gizify/screens/maps_screen.dart';
import 'package:gizify/screens/profiles/edit_profile_screen.dart';
import 'package:gizify/screens/recipe_screen.dart';
import 'package:gizify/screens/profile_screen.dart';
import 'package:gizify/screens/simulation/simulation_budget_screen.dart';
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

  final List<Widget> _screens = [
    HomeScreen(),
    RecipeScreen(),
    const MapsScreen(),
    const GizifyChatbotScreen(),
    const SimulationBudgetScreen(),
    ProfileScreen(),
  ];

  Future<bool> checkProfileCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    bool isIncomplete(dynamic value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      if (value is List && value.isEmpty) return true;
      return false;
    }

    final requiredFields = [
      data['name'],
      data['gender'],
      data['date_of_birth'] ?? data['birthDate'] ?? data['dateOfBirth'],
      data['height'],
      data['weight'],
      data['daily_calories'] ?? data['calories'] ?? data['dailyCalories'],
      data['activity_level'] ?? data['activity'] ?? data['activityLevel'],
      data['exercise_level'] ?? data['exercise'] ?? data['exerciseLevel'],
      data['body_goal'] ?? data['bodyGoal'],
      data['food_type'] ?? data['dietTypes'] ?? data['dietType'],
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
                onPressed: () => Navigator.pop(context),
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
                  backgroundColor: const Color(0xFF1EAB57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lengkapi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }
  }

  Future<void> _onTabTapped(int index) async {
    // Profil (index 5) selalu bisa diakses kapan saja
    if (index == 5) {
      setState(() => _selectedIndex = index);
      return;
    }

    final profileComplete = await checkProfileCompleted();
    if (!profileComplete) return;

    setState(() => _selectedIndex = index);
  }

  Future<void> _openScanner() async {
    final profileComplete = await checkProfileCompleted();
    if (!profileComplete) return;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData iconInactive,
    required IconData iconActive,
    required String tooltip,
  }) {
    final isSelected = _selectedIndex == index;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1EAB57).withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1EAB57).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isSelected ? iconActive : iconInactive,
              color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF94A3B8),
              size: isSelected ? 22 : 21,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // White Bottom Bar matching Web layout
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kiri: Home, Resep, Maps
                    _buildNavItem(
                      index: 0,
                      iconInactive: Icons.home_outlined,
                      iconActive: Icons.home_rounded,
                      tooltip: 'Ringkasan Harian',
                    ),
                    _buildNavItem(
                      index: 1,
                      iconInactive: Icons.menu_book_outlined,
                      iconActive: Icons.menu_book_rounded,
                      tooltip: 'Katalog Resep',
                    ),
                    _buildNavItem(
                      index: 2,
                      iconInactive: Icons.map_outlined,
                      iconActive: Icons.map_rounded,
                      tooltip: 'Peta Belanja',
                    ),

                    // Spacer di tengah untuk Floating Scanner Button
                    const SizedBox(width: 54),

                    // Kanan: Chatbot, Meal Plan, Profile
                    _buildNavItem(
                      index: 3,
                      iconInactive: Icons.smart_toy_outlined,
                      iconActive: Icons.smart_toy_rounded,
                      tooltip: 'Tanya GiziBot',
                    ),
                    _buildNavItem(
                      index: 4,
                      iconInactive: Icons.account_balance_wallet_outlined,
                      iconActive: Icons.account_balance_wallet_rounded,
                      tooltip: 'Rencana Menu Budget',
                    ),
                    _buildNavItem(
                      index: 5,
                      iconInactive: Icons.person_outline_rounded,
                      iconActive: Icons.person_rounded,
                      tooltip: 'Profil Saya',
                    ),
                  ],
                ),
              ),
            ),

            // Tombol Scanner Melayang Tengah (Floating Action Scan)
            Positioned(
              top: -22,
              child: Tooltip(
                message: 'Scan Makanan',
                child: GestureDetector(
                  onTap: _openScanner,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1EAB57), Color(0xFF0D5929)],
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1EAB57).withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
