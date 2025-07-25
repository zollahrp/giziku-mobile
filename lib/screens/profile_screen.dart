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
        body: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2AD882),
                        Color(0xFF2ECC71),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
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
                ),

                const SizedBox(height: 80), // ruang untuk avatar
                // Menu List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.person,
                        label: 'My Profile',
                        bgColor: Color(0xFFD4D4FC),
                        iconColor: Colors.black,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileDetailScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.help_outline,
                        label: 'FAQ',
                        bgColor: Color(0xFF9BFFD0),
                        iconColor: Colors.black,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FAQScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.info_outline,
                        label: 'About',
                        bgColor: Color(0xFFE3D1FF),
                        iconColor: Colors.black,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'My Shop',
                        bgColor: Color(0xFFADE0FF),
                        iconColor: Colors.black,
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
  onPressed: () {
    // Navigasi ke halaman login dan hapus semua riwayat halaman sebelumnya
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF2ECC71),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 0,
  ),
  child: const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
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

            // Avatar - ditumpuk di atas header
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(2), // GANTI: dari 5 → 2
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2, // GANTI: dari 4 → 2
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.yellow,
                    backgroundImage: AssetImage('assets/profile/profile.png'),
                  ),
                ),
              ),
            ),
          ],
        ),
      // BottomNavigationBar dihapus
    );
  }
}

// Widget untuk menu item profil
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon; // GANTI dari String ke IconData
  final String label;
  final Color bgColor;
  final Color? iconColor;
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
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.black,
                  size: 24,
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