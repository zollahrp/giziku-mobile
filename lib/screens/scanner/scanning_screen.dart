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

  int currentStep = 0;

  final List<String> scanningSteps = [
    "Mendeteksi jenis makanan",
    "Menghitung kalori & protein",
    "Menganalisa kandungan nutrisi",
    "Membuat Gizify health insight",
  ];

  Future<void> startScanning() async {
    final futureResult = ScannerService().scanFood(widget.imageFile);

    for (int i = 0; i < scanningSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 850));

      if (!mounted) return;

      setState(() {
        currentStep = i;
      });
    }

    final result = await futureResult;

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
                            "Gizify Vision",
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

              const SizedBox(height: 36),

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
                  children: List.generate(scanningSteps.length, (index) {
                    final isActive = index <= currentStep;
                    final isCurrent = index == currentStep;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 450),
                      opacity: isActive ? 1 : 0.35,

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),

                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF2AD882).withOpacity(0.2)
                                : Colors.transparent,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: isCurrent
                                  ? const Color(0xFF2AD882).withOpacity(0.12)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 30,
                              height: 30,

                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF2AD882)
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),

                              child: isCurrent
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isActive
                                          ? Icons.check
                                          : Icons.more_horiz_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Text(
                                scanningSteps[index],
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? const Color(0xFF111827)
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
