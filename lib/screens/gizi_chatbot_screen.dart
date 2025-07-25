import 'package:flutter/material.dart';

class GizikuChatbotScreen extends StatelessWidget {
  const GizikuChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2ECC71),
      body: Column(
        children: [
          // Header: Avatar + Title
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2ECC71),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.only(top: 48, bottom: 10),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/avatar_gizi_bot.png'), // Ganti dengan asset sesuai gambar
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Gizi Bot",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Chat area (kosong)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: const SizedBox(),
            ),
          ),
          // Bottom input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Plus button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FDFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF2ECC71), size: 24),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                // Input field (disabled/empty)
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FDFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation bar
          Container(
            color: const Color(0xFF2ECC71),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
                Container(
                  width: 56,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.android, color: Color(0xFF2ECC71), size: 28),
                    onPressed: () {},
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}