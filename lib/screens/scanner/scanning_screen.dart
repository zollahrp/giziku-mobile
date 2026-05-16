import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/food_scan_model.dart';
import '../../services/scanner_service.dart';
import 'scanner_result_screen.dart';

class ScanningScreen extends StatefulWidget {
  final File imageFile;

  const ScanningScreen({super.key, required this.imageFile});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController scanController;
  late Animation<double> scanAnimation;
  @override
  void initState() {
    super.initState();

    scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    scanAnimation = Tween<double>(
      begin: -110,
      end: 110,
    ).animate(CurvedAnimation(parent: scanController, curve: Curves.easeInOut));

    startScanning();
  }

  Future<void> startScanning() async {
    final result = await ScannerService().scanFood(widget.imageFile);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScannerResultScreen(result: result, imageFile: widget.imageFile),
      ),
    );
  }

  @override
  void dispose() {
    scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// AI SCANNING IMAGE
              Stack(
                alignment: Alignment.center,
                children: [
                  /// IMAGE
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.file(
                        widget.imageFile,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  /// SCANNING LINE
                  /// ANIMATED SCANNING LINE
                  AnimatedBuilder(
                    animation: scanAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, scanAnimation.value),

                        child: Container(
                          width: 240,
                          height: 4,

                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF2AD882),
                                Colors.transparent,
                              ],
                            ),

                            borderRadius: BorderRadius.circular(20),

                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2AD882).withOpacity(0.9),

                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  /// AI BADGE
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF2AD882),
                            size: 18,
                          ),

                          SizedBox(width: 8),

                          Text(
                            "AI Vision",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// TITLE
              const Text(
                "Sedang Menganalisa Makanan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                "AI sedang memproses gambar untuk\nmenghitung nutrisi dan kualitas makanan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 34),

              /// AI PROCESS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    scanningStep("Mendeteksi jenis makanan", true),

                    scanningStep("Menghitung kalori & protein", true),

                    scanningStep("Menganalisa kandungan nutrisi", true),

                    scanningStep("Membuat AI health insight", false),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

Widget scanningStep(String title, bool done) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        done
            ? Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF2AD882),
                  shape: BoxShape.circle,
                ),

                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            : SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: const Color(0xFF2AD882),
                ),
              ),

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: done ? const Color(0xFF111827) : const Color(0xFF2AD882),
            ),
          ),
        ),
      ],
    ),
  );
}
