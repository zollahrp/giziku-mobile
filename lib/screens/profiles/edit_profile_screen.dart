import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:gizify/widgets/avatar_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDetectingLocation = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _favoriteFoodsController = TextEditingController();
  final _dislikedFoodsController = TextEditingController();
  final _otherAllergyController = TextEditingController();
  final _otherDiseaseController = TextEditingController();

  // State Variables
  String _gender = "Pria";
  DateTime _birthDate = DateTime(2004, 7, 29);
  String? _photoURL;
  String _role = "BASIC";

  // Dropdown States
  String _bodyGoal = "Menambah Massa Otot";
  String _activity = "Sedang";
  String _exercise = "3-5x/Minggu";
  String _macroFocus = "Tinggi Protein (Muscle)";
  String _mealsPerDay = "3 Kali Sehari";
  String _waterIntake = "2 Liter";
  String _medicalHistory = "Maag";
  String _cookingSkill = "Menengah";

  // Multi-select Lists
  List<String> _selectedDietTypes = ["Halal"];
  List<String> _selectedAllergies = [];
  List<String> _selectedKitchen = ["Kompor", "Rice Cooker", "Kulkas", "Pisau", "Panci"];

  // Live Calculated Metrics
  double _bmi = 0.0;
  String _bmiStatus = "-";
  double _idealWeight = 0.0;
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;

  // Options matching Gizify Web
  final List<String> _genderOptions = ["Pria", "Wanita"];

  final List<String> _bodyGoalOptions = [
    "Menurunkan Berat Badan",
    "Menjaga Berat Badan",
    "Menambah Massa Otot",
  ];

  final List<String> _activityOptions = [
    "Rendah",
    "Sedang",
    "Tinggi",
  ];

  final List<String> _exerciseOptions = [
    "Jarang",
    "1-2x/Minggu",
    "3-5x/Minggu",
    "Setiap Hari",
  ];

  final List<String> _macroFocusOptions = [
    "Seimbang",
    "Tinggi Protein (Muscle)",
    "Rendah Karbohidrat",
    "Rendah Lemak",
    "Sangat Rendah Karbo (Keto)",
  ];

  final List<String> _mealsPerDayOptions = [
    "3 Kali Sehari",
    "5 Kali (Porsi Kecil)",
    "2 Kali Sehari (Fasting)",
    "1 Kali Sehari (OMAD)",
  ];

  final List<String> _waterIntakeOptions = [
    "2 Liter",
    "3.5 Liter",
    "1.5 Liter",
  ];

  final List<String> _cookingSkillOptions = [
    "Pemula",
    "Menengah",
    "Mahir",
  ];

  final List<String> _dietOptions = [
    "Halal",
    "Vegetarian",
    "Vegan",
    "Pescetarian",
    "Keto",
    "Rendah Gula",
    "Bebas Gluten",
    "Bebas Laktosa",
  ];

  final List<String> _allergyOptions = [
    "Kacang",
    "Seafood",
    "Telur",
    "Susu Sapi",
    "Kedelai",
    "Gandum",
  ];

  final List<String> _diseaseOptions = [
    "Tidak Ada",
    "Maag",
    "Diabetes",
    "Hipertensi",
    "Kolesterol",
    "Asam Urat",
  ];

  final List<String> _kitchenOptions = [
    "Kompor",
    "Rice Cooker",
    "Kulkas",
    "Pisau",
    "Panci",
    "Air Fryer",
    "Microwave",
    "Oven",
    "Blender",
    "Timbangan",
    "Kukusan",
    "Panggangan",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _heightController.addListener(_calculateLiveMetrics);
    _weightController.addListener(_calculateLiveMetrics);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _favoriteFoodsController.dispose();
    _dislikedFoodsController.dispose();
    _otherAllergyController.dispose();
    _otherDiseaseController.dispose();
    super.dispose();
  }

  // =========================================================================
  // LOAD DATA DARI FIRESTORE (MENDUKUNG FORMAT WEB & MOBILE)
  // =========================================================================
  Future<void> _loadProfileData() async {
    if (uid.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (data != null) {
        _nameController.text = data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
        _locationController.text = data['location'] ?? 'Jakarta, Indonesia';
        _photoURL = data['photoURL'] ?? data['photo_url'] ?? FirebaseAuth.instance.currentUser?.photoURL;
        _role = data['role'] ?? 'BASIC';

        _gender = data['gender'] ?? 'Pria';
        if (!_genderOptions.contains(_gender)) _gender = 'Pria';

        final dobStr = data['birthDate'] ?? data['date_of_birth'];
        if (dobStr != null && dobStr is String && dobStr.isNotEmpty) {
          try {
            _birthDate = DateTime.parse(dobStr);
          } catch (_) {
            _birthDate = DateTime(2004, 7, 29);
          }
        }

        _heightController.text = data['height']?.toString() ?? '165';
        _weightController.text = data['weight']?.toString() ?? '58';

        _bodyGoal = data['bodyGoal'] ?? data['body_goal'] ?? 'Menambah Massa Otot';
        _activity = data['activity'] ?? data['activity_level'] ?? 'Sedang';
        _exercise = data['exercise'] ?? data['exercise_level'] ?? '3-5x/Minggu';
        _macroFocus = data['macroFocus'] ?? 'Tinggi Protein (Muscle)';
        _mealsPerDay = data['mealsPerDay'] ?? data['eating_pattern'] ?? '3 Kali Sehari';
        _waterIntake = data['waterIntake'] ?? '2 Liter';

        _favoriteFoodsController.text = data['favoriteFoods'] ?? data['favorite_foods'] ?? '';
        _dislikedFoodsController.text = data['dislikedFoods'] ?? data['disliked_foods'] ?? '';

        _medicalHistory = data['medicalHistory'] ?? 'Tidak Ada';
        if (!_diseaseOptions.contains(_medicalHistory) && _medicalHistory.isNotEmpty) {
          _otherDiseaseController.text = _medicalHistory;
        }

        // Diet types
        dynamic rawDiet = data['dietTypes'] ?? data['food_type'] ?? data['dietType'];
        if (rawDiet is List) {
          _selectedDietTypes = List<String>.from(rawDiet.map((e) => e.toString()));
        } else if (rawDiet is String && rawDiet.isNotEmpty) {
          _selectedDietTypes = [rawDiet];
        }

        // Allergies
        dynamic rawAllergies = data['allergies'];
        if (rawAllergies is List) {
          _selectedAllergies = List<String>.from(rawAllergies.map((e) => e.toString()));
        }

        // Kitchen
        _cookingSkill = data['cookingSkill'] ?? 'Menengah';
        dynamic rawKitchen = data['kitchenEquipments'];
        if (rawKitchen is List) {
          _selectedKitchen = List<String>.from(rawKitchen.map((e) => e.toString()));
        }

        _calculateLiveMetrics();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // DETEKSI LOKASI OTOMATIS (GPS / REVERSE GEOCODING)
  // SAMA PERSIS DENGAN WEB GIZIFY: BIGDATACLOUD REVERSE GEOCODING
  // =========================================================================
  Future<void> _fetchCurrentLocation() async {
    if (_isDetectingLocation) return;
    setState(() => _isDetectingLocation = true);

    try {
      double? lat;
      double? lng;

      // 1. Coba ambil koordinat GPS device via Geolocator
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 4),
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (_) {
        // Fallback langsung ke IP reverse-geocode tanpa hambatan
      }

      // 2. Query BigDataCloud reverse geocoding API (identik dengan Gizify Web)
      final url = (lat != null && lng != null)
          ? 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=id'
          : 'https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=id';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'] ?? data['locality'] ?? 'Jakarta';
        final country = data['countryName'] ?? 'Indonesia';
        final detectedLocation = "$city, $country";

        setState(() {
          _locationController.text = detectedLocation;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Lokasi terdeteksi: $detectedLocation")),
                ],
              ),
              backgroundColor: const Color(0xFF1EAB57),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception("Gagal mendapatkan lokasi dari server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                "Gagal mendeteksi lokasi otomatis. Silakan coba lagi atau ketik manual."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  // =========================================================================
  // LIVE CALCULATION ENGINE (100% SESUAI DENGAN WEB GIZIFY)
  // JURNAL: Mifflin-St Jeor, WHO Broca, FAO/WHO PAL, ACSM, Atwater AMDR
  // =========================================================================
  void _calculateLiveMetrics() {
    final h = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final w = double.tryParse(_weightController.text.trim()) ?? 0.0;

    if (h <= 0 || w <= 0) return;

    // 1. Usia Presisi
    final now = DateTime.now();
    int age = now.year - _birthDate.year;
    if (now.month < _birthDate.month ||
        (now.month == _birthDate.month && now.day < _birthDate.day)) {
      age--;
    }
    if (age < 1) age = 20;

    // 2. BMI
    final hMeter = h / 100.0;
    final bmiVal = w / (hMeter * hMeter);
    _bmi = double.parse(bmiVal.toStringAsFixed(1));

    final isGym = _exercise == "3-5x/Minggu" ||
        _exercise == "Setiap Hari" ||
        _bodyGoal == "Menambah Massa Otot";

    if (age < 18) {
      _bmiStatus = "BMI Remaja";
    } else if (age >= 65) {
      if (_bmi < 22) _bmiStatus = "Kurus (Lansia)";
      else if (_bmi <= 27) _bmiStatus = "Normal (Lansia)";
      else _bmiStatus = "Gemuk (Lansia)";
    } else {
      if (_bmi < 18.5) {
        _bmiStatus = "Kurus";
      } else if (_bmi < 25) {
        _bmiStatus = "Normal";
      } else if (_bmi < 30) {
        _bmiStatus = isGym ? "Atletis (Massa Otot)" : "Gemuk";
      } else {
        _bmiStatus = (isGym && _bmi < 32) ? "Atletis (Massa Otot)" : "Obesitas";
      }
    }

    // 3. Berat Badan Ideal (Broca Modifikasi WHO)
    double ideal;
    if (_gender == "Pria") {
      ideal = h < 160 ? (h - 100) : (h - 100) - ((h - 100) * 0.10);
    } else {
      ideal = h < 150 ? (h - 100) : (h - 100) - ((h - 100) * 0.15);
    }
    _idealWeight = double.parse(ideal.toStringAsFixed(1));

    // 4. BMR (Mifflin-St Jeor)
    double bmr;
    if (_gender == "Pria") {
      bmr = (10 * w) + (6.25 * h) - (5 * age) + 5;
    } else {
      bmr = (10 * w) + (6.25 * h) - (5 * age) - 161;
    }

    // 5. TDEE (Physical Activity Level)
    double pal = 1.2;
    if (_activity == "Rendah") {
      if (_exercise == "Jarang") pal = 1.2;
      else if (_exercise == "1-2x/Minggu") pal = 1.375;
      else pal = 1.45;
    } else if (_activity == "Sedang") {
      if (_exercise == "Jarang") pal = 1.375;
      else if (_exercise == "1-2x/Minggu") pal = 1.55;
      else if (_exercise == "3-5x/Minggu") pal = 1.65;
      else pal = 1.725;
    } else if (_activity == "Tinggi") {
      if (_exercise == "Jarang") pal = 1.55;
      else if (_exercise == "1-2x/Minggu") pal = 1.725;
      else pal = 1.9;
    }

    double totalCals = bmr * pal;

    // 6. Penyesuaian Body Goal
    if (_bodyGoal == "Menambah Massa Otot") {
      totalCals += 300; // Surplus sehat
    } else if (_bodyGoal == "Menurunkan Berat Badan") {
      totalCals -= 500; // Defisit sehat
    }

    int finalCals = totalCals.round();
    if (_gender == "Wanita" && finalCals < 1200) finalCals = 1200;
    if (_gender == "Pria" && finalCals < 1500) finalCals = 1500;
    _calories = finalCals;

    // 7. Distribusi Makronutrisi (Atwater System)
    double proPct = 0.30;
    double carPct = 0.40;
    double fatPct = 0.30;

    if (_selectedDietTypes.contains("Keto") || _macroFocus == "Sangat Rendah Karbo (Keto)") {
      proPct = 0.25; carPct = 0.05; fatPct = 0.70;
    } else if (_macroFocus == "Tinggi Protein (Muscle)") {
      proPct = 0.40; carPct = 0.30; fatPct = 0.30;
    } else if (_macroFocus == "Rendah Karbohidrat") {
      proPct = 0.35; carPct = 0.20; fatPct = 0.45;
    } else if (_macroFocus == "Rendah Lemak") {
      proPct = 0.30; carPct = 0.50; fatPct = 0.20;
    }

    _protein = ((finalCals * proPct) / 4).round();
    _carbs = ((finalCals * carPct) / 4).round();
    _fat = ((finalCals * fatPct) / 9).round();

    if (mounted) setState(() {});
  }

  // =========================================================================
  // PILIH FOTO DARI GALERI / KAMERA
  // =========================================================================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
      setState(() {
        _photoURL = base64String;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto profil berhasil dipilih!"),
          backgroundColor: Color(0xFF1EAB57),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // =========================================================================
  // SIMPAN KE FIREBASE (SINKRON DENGAN SCHEMA WEB & MOBILE)
  // =========================================================================
  Future<void> _saveProfile() async {
    if (uid.isEmpty) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama lengkap tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final birthDateStr = DateFormat('yyyy-MM-dd').format(_birthDate);
      final heightStr = _heightController.text.trim();
      final weightStr = _weightController.text.trim();
      final location = _locationController.text.trim().isEmpty ? "Jakarta, Indonesia" : _locationController.text.trim();
      final favoriteFoods = _favoriteFoodsController.text.trim();
      final dislikedFoods = _dislikedFoodsController.text.trim();

      String finalMedical = _medicalHistory;
      if (_medicalHistory == "Lainnya" && _otherDiseaseController.text.trim().isNotEmpty) {
        finalMedical = _otherDiseaseController.text.trim();
      }

      final updateMap = {
        // Schema Standar Web Gizify
        'name': name,
        'gender': _gender,
        'birthDate': birthDateStr,
        'date_of_birth': birthDateStr,
        'location': location,
        if (_photoURL != null) 'photoURL': _photoURL,
        if (_photoURL != null) 'photo_url': _photoURL,

        'height': heightStr,
        'weight': weightStr,
        'activity': _activity,
        'activity_level': _activity,
        'exercise': _exercise,
        'exercise_level': _exercise,
        'bodyGoal': _bodyGoal,
        'body_goal': _bodyGoal,

        'dietTypes': _selectedDietTypes,
        'food_type': _selectedDietTypes,
        'dietType': _selectedDietTypes.isNotEmpty ? _selectedDietTypes.first : 'Normal',
        'macroFocus': _macroFocus,
        'mealsPerDay': _mealsPerDay,
        'waterIntake': _waterIntake,

        'favoriteFoods': favoriteFoods,
        'favorite_foods': favoriteFoods,
        'dislikedFoods': dislikedFoods,
        'disliked_foods': dislikedFoods,

        'allergies': _selectedAllergies,
        'medicalHistory': finalMedical,
        'chronic_disease': [finalMedical],

        'cookingSkill': _cookingSkill,
        'kitchenEquipments': _selectedKitchen,

        // Hasil Perhitungan Live AI
        'bmi': _bmi.toString(),
        'bmiStatus': _bmiStatus,
        'bmi_category': _bmiStatus,
        'idealWeight': _idealWeight.toString(),
        'ideal_weight': _idealWeight.toString(),
        'calories': _calories.toString(),
        'daily_calories': _calories,
        'macros': {
          'pro': _protein,
          'car': _carbs,
          'fat': _fat,
        },
        'protein_need': _protein,
        'carb_need': _carbs,
        'fat_need': _fat,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        updateMap,
        SetOptions(merge: true),
      );

      // Update Firebase Auth displayName
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.displayName != name) {
        await currentUser.updateDisplayName(name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil dan kebutuhan nutrisi berhasil diperbarui!"),
          backgroundColor: Color(0xFF1EAB57),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan profil: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1EAB57))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Ubah Profilmu",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "Perbarui data fisik & target gizi AI",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 14),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Batal",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE8F8EE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1EAB57)),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_rounded, color: Color(0xFF1EAB57), size: 15),
                        SizedBox(width: 4),
                        Text(
                          "Simpan",
                          style: TextStyle(
                            color: Color(0xFF1EAB57),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          children: [
            // ==========================================
            // 1. AVATAR PICKER
            // ==========================================
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF22C55E),
                              Color(0xFF06B6D4),
                              Color(0xFF8B5CF6),
                              Color(0xFFEC4899),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: getProfileImageProvider(_photoURL),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2AD882), Color(0xFF1EAB57)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 13, color: Color(0xFF1EAB57)),
                          SizedBox(width: 5),
                          Text(
                            "Ganti Foto Profil",
                            style: TextStyle(
                              color: Color(0xFF1EAB57),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 2. HASIL KALKULASI LIVE (AI PREVIEW BOX)
            // ==========================================
            _buildLiveMetricsCard(),

            const SizedBox(height: 20),

            // ==========================================
            // 3. INFORMASI PRIBADI
            // ==========================================
            _buildSection(
              title: "Informasi Pribadi",
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF1EAB57),
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: "Nama Lengkap",
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildLocationField(),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Jenis Kelamin",
                  value: _gender,
                  options: _genderOptions,
                  icon: Icons.wc_rounded,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _gender = val);
                      _calculateLiveMetrics();
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDatePickerTile(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: "Tinggi (cm)",
                        icon: Icons.height_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: "Berat (kg)",
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. TARGET TUBUH & GAYA HIDUP
            // ==========================================
            _buildSection(
              title: "Target Tubuh & Gaya Hidup",
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF3B82F6),
              children: [
                _buildDropdownField(
                  label: "Target Fisik",
                  value: _bodyGoal,
                  options: _bodyGoalOptions,
                  icon: Icons.flag_rounded,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _bodyGoal = val;
                        if (val == "Menambah Massa Otot") {
                          _macroFocus = "Tinggi Protein (Muscle)";
                        } else if (val == "Menurunkan Berat Badan") {
                          _macroFocus = "Rendah Karbohidrat";
                        }
                      });
                      _calculateLiveMetrics();
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Aktivitas Harian",
                  value: _activity,
                  options: _activityOptions,
                  icon: Icons.directions_walk_rounded,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _activity = val);
                      _calculateLiveMetrics();
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Frekuensi Olahraga",
                  value: _exercise,
                  options: _exerciseOptions,
                  icon: Icons.fitness_center_rounded,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _exercise = val);
                      _calculateLiveMetrics();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 5. PREFERENSI NUTRISI & DIET
            // ==========================================
            _buildSection(
              title: "Preferensi Nutrisi & Pola Makan",
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFFF59E0B),
              children: [
                _buildMultiSelectChips(
                  label: "Tipe Diet (Bisa lebih dari 1)",
                  allOptions: _dietOptions,
                  selectedOptions: _selectedDietTypes,
                  onChanged: (newList) {
                    setState(() => _selectedDietTypes = newList);
                    _calculateLiveMetrics();
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  label: "Fokus Makronutrisi",
                  value: _macroFocus,
                  options: _macroFocusOptions,
                  icon: Icons.pie_chart_outline_rounded,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _macroFocus = val);
                      _calculateLiveMetrics();
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Jadwal Makan Harian",
                  value: _mealsPerDay,
                  options: _mealsPerDayOptions,
                  icon: Icons.schedule_rounded,
                  onChanged: (val) {
                    if (val != null) setState(() => _mealsPerDay = val);
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: "Target Asupan Air",
                  value: _waterIntake,
                  options: _waterIntakeOptions,
                  icon: Icons.water_drop_outlined,
                  onChanged: (val) {
                    if (val != null) setState(() => _waterIntake = val);
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _favoriteFoodsController,
                  label: "Makanan Favorit",
                  icon: Icons.favorite_border_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _dislikedFoodsController,
                  label: "Makanan Tidak Disukai",
                  icon: Icons.thumb_down_alt_outlined,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 6. KONDISI KESEHATAN & ALERGI
            // ==========================================
            _buildSection(
              title: "Kesehatan & Alergi",
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFFF43F5E),
              children: [
                _buildMultiSelectChips(
                  label: "Alergi Makanan",
                  allOptions: _allergyOptions,
                  selectedOptions: _selectedAllergies,
                  isDanger: true,
                  onChanged: (newList) => setState(() => _selectedAllergies = newList),
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  label: "Riwayat Penyakit / Medis",
                  value: _diseaseOptions.contains(_medicalHistory) ? _medicalHistory : "Lainnya",
                  options: [..._diseaseOptions, "Lainnya"],
                  icon: Icons.healing_rounded,
                  onChanged: (val) {
                    if (val != null) setState(() => _medicalHistory = val);
                  },
                ),
                if (_medicalHistory == "Lainnya" || !_diseaseOptions.contains(_medicalHistory)) ...[
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _otherDiseaseController,
                    label: "Sebutkan Riwayat Medis Lainnya",
                    icon: Icons.edit_note_rounded,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 7. PROFIL DAPUR
            // ==========================================
            _buildSection(
              title: "Profil Dapur & Memasak",
              icon: Icons.soup_kitchen_rounded,
              iconColor: const Color(0xFF8B5CF6),
              children: [
                _buildDropdownField(
                  label: "Keahlian Memasak",
                  value: _cookingSkill,
                  options: _cookingSkillOptions,
                  icon: Icons.restaurant_menu_rounded,
                  onChanged: (val) {
                    if (val != null) setState(() => _cookingSkill = val);
                  },
                ),
                const SizedBox(height: 14),
                _buildMultiSelectChips(
                  label: "Peralatan Dapur yang Tersedia",
                  allOptions: _kitchenOptions,
                  selectedOptions: _selectedKitchen,
                  onChanged: (newList) => setState(() => _selectedKitchen = newList),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 8. TOMBOL SIMPAN ELEVATED
            // ==========================================
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EAB57), Color(0xFF2AD882)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1EAB57).withOpacity(0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isSaving ? "MENYIMPAN PERUBAHAN..." : "SIMPAN PROFIL & GIZI",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 9. TOMBOL BATAL
            // ==========================================
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                label: const Text(
                  "Batal",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HELPER WIDGETS (GEN-Z COLORFUL HEALTH & AI METRICS DASHBOARD)
  // =========================================================================
  Widget _buildLiveMetricsCard() {
    final int totalMacros = _protein + _carbs + _fat;
    final int proFlex = totalMacros > 0 ? ((_protein / totalMacros) * 100).round() : 33;
    final int carFlex = totalMacros > 0 ? ((_carbs / totalMacros) * 100).round() : 33;
    final int fatFlex = totalMacros > 0 ? (100 - proFlex - carFlex).clamp(1, 100) : 34;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: AI Tag + BMI Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 13),
                    SizedBox(width: 5),
                    Text(
                      "HASIL PERHITUNGAN GIZIFY",
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontFamily: 'Poppins' ,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _bmiStatus.contains("Normal") || _bmiStatus.contains("Atletis")
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _bmiStatus.contains("Normal") || _bmiStatus.contains("Atletis")
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _bmiStatus.contains("Normal") || _bmiStatus.contains("Atletis")
                          ? Icons.favorite_rounded
                          : Icons.bolt_rounded,
                      size: 13,
                      color: _bmiStatus.contains("Normal") || _bmiStatus.contains("Atletis")
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "BMI: $_bmi • $_bmiStatus",
                      style: TextStyle(
                        color: _bmiStatus.contains("Normal") || _bmiStatus.contains("Atletis")
                            ? const Color(0xFF047857)
                            : const Color(0xFFB45309),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2 Hero Metric Cards (Side by Side)
          Row(
            children: [
              // 1. Target Kalori (Warm Orange Sunset)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFF97316),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "TARGET KALORI",
                            style: TextStyle(
                              color: Color(0xFFC2410C),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "$_calories ",
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const TextSpan(
                              text: "kkal",
                              style: TextStyle(
                                color: Color(0xFFEA580C),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Kebutuhan harian metabolik",
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Berat Ideal (Fresh Cyan Sky Blue)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: Color(0xFF0284C7),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "BERAT IDEAL",
                            style: TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "$_idealWeight ",
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const TextSpan(
                              text: "kg",
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Standar modifikasi Broca",
                        style: TextStyle(
                          color: Color(0xFF075985),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Macronutrient Header & Visual Segmented Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Distribusi Makronutrisi",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _macroFocus,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Multi-color Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: proFlex,
                  child: Container(
                    height: 8,
                    color: const Color(0xFF3B82F6), // Royal Blue
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  flex: carFlex,
                  child: Container(
                    height: 8,
                    color: const Color(0xFF10B981), // Emerald
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  flex: fatFlex,
                  child: Container(
                    height: 8,
                    color: const Color(0xFFF43F5E), // Coral Rose
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3 Vibrant Macro Cards
          Row(
            children: [
              // 1. Protein
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "PROTEIN",
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${_protein}g",
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Karbohidrat
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "KARBO",
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${_carbs}g",
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Lemak
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "LEMAK",
                        style: TextStyle(
                          color: Color(0xFFBE123C),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${_fat}g",
                        style: const TextStyle(
                          color: Color(0xFF9F1239),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Footnote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Dihitung otomatis berbasis standar nutrisi klinis Mifflin-St Jeor & WHO",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Circle Icon Container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.place_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content (Label & TextField)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "DOMISILI",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.1,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: _locationController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: "Pilih / deteksi lokasi",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // GPS / Radar Detect Button (Identik dengan versi Web Gizify)
          Tooltip(
            message: "Deteksi lokasi saat ini",
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isDetectingLocation ? null : _fetchCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isDetectingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1EAB57),
                            ),
                          )
                        : const Icon(
                            Icons.gps_fixed_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 1),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                    fontFamily: 'Poppins',
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: options.contains(value) ? value : options.first,
                    items: options.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(
                          opt,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerTile() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthDate,
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1EAB57),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _birthDate = picked);
          _calculateLiveMetrics();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.cake_outlined, color: Color(0xFF64748B), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "TANGGAL LAHIR",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_birthDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1EAB57), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<String> allOptions,
    required List<String> selectedOptions,
    required ValueChanged<List<String>> onChanged,
    bool isDanger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allOptions.map((opt) {
            final isSelected = selectedOptions.contains(opt);
            return InkWell(
              onTap: () {
                final updated = List<String>.from(selectedOptions);
                if (isSelected) {
                  updated.remove(opt);
                } else {
                  updated.add(opt);
                }
                onChanged(updated);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDanger ? const Color(0xFFFFE4E6) : const Color(0xFFE8F8EE))
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? (isDanger ? const Color(0xFFFDA4AF) : const Color(0xFFA7F3D0))
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDanger ? const Color(0xFFE11D48) : const Color(0xFF1EAB57)).withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        isDanger ? Icons.warning_rounded : Icons.check_circle_rounded,
                        size: 13,
                        color: isDanger ? const Color(0xFFE11D48) : const Color(0xFF1EAB57),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDanger ? const Color(0xFFBE123C) : const Color(0xFF166534))
                            : const Color(0xFF475569),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
