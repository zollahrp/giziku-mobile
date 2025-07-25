import 'package:flutter/material.dart';
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // About image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Image.asset(
                'profile/aboutsc.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              "About",
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea.\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}