import 'package:flutter/material.dart';
import 'package:giziku/screens/simulation_steps/simulation_step1.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDayIndex = 3; // Default: Wednesday
  final List<String> _daysShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<int> _dates = [1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(formattedDate),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildActiveSimulationCard(),
              ),
              const SizedBox(height: 15),
              _buildNutritionSection(),
              const SizedBox(height: 15),
              _buildDateSelector(),
              const SizedBox(height: 15),
              _buildRecipeTodaySection(),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 25),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Jenny!',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE7FCF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.notifications_outlined, color: Color(0xFF2ECC71), size: 22),
            ),
          ),
        ],
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              // STATIC VALUES:
              _SimulationItem(label: "Budget", value: "Rp 500.000"),
              _SimulationItem(label: "Days", value: "3 Days"),
              _SimulationItem(label: "People", value: "4 People"),
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

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Nutrition Intake',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutritionItem('88', '/120', 'Carbs', 0.73, Colors.white),
                _buildNutritionItem('24', '/70', 'Protein', 0.34, Colors.white),
                _buildNutritionItem('32', '/52', 'Vitamin', 0.62, const Color(0xFF2ECC71)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionItem(String value, String total, String label, double percent, Color progressColor) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
            ),
            Text(
              total,
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400], fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          width: 75.0,
          lineHeight: 4.0,
          percent: percent,
          backgroundColor: Colors.grey[700],
          progressColor: progressColor,
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(10),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          itemBuilder: (context, index) {
            bool isSelected = index == _selectedDayIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: Container(
                width: 42,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF2ECC71), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_daysShort[index],
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 4),
                    Text(_dates[index].toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                            fontFamily: 'Poppins')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecipeTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Recipe Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              return _buildRecipeCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(right: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Green Box',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.local_fire_department, color: Colors.red, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '280 Calories',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.attach_money, color: Color(0xFF2ECC71), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Estimated Cost: Rp 149.000',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          elevation: 0,
                        ),
                        child: const Text(
                          'See Recipe',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const Positioned(
          top: 20,
          right: 10,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 56,
              backgroundImage: AssetImage('assets/recipe_today.png'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulationItem extends StatelessWidget {
  final String label;
  final String value;

  const _SimulationItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
