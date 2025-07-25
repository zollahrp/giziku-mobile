import 'package:flutter/material.dart';
import 'simulation_steps/simulation_step1.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  bool _hasSimulationData = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Your Simulation',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Simulation Card atau No Data
              _hasSimulationData
              ? _buildActiveSimulationCard()
              : _buildNoDataSimulation(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildActiveSimulationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jenny Perdana',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimulationInfo("Budget", "-"),
              _buildSimulationInfo("Days", "-"),
              _buildSimulationInfo("People", "-"),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SimulationStep1()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Start Simulation',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF2ECC71),
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimulationInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildNoDataSimulation(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Card simulasi yang sama dengan yang ada data
          _buildActiveSimulationCard(),
          
          // Spacer untuk memberikan ruang antara card dan no data
          const SizedBox(height: 30),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/simulation/nodatasimulation.png',
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NO DATA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2ECC71),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60, 
      padding: const EdgeInsets.symmetric(vertical: 8), 
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.pie_chart, 'Simulation', 1, isSelected: true),
          
          Container(
            width: 45, 
            height: 45, 
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ECC71).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 22, 
            ),
          ),
          
          _buildNavItem(Icons.menu_book, 'Recipe', 3),
          _buildNavItem(Icons.person_outline, 'Profile', 4),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, int index, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 4) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF2ECC71) : Colors.grey,
            size: 22, 
          ),
          const SizedBox(height: 2), 
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              color: isSelected ? const Color(0xFF2ECC71) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  // Metode tidak lagi digunakan
}
