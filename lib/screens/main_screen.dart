import 'package:flutter/material.dart';
import 'package:gizify/screens/home_screen.dart';
import 'package:gizify/screens/maps_screen.dart';
import 'package:gizify/screens/meal_plan_screen.dart';
import 'package:gizify/screens/profiles/edit_profile_screen.dart';
import 'package:gizify/screens/recipe_screen.dart';
import 'package:gizify/screens/profile_screen.dart';
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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;

  // Pulse animation controller untuk tombol Scan di tengah
  late AnimationController _scanPulseController;

  // Urutan Layar: Home (0), Resep (1), Plan (2 - samping Resep), Gizibot (3), Peta (4), Profil (5)
  // Menggunakan getter agar langsung ter-refresh seketika saat Hot Reload tanpa tertahan cache state
  List<Widget> get _screens => [
    HomeScreen(),
    RecipeScreen(),
    const MealPlanScreen(),
    const GizifyChatbotScreen(),
    const MapsScreen(),
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

  // Nav Item Standar (Anti-Overflow, Responsif)
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
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF1EAB57).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active pill background di sekitar icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFECFDF5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? iconActive : iconInactive,
                    color: isSelected
                        ? const Color(0xFF1EAB57)
                        : const Color(0xFF94A3B8),
                    size: 21,
                  ),
                ),
                const SizedBox(height: 2),

                // Teks Label
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
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
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF1EAB57).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                // Spacer setinggi icon agar label "Scan" sejajar sempurna
                SizedBox(height: 27),
                SizedBox(height: 2),
                Text(
                  'Scan',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: const Color(0xFF1EAB57).withValues(alpha: 0.04),
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
              // Row Navigasi 7 Slot Sejajar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Home
                    _buildNavItem(
                      index: 0,
                      label: 'Home',
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

                    // 3. Plan (Rencana Menu Budget - Samping Resep!)
                    _buildNavItem(
                      index: 2,
                      label: 'Plan',
                      iconInactive: Icons.account_balance_wallet_outlined,
                      iconActive: Icons.account_balance_wallet_rounded,
                    ),

                    // 4. Center Placeholder untuk Tombol Scan
                    _buildCenterPlaceholder(),

                    // 5. Gizibot AI
                    _buildNavItem(
                      index: 3,
                      label: 'Gizibot',
                      iconInactive: Icons.smart_toy_outlined,
                      iconActive: Icons.smart_toy_rounded,
                    ),

                    // 6. Peta Belanja (Maps)
                    _buildNavItem(
                      index: 4,
                      label: 'Peta',
                      iconInactive: Icons.map_outlined,
                      iconActive: Icons.map_rounded,
                    ),

                    // 7. Profil Saya
                    _buildNavItem(
                      index: 5,
                      label: 'Profil',
                      iconInactive: Icons.person_outline_rounded,
                      iconActive: Icons.person_rounded,
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
                      width: 52,
                      height: 52,
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
                          size: 24,
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
