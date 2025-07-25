import 'package:flutter/material.dart';
import '../profile_screen.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> questions = [
      "What is Lorem Ipsum?",
      "What is Lorem Ipsum?",
      "What is Lorem Ipsum?",
      "What is Lorem Ipsum?",
      "What is Lorem Ipsum?",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                      onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
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
            const SizedBox(height: 10),
            // Title
            const Text(
              "Frequently Asked\nQuestions",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),
            // FAQ List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.09)),
                    ),
                    child: ListTile(
                      title: Text(
                        questions[index],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: Colors.black87,
                      ),
                      onTap: () {
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}