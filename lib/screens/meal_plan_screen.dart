import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ==========================================
// SMART FOOD IMAGE MATCHER (SINKRON DENGAN WEB)
// ==========================================
String getMealFoodImage(String title, {String? category}) {
  final lower = '$title ${category ?? ''}'.toLowerCase();

  if (lower.contains('nasi goreng') || lower.contains('fried rice')) {
    return 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('nasi') || lower.contains('rice') || lower.contains('bubur')) {
    return 'https://images.unsplash.com/photo-1541832676-9b763b0239ab?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('ayam bakar') || lower.contains('panggang') || lower.contains('grilled chicken') || lower.contains('rosemary')) {
    return 'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('ayam') || lower.contains('chicken') || lower.contains('katsu') || lower.contains('geprek')) {
    return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('rendang') || lower.contains('daging') || lower.contains('beef') || lower.contains('steak')) {
    return 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('sate') || lower.contains('satay') || lower.contains('taichan')) {
    return 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('bakso') || lower.contains('meatball')) {
    return 'https://images.unsplash.com/photo-1529042410759-befb1204b468?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('sup') || lower.contains('soup') || lower.contains('soto') || lower.contains('lodeh') || lower.contains('kuah')) {
    return 'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('salmon') || lower.contains('tuna') || lower.contains('dori') || lower.contains('ikan') || lower.contains('fish')) {
    return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('udang') || lower.contains('shrimp') || lower.contains('seafood')) {
    return 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('salad') || lower.contains('selada') || lower.contains('alpukat')) {
    return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('oatmeal') || lower.contains('smoothie') || lower.contains('naga') || lower.contains('chia')) {
    return 'https://images.unsplash.com/photo-1548807371-30dc1bbe6cb5?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('telur') || lower.contains('egg') || lower.contains('omelette') || lower.contains('roti') || lower.contains('toast')) {
    return 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('mie') || lower.contains('noodle') || lower.contains('ramen') || lower.contains('pasta') || lower.contains('spaghetti')) {
    return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('tempe') || lower.contains('tahu') || lower.contains('tofu')) {
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop';
  }
  if (lower.contains('sayur') || lower.contains('tumis') || lower.contains('bayam') || lower.contains('kangkung') || lower.contains('brokoli')) {
    return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=800&auto=format&fit=crop';
  }

  return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=800&auto=format&fit=crop';
}

// ==========================================
// MODELS UNTUK MEAL PLAN (JSON HYBRID WEB)
// ==========================================
class MealPlanData {
  final String budget;
  final String days;
  final String people;
  final String currency;
  final String startDate;
  final List<MealPlanDay> plan;

  MealPlanData({
    required this.budget,
    required this.days,
    required this.people,
    required this.currency,
    required this.startDate,
    required this.plan,
  });

