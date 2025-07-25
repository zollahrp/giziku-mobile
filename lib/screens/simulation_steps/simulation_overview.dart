import 'package:flutter/material.dart';
import 'simulation_loading.dart';

class SimulationOverviewScreen extends StatelessWidget {
  const SimulationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 10),

              // Illustration
              Center(
                child: Image.asset(
                  'assets/simulation/overview.png',
                  height: 200,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Input fields
              const Text(
                'Budget',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Rp. 2.000.000',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: const BorderSide(color: Color(0xFF2ECC71)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Days',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: InputDecoration(
                  hintText: '3',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: const BorderSide(color: Color(0xFF2ECC71)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'People',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                decoration: InputDecoration(
                  hintText: '5',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: const BorderSide(color: Color(0xFF2ECC71)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              const Spacer(),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Tampilkan halaman loading ketika tombol Save ditekan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimulationLoadingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}