import 'package:flutter/material.dart';
import 'package:giziku/screens/profiles/about_screen.dart';
import 'package:giziku/screens/profiles/profile_detail_screen.dart';
import 'package:giziku/screens/profiles/shop_profile_screen.dart';
import 'profiles/faq_screen.dart';
import 'profiles/about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String name = "Jenny Perdana";
    final String email = "bagasakfa02@gmail.com";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 250, 
            decoration: const BoxDecoration(
              color: Color(0xFF2ECC71),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back Button
                Positioned(
                  top: 35,
                  left: 20,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Name & Email
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.yellow,
                      backgroundImage: const AssetImage('assets/profile/profile.png'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Menu List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                _ProfileMenuItem(
                  icon: 'assets/profile/profile.png',
                  label: 'My Profile',
                  bgColor: const Color(0xFFD4D4FC),
                  iconColor: null,
                  onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileDetailScreen()),
                        );
                  },
                ),
                _ProfileMenuItem(
                  icon: 'assets/profile/faq.png',
                  label: 'FAQ',
                  bgColor: const Color(0xFF9BFFD0),
                  iconColor: null,
                  onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FAQScreen()),
                        );
                    },
                ),
                _ProfileMenuItem(
                  icon: 'assets/profile/about.png',
                  label: 'About',
                  bgColor: const Color(0xFFE3D1FF),
                  iconColor: null,
                  onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                  },
                ),
                _ProfileMenuItem(
                  icon: 'profile/shops.png', 
                  label: 'My Shop',
                  bgColor: const Color(0xFFADE0FF),
                  iconColor: null,
                  onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreProfileScreen()),
                        );
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
      // BottomNavigationBar dihapus
    );
  }
}

// Widget untuk menu item profil
class _ProfileMenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color bgColor;
  final Color? iconColor; // null = tampilkan PNG asli
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    this.iconColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                  // Jangan gunakan color agar PNG asli tampil
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFFD9D9D9),
            ),
          ],
        ),
      ),
    );
  }
}