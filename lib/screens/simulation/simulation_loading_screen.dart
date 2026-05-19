import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/simulation_service.dart';
import 'simulation_result_screen.dart';

class SimulationLoadingScreen extends StatefulWidget {
  final int budget;
  final int days;
  final int people;

  const SimulationLoadingScreen({
    super.key,
    required this.budget,
    required this.days,
    required this.people,
  });

  @override
  State<SimulationLoadingScreen> createState() =>
      _SimulationLoadingScreenState();
}

class _SimulationLoadingScreenState extends State<SimulationLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  int currentMessageIndex = 0;

  final List<String> loadingMessages = [
    "Menganalisis budget makanan...",
    "Menghitung kebutuhan nutrisi...",
    "Menyesuaikan porsi makanan...",
    "Mencari menu terbaik...",
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    startLoading();
  }

  Future<void> startLoading() async {
    // LANGSUNG START REQUEST
    final futureResult = SimulationService().generateMealPlan(
      budget: widget.budget,
      days: widget.days,
      people: widget.people,
    );

    // ANIMASI LOADING JALAN PARALEL
    for (int i = 0; i < loadingMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      setState(() {
        currentMessageIndex = i;
      });
    }

    try {
      final result = await futureResult;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimulationResultScreen(
            budget: widget.budget,
            days: widget.days,
            people: widget.people,
            aiResult: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal generate rekomendasi: $e')));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // AI Circle Animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 6.3,
                        child: Container(
                          width: 95,
                          height: 95,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                const Color(0xFF2ECC71),
                                const Color(0xFF2ECC71).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 38,
                              color: Color(0xFF2ECC71),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Title
                  const Text(
                    "Giziku Sedang Membuat\nRencana Makananmu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "Tunggu sebentar, kami sedang menyesuaikan menu terbaik untukmu.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Loading Messages
                  Column(
                    children: List.generate(loadingMessages.length, (index) {
                      final isActive = index <= currentMessageIndex;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: isActive ? 1 : 0.35,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF2ECC71).withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF2ECC71)
                                      : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? Icons.check : Icons.more_horiz,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  loadingMessages[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.black
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

                  const SizedBox(height: 28),

                  // Bottom Info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFF2ECC71),
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "Giziku akan membuat rekomendasi menu berdasarkan budget, durasi, dan jumlah orang.",
                            style: TextStyle(
                              height: 1.5,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
