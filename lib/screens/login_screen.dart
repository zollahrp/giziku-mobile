import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              // ================= TOP =================
              Padding(
                padding: const EdgeInsets.only(top: 6),

                child: Image.asset(
                  'assets/gizikulogohitam.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),

              // ================= IMAGE =================
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/login_hero.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ================= TEXT =================
              const Text(
                'Makan sehat,\nlebih pintar.',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Atur pola makan sehat dengan bantuan AI, rekomendasi nutrisi personal, dan meal plan sesuai kebutuhan tubuhmu.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 40),

              // ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(
                  onPressed: () async {
                    final authService = context.read<AuthService>();

                    final success = await authService.signInWithGoogle();

                    if (success) {
                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      );
                    } else {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authService.errorMessage ?? 'Google Login Failed',
                          ),
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Container(
                        width: 32,
                        height: 32,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(6),

                          child: Image.network(
                            'https://cdn-icons-png.flaticon.com/512/281/281764.png',
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Text(
                        'Lanjut dengan Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  'Dengan melanjutkan, kamu menyetujui Syarat & Kebijakan Privasi kami',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
