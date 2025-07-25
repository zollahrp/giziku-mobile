import 'package:flutter/material.dart';
import 'package:giziku/models/simulation_model.dart';
import 'package:giziku/repositories/simulation_repository.dart';
import '../../config/api_config.dart';
import 'simulation_loading.dart';

class SimulationOverviewScreen extends StatefulWidget {
  final int budget;
  final int days;
  final int people;

  const SimulationOverviewScreen({
    super.key,
    required this.budget,
    required this.days,
    required this.people,
  });

  @override
  State<SimulationOverviewScreen> createState() =>
      _SimulationOverviewScreenState();
}

class _SimulationOverviewScreenState extends State<SimulationOverviewScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _budgetController.text = widget.budget.toString();
    _daysController.text = widget.days.toString();
    _peopleController.text = widget.people.toString();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _daysController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _createSimulation() async {
    setState(() {
      _isLoading = true;
    });

    // Create the request
    final request = SimulationRequest(
      budget: int.parse(_budgetController.text),
      days: int.parse(_daysController.text),
      people: int.parse(_peopleController.text),
    );

    // Call the API
    final repository = SimulationRepository(baseUrl: ApiConfig.baseUrl);
    final response = await repository.createSimulation(request);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (response.success && response.data != null) {
      // Navigate to loading screen with the simulation ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SimulationLoadingScreen(simulationId: response.data!.id),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

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
                  onPressed: _isLoading ? null : _createSimulation,
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
