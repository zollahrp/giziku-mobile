import 'package:flutter/material.dart';
import 'simulation_step2.dart';

class SimulationStep1 extends StatefulWidget {
  const SimulationStep1({super.key});

  @override
  State<SimulationStep1> createState() => _SimulationStep1State();
}

class _SimulationStep1State extends State<SimulationStep1> {
  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepCircle(1, true),
                _buildStepLine(),
                _buildStepCircle(2, false),
                _buildStepLine(),
                _buildStepCircle(3, false),
              ],
            ),
            const SizedBox(height: 40),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: 'How much '),
                  TextSpan(text: 'budget ', style: TextStyle(color: Color(0xFF2ECC71))),
                  TextSpan(text: 'do you\nspend on food?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We will use this data to give you\na better nutrition type for you',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Rp',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Your Budget',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SimulationStep2()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71),
                      blurRadius: 0,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),

        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2ECC71) : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 32,
      height: 2,
      color: Colors.grey.shade300,
    );
  }
}
