import 'dart:async';
import 'package:flutter/material.dart';
import '../home_screen.dart';

class SimulationLoadingScreen extends StatefulWidget {
  const SimulationLoadingScreen({super.key});

  @override
  State<SimulationLoadingScreen> createState() => _SimulationLoadingScreenState();
}

class _SimulationLoadingScreenState extends State<SimulationLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 3;
  int _currentDot = 0;
  late Timer _dotTimer;
  late Timer _doneTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Teks animasi ...
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentDot = (_currentDot + 1) % (_dotCount + 1);
      });
    });

   _doneTimer = Timer(const Duration(seconds: 3), () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeay Perencanaan Makan Siap !'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2ECC71),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotTimer.cancel();
    _doneTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingText = "Setting up your nutrition plan\nand analyzing your goals" + "." * _currentDot;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFEBFAF3),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/simulation/simulationload.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Preparing your plan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loadingText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}