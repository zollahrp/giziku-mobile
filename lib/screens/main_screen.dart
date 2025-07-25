import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:giziku/screens/home_screen.dart';
import 'package:giziku/screens/recipe_screen.dart';
import 'package:giziku/screens/profile_screen.dart';
import 'gizi_chatbot_screen.dart';

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
    GizikuChatbotScreen(),
    ProfileScreen(),
  ];

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
      bottomNavigationBar: PhysicalModel(
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
            Icon(Icons.home, size: 30, color: Color.fromARGB(255, 255, 255, 255)),
            Icon(Icons.restaurant_menu, size: 30, color: Color.fromARGB(255, 255, 255, 255)),
            Icon(Icons.chat_rounded, size: 30, color: Color.fromARGB(255, 255, 255, 255)),
            Icon(Icons.person_outline, size: 30, color: Color.fromARGB(255, 255, 255, 255)),
          
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