  factory MealPlanData.fromJson(Map<String, dynamic> json) {
    return MealPlanData(
      budget: json['budget']?.toString() ?? '100.000',
      days: json['days']?.toString() ?? '2',
      people: json['people']?.toString() ?? '1',
      currency: json['currency']?.toString() ?? 'IDR',
      startDate: json['startDate']?.toString() ?? '',
      plan: (json['plan'] as List? ?? [])
          .map((e) => MealPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'budget': budget,
        'days': days,
        'people': people,
        'currency': currency,
        'startDate': startDate,
        'plan': plan.map((e) => e.toJson()).toList(),
      };
}

class MealPlanDay {
  final int day;
  final List<MealPlanItem> meals;

  MealPlanDay({required this.day, required this.meals});

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    return MealPlanDay(
      day: json['day'] is int ? json['day'] : int.tryParse(json['day']?.toString() ?? '1') ?? 1,
      meals: (json['meals'] as List? ?? [])
          .map((e) => MealPlanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'meals': meals.map((e) => e.toJson()).toList(),
      };
}

class MealPlanItem {
  final String id;
  final String type; // Sarapan, Makan Siang, Makan Malam
  final String time; // 07:00, 12:30, 19:00
  final String title;
  final String category;
  final int kal;
  final int pro;
  final int car;
  final int fat;
  final double rating;
  final int matchScore;
  final String description;
  final String prepTime;
  final String cookTime;
  final String servings;
  final String totalBudget;
  final List<String> equipments;
  final List<String> ingredients;
  final List<String> instructions;
  final String image;

  MealPlanItem({
    required this.id,
    required this.type,
    required this.time,
    required this.title,
    required this.category,
    required this.kal,
    required this.pro,
    required this.car,
    required this.fat,
    required this.rating,
    required this.matchScore,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.totalBudget,
    required this.equipments,
    required this.ingredients,
    required this.instructions,
    required this.image,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedIngredients = [];
    if (json['ingredients'] is List) {
      for (var item in json['ingredients']) {
        if (item is Map && item['items'] is List) {
          for (var subItem in item['items']) {
            parsedIngredients.add(subItem.toString());
          }
        } else if (item is Map && item['name'] != null) {
          final amt = item['amount'] != null ? ' (${item['amount']})' : '';
          parsedIngredients.add('${item['name']}$amt');
        } else {
          parsedIngredients.add(item.toString());
        }
      }
    }

    List<String> parsedInstructions = [];
    if (json['instructions'] is List) {
      parsedInstructions =
          (json['instructions'] as List).map((e) => e.toString()).toList();
    }

    final rawTitle = json['title']?.toString() ?? 'Menu Sehat Gizify';
    final rawCat = json['category']?.toString() ?? json['type']?.toString();
    final imgUrl = (json['image'] != null && json['image'].toString().isNotEmpty)
        ? json['image'].toString()
        : getMealFoodImage(rawTitle, category: rawCat);

    return MealPlanItem(
      id: json['id']?.toString() ?? 'meal_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type']?.toString() ?? json['meal_type']?.toString() ?? 'Sarapan',
      time: json['time']?.toString() ?? '07:00',
      title: rawTitle,
      category: rawCat ?? 'Sehat',
      kal: (json['kal'] as num?)?.toInt() ??
          (json['calories'] as num?)?.toInt() ??
          (json['estimated_calories'] as num?)?.toInt() ??
          350,
      pro: (json['pro'] as num?)?.toInt() ??
          (json['protein'] as num?)?.toInt() ??
          15,
      car: (json['car'] as num?)?.toInt() ??
          (json['carbs'] as num?)?.toInt() ??
          40,
      fat: (json['fat'] as num?)?.toInt() ??
          (json['fats'] as num?)?.toInt() ??
          10,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      matchScore: (json['matchScore'] as num?)?.toInt() ??
          ((json['health_score'] as num?) != null
              ? ((json['health_score'] as num).toDouble() * 10).toInt()
              : 98),
      description: json['description']?.toString() ??
          'Menu sehat kaya gizi seimbang yang diracik khusus untuk memenuhi target kalori harianmu.',
      prepTime: json['prepTime']?.toString() ??
          (json['prep_time'] != null ? '${json['prep_time']} Menit' : '10 Menit'),
      cookTime: json['cookTime']?.toString() ??
          (json['cook_time'] != null ? '${json['cook_time']} Menit' : '15 Menit'),
      servings: json['servings']?.toString() ?? '1 Porsi',
      totalBudget: json['totalBudget']?.toString() ??
          (json['estimated_price'] != null ? 'Rp ${json['estimated_price']}' : 'Rp 20.000'),
      equipments: (json['equipments'] as List? ?? ['Wajan', 'Panci', 'Pisau', 'Mangkuk'])
          .map((e) => e.toString())
          .toList(),
      ingredients: parsedIngredients.isNotEmpty
          ? parsedIngredients
          : ['Bahan segar pilihan', 'Bumbu rempah alami', 'Garam & lada secukupnya'],
      instructions: parsedInstructions.isNotEmpty
          ? parsedInstructions
          : [
              'Cuci bersih seluruh bahan di bawah air mengalir.',
              'Masak dengan api sedang hingga matang sempurna.',
              'Sajikan selagi hangat untuk nutrisi maksimal.'
            ],
      image: imgUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'time': time,
        'title': title,
        'category': category,
        'kal': kal,
        'pro': pro,
        'car': car,
        'fat': fat,
        'rating': rating,
        'matchScore': matchScore,
        'description': description,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'totalBudget': totalBudget,
        'equipments': equipments,
        'ingredients': ingredients,
        'instructions': instructions,
        'image': image,
      };
}

// ==========================================
// FALLBACK PLAN (IDENTIK DENGAN WEB)
// ==========================================
List<MealPlanDay> getWebFallbackPlan(String currency, String peopleStr) {
  final isUsd = currency == 'USD';
  final isMyr = currency == 'MYR';

  return [
    MealPlanDay(
      day: 1,
      meals: [
        MealPlanItem(
          id: 'fall_1',
          type: 'Sarapan',
          time: '07:00',
          title: 'Oatmeal Buah Naga & Chia Seed',
          category: 'Sarapan',
          kal: 320,
          pro: 12,
          car: 45,
          fat: 8,
          rating: 4.9,
          matchScore: 98,
          description:
              'Oatmeal sehat yang kaya akan serat dan antioksidan dari buah naga. Sangat cocok untuk memulai pagi dengan energi penuh tanpa rasa begah.',
          prepTime: '5 Menit',
          cookTime: '10 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$2.50' : isMyr ? 'RM 7.50' : 'Rp 15.000',
          equipments: ['Kompor', 'Panci Kecil', 'Mangkuk', 'Sendok'],
          ingredients: [
            '40g Oatmeal instan',
            '1/2 Buah naga merah (potong dadu)',
            '150ml Susu almond tanpa gula',
            '1 sdm Chia seed',
            '2 sdm Granola utuh'
          ],
          instructions: [
            'Panaskan susu almond dalam panci kecil menggunakan api sedang.',
            'Masukkan oatmeal, aduk perlahan secara konstan hingga teksturnya mengental (~5 menit).',
            'Pindahkan ke mangkuk saji, tata potongan buah naga & chia seed di atasnya. Sajikan hangat.'
          ],
          image:
              'https://images.unsplash.com/photo-1548807371-30dc1bbe6cb5?q=80&w=800&auto=format&fit=crop',
        ),
        MealPlanItem(
          id: 'fall_2',
          type: 'Makan Siang',
          time: '12:30',
          title: 'Dada Ayam Bakar Rosemary & Nasi Merah',
          category: 'Makan Siang',
          kal: 550,
          pro: 45,
          car: 50,
          fat: 15,
          rating: 4.8,
          matchScore: 95,
          description:
              'Menu makan siang tinggi protein dengan aroma rosemary yang membangkitkan selera. Menggunakan dada ayam fillet bebas lemak yang dipanggang sempurna.',
          prepTime: '10 Menit',
          cookTime: '20 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$4.00' : isMyr ? 'RM 12.00' : 'Rp 25.000',
          equipments: ['Wajan Anti Lengket', 'Capitan', 'Pisau', 'Talenan'],
          ingredients: [
            '200g Dada ayam fillet',
            '100g Nasi beras merah matang',
            '1 sdt Minyak zaitun',
            '1 sdt Rosemary kering',
            'Garam & lada hitam secukupnya'
          ],
          instructions: [
            'Keringkan dada ayam dengan tisu dapur, baluri dengan minyak zaitun, rosemary, garam, dan lada.',
            'Panaskan wajan anti lengket di atas kompor dengan api sedang-tinggi.',
            'Panggang dada ayam selama 6-8 menit di setiap sisinya hingga matang sempurna dan berwarna kecoklatan.',
            'Angkat dan diamkan 3 menit sebelum diiris agar sari daging tetap juicy. Sajikan bersama nasi merah.'
          ],
          image:
              'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?q=80&w=800&auto=format&fit=crop',
        ),
        MealPlanItem(
          id: 'fall_3',
          type: 'Makan Malam',
          time: '19:00',
          title: 'Salad Tuna Alpukat Zesty Lemon',
          category: 'Makan Malam',
          kal: 400,
          pro: 35,
          car: 10,
          fat: 22,
          rating: 4.9,
          matchScore: 99,
          description:
              'Makan malam rendah karbohidrat yang sangat praktis. Tuna kaya omega-3 dipadukan dengan alpukat yang creamy tanpa proses memasak rumit.',
          prepTime: '10 Menit',
          cookTime: '0 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$5.50' : isMyr ? 'RM 16.00' : 'Rp 35.000',
          equipments: ['Mangkuk Besar', 'Garpu', 'Pisau', 'Talenan'],
          ingredients: [
            '1 kaleng Tuna in water (tiriskan)',
            '1/2 buah Alpukat matang (potong dadu)',
            '1 genggam Selada romaine segar',
            '1 sdm Perasan lemon murni',
            'Lada hitam secukupnya'
          ],
          instructions: [
            'Tiriskan air dari kaleng tuna, pindahkan ke mangkuk besar lalu suwir perlahan dengan garpu.',
            'Masukkan selada romaine dan potongan dadu alpukat ke dalam mangkuk.',
            'Beri perasan lemon segar dan taburan lada hitam. Aduk perlahan dan sajikan segera.'
          ],
          image:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop',
        ),
      ],
    ),
    MealPlanDay(
      day: 2,
      meals: [
        MealPlanItem(
          id: 'fall_4',
          type: 'Sarapan',
          time: '07:00',
          title: 'Roti Gandum Utuh & Telur Dadar Lembut',
          category: 'Sarapan',
          kal: 300,
          pro: 15,
          car: 30,
          fat: 10,
          rating: 4.7,
          matchScore: 92,
          description:
              'Menu sarapan klasik bernutrisi tinggi. Karbohidrat kompleks dari gandum utuh berpadu dengan protein berkualitas tinggi dari telur ayam.',
          prepTime: '5 Menit',
          cookTime: '5 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$2.00' : isMyr ? 'RM 6.00' : 'Rp 12.000',
          equipments: ['Wajan Anti Lengket', 'Spatula'],
          ingredients: [
            '2 lembar Roti gandum utuh',
            '2 butir Telur ayam segar',
            '1 sdt Mentega tawar',
            'Sejumput garam Himalaya'
          ],
          instructions: [
            'Kocok lepas dua butir telur dengan sejumput garam.',
            'Panaskan wajan anti lengket dan lelehkan mentega dengan api sedang.',
            'Panggang roti gandum sebentar hingga harum dan kecoklatan.',
            'Masak telur dadar hingga lembut, lalu sajikan bersama roti gandum.'
          ],
          image:
              'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?q=80&w=800&auto=format&fit=crop',
        ),
        MealPlanItem(
          id: 'fall_5',
          type: 'Makan Siang',
          time: '12:30',
          title: 'Nasi Merah & Fillet Ikan Dori Panggang',
          category: 'Makan Siang',
          kal: 500,
          pro: 40,
          car: 45,
          fat: 12,
          rating: 4.8,
          matchScore: 96,
          description:
              'Fillet ikan dori lembut yang kaya protein dengan bumbu rempah aromatik, disajikan dengan nasi beras merah kaya serat.',
          prepTime: '10 Menit',
          cookTime: '15 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$3.50' : isMyr ? 'RM 11.00' : 'Rp 22.000',
          equipments: ['Wajan Panggang', 'Spatula', 'Talenan'],
          ingredients: [
            '200g Fillet ikan dori segar',
            '100g Nasi merah matang',
            '1 sdm Minyak zaitun',
            '1 sdt Bubuk bawang putih & ketumbar',
            '1/2 buah Jeruk nipis'
          ],
          instructions: [
            'Lumuri fillet ikan dori dengan air perasan jeruk nipis dan bumbu rempah selama 5 menit.',
            'Panaskan wajan panggang dengan sedikit minyak zaitun.',
            'Panggang ikan dori selama 4-5 menit per sisi hingga matang dan berwarna keemasan.',
            'Sajikan hangat bersama seporsi nasi merah.'
          ],
          image:
              'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=800&auto=format&fit=crop',
        ),
        MealPlanItem(
          id: 'fall_6',
          type: 'Makan Malam',
          time: '19:00',
          title: 'Sup Brokoli Tahu Gurih Hangat',
          category: 'Makan Malam',
          kal: 320,
          pro: 20,
          car: 18,
          fat: 8,
          rating: 4.8,
          matchScore: 94,
          description:
              'Sup sayur hangat yang menenangkan lambung di malam hari dengan tahu sutra kaya kalsium dan brokoli segar kaya antioksidan.',
          prepTime: '10 Menit',
          cookTime: '12 Menit',
          servings: '$peopleStr Porsi',
          totalBudget: isUsd ? '\$2.00' : isMyr ? 'RM 6.00' : 'Rp 14.000',
          equipments: ['Panci Sup', 'Sendok Sayur', 'Pisau'],
          ingredients: [
            '1 bonggol Brokoli (potong per kuntum)',
            '1 kotak Tahu sutra putih (potong dadu)',
            '2 siung Bawang putih geprek',
            '400ml Air kaldu sayur bening',
            'Garam & merica secukupnya'
          ],
          instructions: [
            'Tumis bawang putih dengan sedikit air hingga harum di dalam panci.',
            'Tuangkan air kaldu sayur dan biarkan mendidih perlahan.',
            'Masukkan potongan tahu dan brokoli, masak selama 4 menit agar sayuran tetap renyah bernutrisi.',
            'Beri garam dan merica secukupnya. Angkat dan nikmati selagi hangat.'
          ],
          image:
              'https://images.unsplash.com/photo-1547592166-23ac45744acd?q=80&w=800&auto=format&fit=crop',
        ),
      ],
    ),
  ];
}

// ==========================================
// UTAMA: MEAL PLAN SCREEN
// ==========================================
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  // Wizard States: 1 = Budget, 2 = Days, 3 = People, 4 = Review
  int _currentStep = 1;

  String _currency = 'IDR';
  final TextEditingController _budgetController =
      TextEditingController(text: '100.000');
  final TextEditingController _daysController =
      TextEditingController(text: '2');
  final TextEditingController _peopleController =
      TextEditingController(text: '1');

  // Active Plan & Result States
  MealPlanData? _activePlan;
  int _activeDayIndex = 0;
  bool _isLoadingPlan = false;
  int _loadingStep = 0;
  Map<String, dynamic>? _userProfile;

  // Animation controller for pulsing AI loading
  late AnimationController _pulseController;

  final List<String> _loadingMessages = [
    'Menganalisis budget makanan...',
    'Menghitung kebutuhan nutrisi & kalori...',
    'Menyesuaikan porsi untuk seluruh keluarga...',
    'Meracik resep & estimasi gizi terbaik Gizify...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadUserData();
    _loadSavedPlan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _budgetController.dispose();
    _daysController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  // Tarik data profil pengguna dari Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userProfile = doc.data();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Cek apakah ada saved plan di SharedPreferences
  Future<void> _loadSavedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('gizify_saved_plan');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as Map<String, dynamic>;
        final loadedPlan = MealPlanData.fromJson(decoded);
        if (mounted) {
          setState(() {
            _activePlan = loadedPlan;
          });
        }
      }
    } catch (e) {
      debugPrint('Error parsing saved plan: $e');
    }
  }

  void _switchCurrency(String newCurr) {
    if (_currency == newCurr) return;
    setState(() {
      _currency = newCurr;
      if (newCurr == 'USD') {
        _budgetController.text = '15';
      } else if (newCurr == 'MYR') {
        _budgetController.text = '25';
      } else {
        _budgetController.text = '100.000';
      }
    });
  }

  void _addBudget(int amount) {
    if (_currency == 'USD' || _currency == 'MYR') {
      final current =
          double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
      final newAmt = current + (amount / 10000);
      setState(() {
        _budgetController.text = newAmt.toStringAsFixed(0);
      });
    } else {
      final current =
          int.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final newAmt = current + amount;
      setState(() {
        _budgetController.text = _formatNumber(newAmt);
      });
    }
  }

  String _formatNumber(int val) {
    return val.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  void _onBudgetChanged(String val) {
    if (_currency == 'IDR') {
      final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) {
        _budgetController.value = const TextEditingValue(text: '');
        return;
      }
      final parsed = int.tryParse(cleaned) ?? 0;
      final formatted = _formatNumber(parsed);
      _budgetController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Mulai Meracik Menu dengan AI
  Future<void> _generateMealPlan() async {
    setState(() {
      _isLoadingPlan = true;
      _loadingStep = 0;
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _loadingStep = 1);
    });
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _loadingStep = 2);
    });
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _loadingStep = 3);
    });

    final budgetStr = _budgetController.text.trim();
    final daysNum = int.tryParse(_daysController.text.trim()) ?? 2;
    final peopleNum = int.tryParse(_peopleController.text.trim()) ?? 1;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isNotEmpty) {
        final model = GenerativeModel(
          model: 'gemini-3.1-flash-lite',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            responseMimeType: 'application/json',
          ),
        );

        final bodyGoal = _userProfile?['body_goal'] ?? _userProfile?['bodyGoal'] ?? 'Menjaga Berat Badan';
        final cals = _userProfile?['daily_calories'] ?? _userProfile?['calories'] ?? 2000;
        final allergies = (_userProfile?['allergies'] as List?)?.join(', ') ?? '-';
        final diets = (_userProfile?['dietTypes'] as List?)?.join(', ') ?? 'Sehat Seimbang';

        final prompt = '''
Kamu adalah Gizify AI Nutritionist. Buat Meal Plan hemat & sehat dalam bentuk JSON Array murni.
Data:
- Budget: $_currency $budgetStr
- Durasi: $daysNum hari
- Jumlah Orang: $peopleNum orang
- Target Tubuh: $bodyGoal
- Kalori Harian: $cals Kkal
- Alergi: $allergies
- Preferensi Diet: $diets

Setiap hari wajib ada 3 menu: Sarapan, Makan Siang, Makan Malam.
Format JSON Array yang wajib dikembalikan:
[
  {
    "day": 1,
    "meals": [
      {
        "id": "meal_d1_1",
        "type": "Sarapan",
        "time": "07:00",
        "title": "Nama Masakan",
        "category": "Sarapan",
        "kal": 320,
        "pro": 15,
        "car": 40,
        "fat": 8,
        "rating": 4.9,
        "matchScore": 98,
        "description": "Deskripsi singkat dan gizi.",
        "prepTime": "10 Menit",
        "cookTime": "15 Menit",
        "servings": "$peopleNum Porsi",
        "totalBudget": "$_currency 15.000",
        "equipments": ["Wajan", "Panci"],
        "ingredients": ["Bahan 1", "Bahan 2"],
        "instructions": ["Langkah 1", "Langkah 2"],
        "image": ""
      }
    ]
  }
]
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';

        if (text.isNotEmpty) {
          final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(cleaned) as List;

          final planDays = parsed.map((e) => MealPlanDay.fromJson(e as Map<String, dynamic>)).toList();

          if (planDays.isNotEmpty) {
            final newPlan = MealPlanData(
              budget: budgetStr,
              days: daysNum.toString(),
              people: peopleNum.toString(),
              currency: _currency,
              startDate: DateTime.now().toIso8601String().split('T')[0],
              plan: planDays,
            );

            if (mounted) {
              setState(() {
                _activePlan = newPlan;
                _activeDayIndex = 0;
                _isLoadingPlan = false;
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini Meal Plan Error (using high quality fallback): $e');
    }

    // Fallback jika API error / rate limit
    final fallbackDays = getWebFallbackPlan(_currency, peopleNum.toString());
    final newPlan = MealPlanData(
      budget: budgetStr,
      days: daysNum.toString(),
      people: peopleNum.toString(),
      currency: _currency,
      startDate: DateTime.now().toIso8601String().split('T')[0],
      plan: fallbackDays,
    );

    if (mounted) {
      setState(() {
        _activePlan = newPlan;
        _activeDayIndex = 0;
        _isLoadingPlan = false;
      });
    }
  }

  // Simpan ke SharedPreferences & Firestore
  Future<void> _savePlanToJournal() async {
    if (_activePlan == null) return;

    DateTime selectedDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1EAB57),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    final updatedPlan = MealPlanData(
      budget: _activePlan!.budget,
      days: _activePlan!.days,
      people: _activePlan!.people,
      currency: _activePlan!.currency,
      startDate: dateStr,
      plan: _activePlan!.plan,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gizify_saved_plan', jsonEncode(updatedPlan.toJson()));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': 'Meal Plan Berhasil Disimpan! 🎉',
          'message':
              'Rencana menu ${_activePlan!.days} hari telah dijadwalkan mulai $dateStr.',
          'type': 'success',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Meal Plan berhasil disimpan ke jurnal jadwal makanmu!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1EAB57),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Error saving plan: $e');
    }
  }

  // Reset / Buat Ulang Plan
  void _resetPlan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Buat Meal Plan Baru?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Kamu sudah memiliki Meal Plan aktif. Apakah kamu ingin mereset dan membuat menu yang baru?',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('gizify_saved_plan');
              setState(() {
                _activePlan = null;
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1EAB57),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Buat Baru', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD METHODS
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (_isLoadingPlan) {
      return _buildLoadingView();
    }

    if (_activePlan != null) {
      return _buildResultView();
    }

    return _buildWizardView();
  }

  // ------------------------------------------
  // 1. LOADING VIEW DENGAN ANIMASI SINKRON WEB
  // ------------------------------------------
  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1EAB57), Color(0xFF0D5929)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1EAB57).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Meracik Meal Plan AI...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingMessages[_loadingStep.clamp(0, 3)],
                    key: ValueKey<int>(_loadingStep),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1EAB57),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 220,
                    height: 8,
                    child: LinearProgressIndicator(
                      value: (_loadingStep + 1) / 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF1EAB57)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Langkah ${_loadingStep + 1} dari 4',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------
  // 2. WIZARD VIEW (STEP 1 - 4)
  // ------------------------------------------
  Widget _buildWizardView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildWizardAppBar(),

            // Wizard Step Indicators
            _buildStepIndicator(),

            // Wizard Dynamic Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Actions (Kembali / Lanjut)
            _buildWizardBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF1EAB57),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Meal Plan Generator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'RENCANA MENU HEMAT & SEHAT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1EAB57),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepDot(1, 'Budget'),
          _buildStepLine(1),
          _buildStepDot(2, 'Hari'),
          _buildStepLine(2),
          _buildStepDot(3, 'Porsi'),
          _buildStepLine(3),
          _buildStepDot(4, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isDone = _currentStep > step;
    final isActive = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF1EAB57)
                : isDone
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isActive || isDone
                  ? const Color(0xFF1EAB57)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Color(0xFF1EAB57))
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1EAB57) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: isDone ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Budget();
      case 2:
        return _buildStep2Days();
      case 3:
        return _buildStep3People();
      case 4:
        return _buildStep4Review();
      default:
        return _buildStep1Budget();
    }
  }

  // STEP 1: BUDGET
  Widget _buildStep1Budget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildSectionHeader(
          icon: Icons.savings_outlined,
          title: 'Berapa Budget Belanjamu?',
          desc:
              'Tentukan batas pengeluaran untuk bahan makanan. AI akan memaksimalkan nutrisi dan variasi resep sesuai budget ini.',
        ),
        const SizedBox(height: 20),

        // Currency Toggle
        Row(
          children: [
            _buildCurrencyPill('IDR (Rp)', 'IDR'),
            const SizedBox(width: 8),
            _buildCurrencyPill('USD (\$)', 'USD'),
            const SizedBox(width: 8),
            _buildCurrencyPill('MYR (RM)', 'MYR'),
          ],
        ),
        const SizedBox(height: 16),

        // Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                _currency == 'USD'
                    ? '\$'
                    : _currency == 'MYR'
                        ? 'RM'
                        : 'Rp',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1EAB57),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  onChanged: _onBudgetChanged,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '100.000',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Add Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_currency == 'IDR') ...[
              _buildQuickAddChip('+Rp 50.000', 50000),
              _buildQuickAddChip('+Rp 100.000', 100000),
              _buildQuickAddChip('+Rp 200.000', 200000),
            ] else if (_currency == 'USD') ...[
              _buildQuickAddChip('+\$5', 50000),
              _buildQuickAddChip('+\$10', 100000),
              _buildQuickAddChip('+\$20', 200000),
            ] else ...[
              _buildQuickAddChip('+RM 10', 50000),
              _buildQuickAddChip('+RM 20', 100000),
              _buildQuickAddChip('+RM 50', 200000),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyPill(String label, String code) {
    final isSelected = _currency == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchCurrency(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1EAB57) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(String label, int amount) {
    return ActionChip(
      onPressed: () => _addBudget(amount),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1EAB57),
        ),
      ),
      backgroundColor: const Color(0xFFECFDF5),
      side: const BorderSide(color: Color(0xFFD1FAE5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // STEP 2: DAYS
  Widget _buildStep2Days() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildSectionHeader(
          icon: Icons.calendar_today_rounded,
          title: 'Berapa Hari Rencana Menumu?',
          desc:
              'Pilih durasi meal plan (1 hingga 7 hari). Setiap hari akan disusun lengkap: Sarapan, Makan Siang, dan Makan Malam.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, color: Color(0xFF1EAB57)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '2',
                    suffixText: 'Hari',
                  ),
                  onChanged: (val) {
                    final n = int.tryParse(val);
                    if (n != null && n > 7) {
                      _daysController.text = '7';
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          children: ['2 Hari', '3 Hari', '5 Hari', '7 Hari'].map((d) {
            final numStr = d.split(' ')[0];
            final isSel = _daysController.text == numStr;
            return ChoiceChip(
              label: Text(d),
              selected: isSel,
              selectedColor: const Color(0xFF1EAB57),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : const Color(0xFF1EAB57),
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: const Color(0xFFECFDF5),
              side: const BorderSide(color: Color(0xFFD1FAE5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _daysController.text = numStr);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 3: PEOPLE
  Widget _buildStep3People() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildSectionHeader(
          icon: Icons.people_outline_rounded,
          title: 'Untuk Berapa Orang?',
          desc:
              'Porsi dan takaran bahan belanja akan dihitung secara proporsional sesuai jumlah anggota yang makan.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_rounded, color: Color(0xFF1EAB57)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _peopleController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '1',
                    suffixText: 'Orang',
                  ),
                  onChanged: (val) {
                    final n = int.tryParse(val);
                    if (n != null && n > 10) {
                      _peopleController.text = '10';
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          children: ['1 Orang', '2 Orang', '4 Orang', '5 Orang'].map((p) {
            final numStr = p.split(' ')[0];
            final isSel = _peopleController.text == numStr;
            return ChoiceChip(
              label: Text(p),
              selected: isSel,
              selectedColor: const Color(0xFF1EAB57),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : const Color(0xFF1EAB57),
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: const Color(0xFFECFDF5),
              side: const BorderSide(color: Color(0xFFD1FAE5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _peopleController.text = numStr);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 4: REVIEW & CONFIRM
  Widget _buildStep4Review() {
    final budgetStr = _budgetController.text.trim();
    final daysStr = _daysController.text.trim();
    final peopleStr = _peopleController.text.trim();

    final daysNum = int.tryParse(daysStr) ?? 1;
    final budgetRaw = int.tryParse(budgetStr.replaceAll('.', '')) ?? 100000;
    final perDay = (budgetRaw / daysNum).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildSectionHeader(
          icon: Icons.check_circle_outline_rounded,
          title: 'Konfirmasi Kebutuhan Meal Plan',
          desc:
              'Periksa kembali parameter rencana menumu sebelum Gizify AI menyusun resep dan takaran belanja.',
        ),
        const SizedBox(height: 20),

        // Review Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildReviewRow('Total Budget', '$_currency $budgetStr'),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildReviewRow('Durasi Menu', '$daysStr Hari'),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildReviewRow('Porsi Masakan', '$peopleStr Orang'),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildReviewRow(
                'Estimasi per Hari',
                _currency == 'IDR'
                    ? 'Rp ${_formatNumber(perDay)} / hari'
                    : '$_currency ${(budgetRaw / daysNum).toStringAsFixed(1)} / hari',
                isHighlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User Health Profile Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1FAE5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFF1EAB57), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Otomatis Disesuaikan dengan Profilmu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target Tubuh: ${_userProfile?['body_goal'] ?? _userProfile?['bodyGoal'] ?? 'Menjaga Berat Badan'} • Kebutuhan: ${_userProfile?['daily_calories'] ?? _userProfile?['calories'] ?? 2000} Kkal/hari',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1EAB57), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 4) {
                  setState(() => _currentStep++);
                } else {
                  _generateMealPlan();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1EAB57),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentStep == 4 ? 'Mulai Racik Menu AI ✨' : 'Lanjut',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // 3. RESULT VIEW (JADWAL MENU SIAP)
  // ------------------------------------------
  Widget _buildResultView() {
    final plan = _activePlan!;
    final currentDay = plan.plan.isNotEmpty
        ? plan.plan[_activeDayIndex.clamp(0, plan.plan.length - 1)]
        : null;

    final isUsd = plan.currency == 'USD';
    final isMyr = plan.currency == 'MYR';
    final currSymbol = isUsd ? '\$' : isMyr ? 'RM' : 'Rp';

    final budgetNum = int.tryParse(plan.budget.replaceAll('.', '')) ?? 100000;
    final daysNum = int.tryParse(plan.days) ?? 1;
    final perDay = (budgetNum / daysNum).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Header Result Bar
            _buildResultAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Budget Card (Emerald Gradient)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1EAB57), Color(0xFF148943)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1EAB57).withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.account_balance_wallet_rounded,
                                  color: Color(0xFFD1FAE5), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'TARGET PENGELUARAN MAKAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD1FAE5),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBudgetStatItem('Total Budget', '$currSymbol ${plan.budget}'),
                              _buildBudgetStatItem('Durasi', '${plan.days} Hari'),
                              _buildBudgetStatItem('Porsi', '${plan.people} Orang'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ESTIMASI PER HARI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  isUsd
                                      ? '\$ ${(budgetNum / daysNum).toStringAsFixed(1)}'
                                      : isMyr
                                          ? 'RM ${(budgetNum / daysNum).toStringAsFixed(1)}'
                                          : 'Rp ${_formatNumber(perDay)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Health Score Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFECFDF5),
                              border: Border.all(color: const Color(0xFF1EAB57), width: 3),
                            ),
                            child: const Center(
                              child: Text(
                                '9.5',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1EAB57),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Health Score AI',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'OPTIMAL',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1EAB57),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Gizi seimbang, kaya serat & vitamin, serta minim lemak jenuh.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Day Tabs Selector
                    if (plan.plan.length > 1) ...[
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: plan.plan.length,
                          itemBuilder: (ctx, idx) {
                            final isSel = idx == _activeDayIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('Hari ${idx + 1}'),
                                selected: isSel,
                                selectedColor: const Color(0xFF1EAB57),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : const Color(0xFF1EAB57),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                backgroundColor: const Color(0xFFECFDF5),
                                side: const BorderSide(color: Color(0xFFD1FAE5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _activeDayIndex = idx);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Meal List for Current Day
                    if (currentDay != null) ...[
                      ...currentDay.meals.map((meal) => _buildMealCard(meal)),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Actions: Simpan ke Jurnal & Buat Baru
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePlanToJournal,
                      icon: const Icon(Icons.bookmark_add_rounded, size: 20, color: Colors.white),
                      label: const Text(
                        'Simpan ke Jurnal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EAB57),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _resetPlan,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                    tooltip: 'Buat Menu Baru',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.restaurant_menu_rounded,
                      color: Color(0xFF1EAB57), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Jadwal Menu Siap!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'GIZIFY MEAL PLANNER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1EAB57),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _resetPlan,
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 16, color: Color(0xFF1EAB57)),
            label: const Text(
              'Baru',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1EAB57),
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFECFDF5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD1FAE5),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealPlanItem meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Image Header with badges
          Stack(
            children: [
              Image.network(
                meal.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 160,
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(Icons.restaurant, color: Colors.grey, size: 40),
                  ),
                ),
              ),
              // Type Badge (Sarapan / Makan Siang / Malam)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        meal.type.toLowerCase().contains('sarapan')
                            ? Icons.wb_sunny_rounded
                            : meal.type.toLowerCase().contains('siang')
                                ? Icons.wb_twilight_rounded
                                : Icons.nightlight_round,
                        size: 14,
                        color: const Color(0xFF1EAB57),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${meal.type} • ${meal.time}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Match Score Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EAB57),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1EAB57).withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '${meal.matchScore}% Cocok',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Meal Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Macro Nutritional Badges
                Row(
                  children: [
                    _buildMacroChip('⚡ ${meal.kal} Kkal'),
                    const SizedBox(width: 6),
                    _buildMacroChip('🥩 ${meal.pro}g Pro'),
                    const SizedBox(width: 6),
                    _buildMacroChip('🍚 ${meal.car}g Kar'),
                    const SizedBox(width: 6),
                    _buildMacroChip('🥑 ${meal.fat}g Lem'),
                  ],
                ),
                const SizedBox(height: 14),

                // Cooking Info
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Masak: ${meal.cookTime}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      meal.totalBudget,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1EAB57),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),

                // Collapsible Ingredients & Instructions
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bahan & Cara Memasak',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1EAB57),
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'BAHAN-BAHAN:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...meal.ingredients.map(
                        (ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: Color(0xFF1EAB57)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ing,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CARA MEMASAK:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...meal.instructions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1EAB57),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
