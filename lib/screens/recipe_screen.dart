import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../screens/recipe/recipe_detail_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int _selectedDayIndex = 0;

  final List<String> _daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<int> _dates = [22, 23, 24, 25, 26, 27, 28];

  // Dummy recipes data
  final List<RecipeModel> _recipes = [
    RecipeModel(
      id: "1",
      title: "Caesar Roasted Bowl",
      imageUrl: "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?fit=crop&w=400&q=80",
      category: "Veggie",
      price: 149000,
      nutrition: 220,
      nutritionUnit: "g",
      prepTime: 10,
      cookTime: 10,
      totalTime: 20,
      description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      ingredients: [
        RecipeIngredient(name: "Cooked rice", amount: "1 Cup"),
        RecipeIngredient(name: "Roasted tofu or tempeh", amount: "1/2 Cup"),
        RecipeIngredient(name: "Boiled Egg", amount: "1/2 Cup"),
        RecipeIngredient(name: "Tomato or cucumber", amount: "1 Slice"),
        RecipeIngredient(name: "Broccoli", amount: "1/2 cup"),
      ],
      instructions: [
        "Mix all ingredients in a bowl.",
        "Serve with your favorite sauce.",
      ],
    ),
    RecipeModel(
      id: "2",
      title: "Green Box",
      imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?fit=crop&w=400&q=80",
      category: "Veggie",
      price: 99000,
      nutrition: 280,
      nutritionUnit: "Calories",
      prepTime: 8,
      cookTime: 7,
      totalTime: 15,
      description: "A healthy and delicious green salad bowl for your daily nutrition.",
      ingredients: [
        RecipeIngredient(name: "Spinach", amount: "70g"),
        RecipeIngredient(name: "Avocado", amount: "1/2"),
        RecipeIngredient(name: "Egg", amount: "1"),
        RecipeIngredient(name: "Quinoa", amount: "1 Cup"),
      ],
      instructions: [
        "Prepare all ingredients.",
        "Boil the egg and quinoa.",
        "Mix with spinach and avocado.",
        "Serve fresh.",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/gizikulabel.png',
                      width: 100,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Let’s find Your\nHealty Food!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 16),

              // Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/banner.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Categories Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildCategoryTabs(),

              const SizedBox(height: 24),

              // Recipe Cards
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recipes.length,
                  itemBuilder: (context, idx) {
                    return _buildRecipeCard(_recipes[idx]);
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search recipe in Giziku',
            hintStyle: TextStyle(fontFamily: 'Poppins'),
            suffixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildCategoryPill("Veggie", isSelected: true),
          const SizedBox(width: 10),
          _buildCategoryPill("Meat"),
          const SizedBox(width: 10),
          _buildCategoryPill("Meat"),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2ECC71) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Stack(
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
                // Left Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.red, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.nutrition} ${recipe.nutritionUnit}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Color(0xFF2ECC71), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Estimated Cost: Rp ${recipe.price}',
                            style: const TextStyle(
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
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
                // Empty space to let image float
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 56,
                backgroundImage: NetworkImage(recipe.imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}