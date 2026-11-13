import 'package:flutter/material.dart';
import 'package:gizify/screens/home_screen.dart';
import 'package:gizify/screens/lainnya_screen.dart';
import 'package:gizify/screens/meal_plan_screen.dart';
import 'package:gizify/screens/profiles/edit_profile_screen.dart';
import 'package:gizify/screens/recipe_screen.dart';
import 'scanner/scanner_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;

  // Pulse animation controller untuk tombol Scan di tengah
  late AnimationController _scanPulseController;

  // 5 Tab Bersih & Lega ala Bank Jago:
  // 0: Beranda (Home)
  // 1: Resep (Katalog Makanan)
  // [Tengah]: Scan (Floating AI Vision)
  // 2: Plan (Rencana Menu & Budget)
  // 3: Lainnya (Hub Fitur: Gizibot AI, Peta Belanja, Profil, dll.)
  List<Widget> get _screens => [
    HomeScreen(),
    RecipeScreen(),
    const MealPlanScreen(),
    const LainnyaScreen(),
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
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
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

    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanPulseController.dispose();
    super.dispose();
  }

  Future<void> _onTabTapped(int index) async {
    // Menu "Lainnya" (index 3) selalu bisa diakses kapan saja
    if (index == 3) {
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

  // Nav Item Modern Ala Bank Jago (Spacious, Tap Target Lebar, Micro-interaction)
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData iconInactive,
    required IconData iconActive,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF1EAB57).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active pill background di sekitar icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFECFDF5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? iconActive : iconInactive,
                    color: isSelected
                        ? const Color(0xFF1EAB57)
                        : const Color(0xFF94A3B8),
                    size: 23,
                  ),
                ),
                const SizedBox(height: 3),

                // Teks Label Bersih
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1EAB57)
                        : const Color(0xFF94A3B8),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder slot tengah untuk menjaga spacing & menaruh label "Scan"
  Widget _buildCenterPlaceholder() {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openScanner,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF1EAB57).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                // Spacer setinggi icon agar label "Scan" sejajar sempurna
                SizedBox(height: 31),
                SizedBox(height: 3),
                Text(
                  'Scan',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1EAB57),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: const Color(0xFF1EAB57).withValues(alpha: 0.03),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true, // Pastikan tidak tertutup tombol back/home sistem Android
          minimum: const EdgeInsets.only(bottom: 6),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Row Navigasi 5 Slot Sejajar Ala Bank Jago
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Beranda (Home)
                    _buildNavItem(
                      index: 0,
                      label: 'Beranda',
                      iconInactive: Icons.home_outlined,
                      iconActive: Icons.home_rounded,
                    ),

                    // 2. Resep
                    _buildNavItem(
                      index: 1,
                      label: 'Resep',
                      iconInactive: Icons.menu_book_outlined,
                      iconActive: Icons.menu_book_rounded,
                    ),

                    // 3. Center Placeholder untuk Tombol Scan
                    _buildCenterPlaceholder(),

                    // 4. Plan (Meal Planner & Budget)
                    _buildNavItem(
                      index: 2,
                      label: 'Plan',
                      iconInactive: Icons.account_balance_wallet_outlined,
                      iconActive: Icons.account_balance_wallet_rounded,
                    ),

                    // 5. Lainnya (Hub Fitur Ala Bank Jago: Gizibot, Peta, Profil, dll.)
                    _buildNavItem(
                      index: 3,
                      label: 'Lainnya',
                      iconInactive: Icons.grid_view_outlined,
                      iconActive: Icons.grid_view_rounded,
                    ),
                  ],
                ),
              ),

              // Tombol Floating Scanner di Tengah (Melayang Rapi di atas Text 'Scan')
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: _openScanner,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                      CurvedAnimation(
                        parent: _scanPulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1EAB57), Color(0xFF0D5929)],
                        ),
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1EAB57).withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
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
