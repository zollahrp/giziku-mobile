import 'dart:async';
import 'package:flutter/material.dart';
import 'package:giziku/models/simulation_model.dart';
import 'package:giziku/repositories/simulation_repository.dart';
import '../../config/api_config.dart';
import '../home_screen.dart'; // Correct import path

class SimulationLoadingScreen extends StatefulWidget {
  final int? simulationId;

  const SimulationLoadingScreen({super.key, this.simulationId});

  @override
  State<SimulationLoadingScreen> createState() =>
      _SimulationLoadingScreenState();
}

class _SimulationLoadingScreenState extends State<SimulationLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 3;
  int _currentDot = 0;
  late Timer _dotTimer;
  late Timer _doneTimer;

  SimulationResult? simulationResult;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Text animation
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentDot = (_currentDot + 1) % (_dotCount + 1);
      });
    });

    // Fetch the simulation data if we have an ID
    if (widget.simulationId != null) {
      _fetchSimulationData(widget.simulationId!);
    } else {
      // If no ID is provided, just show loading and redirect after a few seconds
      _showCompletionMessage();
    }
  }

  Future<void> _fetchSimulationData(int id) async {
    try {
      final repository = SimulationRepository(baseUrl: ApiConfig.baseUrl);
      final response = await repository.getSimulationById(id);

      if (response.success && response.data != null) {
        setState(() {
          simulationResult = response.data;
        });
        _showCompletionMessage();
      } else {
        setState(() {
          isError = true;
        });
        _showErrorMessage(response.message);
      }
    } catch (e) {
      setState(() {
        isError = true;
      });
      _showErrorMessage('Error fetching simulation data: $e');
    }
  }

  void _showCompletionMessage() {
    _doneTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeay Perencanaan Makan Siap !'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2ECC71),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotTimer.cancel();
    if (_doneTimer.isActive) {
      _doneTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingText =
        "Setting up your nutrition plan\nand analyzing your goals" +
        "." * _currentDot;
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2ECC71),
                          ),
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
