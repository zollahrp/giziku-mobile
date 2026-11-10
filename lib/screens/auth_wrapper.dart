import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getScreen() async {

    final prefs =
        await SharedPreferences.getInstance();

    final onboardingDone =
        prefs.getBool('onboarding_done') ?? false;

    final rememberMe =
        prefs.getBool('remember_me') ?? true;

    final user =
        FirebaseAuth.instance.currentUser;

    // ================= BELUM ONBOARDING =================
    if (!onboardingDone) {
      return OnboardingScreen(
        nextScreen: const LoginScreen(),
      );
    }

    // ================= SUDAH LOGIN =================
    if (user != null) {
      if (!rememberMe) {
        // User memilih untuk tidak mengingat sesi saat login
        await FirebaseAuth.instance.signOut();
        return const LoginScreen();
      }
      return const MainScreen();
    }

    // ================= BELUM LOGIN =================
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getScreen(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}