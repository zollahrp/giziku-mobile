import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/food_scan_model.dart';
import '../../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  // Mode: 'piring' (AI Vision Plate) vs 'manual' (Manual Tracking)
  String _activeMode = 'piring';

  // Scanner States: 'idle', 'scanning', 'success', 'error'
  String _scanState = 'idle';
  String _scanText = "Arahkan kamera ke piring makanan...";
  Timer? _scanTextTimer;

  // Camera & Image
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  File? _capturedImage;

  // Scan Result
  FoodPlateScanResult? _scanResult;
  int? _selectedItemIndex; // null = total plate, 0..N = component
  bool _showPointers = true;
  bool _showMicro = false;

  // Inline Macro Editing
  bool _isEditingMacro = false;
  final TextEditingController _editCalController = TextEditingController();
  final TextEditingController _editProController = TextEditingController();
  final TextEditingController _editCarController = TextEditingController();
  final TextEditingController _editFatController = TextEditingController();

  // Saving states
  bool _isSavingLog = false;
  bool _isSavingManual = false;

  // Meal Type Selection
  String _mealType = "Makan Siang";
  final List<Map<String, dynamic>> _mealOptions = [
    {'id': 'Sarapan', 'label': 'Sarapan', 'icon': Icons.wb_twilight_rounded, 'color': const Color(0xFFF59E0B)},
    {'id': 'Makan Siang', 'label': 'Makan Siang', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFEAB308)},
    {'id': 'Sore / Cemilan', 'label': 'Sore / Cemilan', 'icon': Icons.cookie_rounded, 'color': const Color(0xFFD97706)},
    {'id': 'Makan Malam', 'label': 'Makan Malam', 'icon': Icons.nightlight_round, 'color': const Color(0xFF3B82F6)},
  ];

  // User Profile & Today Totals
  int _userDailyCalories = 2000;
  String _userBodyGoal = "Menjaga Berat Badan";
  int _todayCalories = 0;
  List<Map<String, dynamic>> _recentScans = [];

  // Manual Tracking Form State
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualPortionController = TextEditingController(text: "100");
  final TextEditingController _manualBaseCalController = TextEditingController();
  final TextEditingController _manualBaseProController = TextEditingController();
  final TextEditingController _manualBaseCarController = TextEditingController();
  final TextEditingController _manualBaseFatController = TextEditingController();
  final TextEditingController _manualBaseVitCController = TextEditingController();
  final TextEditingController _manualBaseFiberController = TextEditingController();
  final TextEditingController _manualBaseCalciumController = TextEditingController();
  final TextEditingController _manualBaseIronController = TextEditingController();

  bool _showManualMicro = false;
  bool _isGeneratingMacro = false;

  // Animations
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _initAutoMealType();
    _initCamera();
    _loadUserData();
    _initLaserAnimation();
  }

  void _initAutoMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _mealType = "Sarapan";
    } else if (hour < 15) {
      _mealType = "Makan Siang";
    } else if (hour < 18) {
      _mealType = "Sore / Cemilan";
    } else {
      _mealType = "Makan Malam";
    }
  }

  void _initLaserAnimation() {
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        _cameraController = CameraController(
          _availableCameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _userDailyCalories = (data['daily_calories'] ?? data['calories'] ?? data['dailyCalories'] ?? 2000) as int;
          _userBodyGoal = (data['body_goal'] ?? data['bodyGoal'] ?? "Menjaga Berat Badan") as String;
        });
      }

      await _fetchTodayTotals(user.uid);
      await _fetchRecentScans(user.uid);
    } catch (e) {
      debugPrint("User data load error: $e");
    }
  }

  Future<void> _fetchTodayTotals(String uid) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      int cals = 0;
      for (final doc in snaps.docs) {
        cals += (doc.data()['calories'] as num? ?? 0).toInt();
      }

      if (mounted) {
        setState(() {
          _todayCalories = cals;
        });
      }
    } catch (e) {
      debugPrint("Today totals error: $e");
    }
  }

  Future<void> _fetchRecentScans(String uid) async {
    try {
      final snaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .orderBy('scannedAt', descending: true)
          .limit(6)
          .get();

      if (mounted) {
        setState(() {
          _recentScans = snaps.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
      }
    } catch (e) {
      debugPrint("Recent scans fetch error: $e");
    }
  }

  @override
  void dispose() {
    _scanTextTimer?.cancel();
    _laserAnimController.dispose();
    _cameraController?.dispose();
    _manualNameController.dispose();
    _manualPortionController.dispose();
    _manualBaseCalController.dispose();
    _manualBaseProController.dispose();
    _manualBaseCarController.dispose();
    _manualBaseFatController.dispose();
    _manualBaseVitCController.dispose();
    _manualBaseFiberController.dispose();
    _manualBaseCalciumController.dispose();
    _manualBaseIronController.dispose();
    _editCalController.dispose();
    _editProController.dispose();
    _editCarController.dispose();
    _editFatController.dispose();
    super.dispose();
  }

  // Flashlight toggle
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(newFlash ? FlashMode.torch : FlashMode.off);
      setState(() => _isFlashOn = newFlash);
    } catch (e) {
      debugPrint("Flash error: $e");
    }
  }

  // Capture Image from Camera
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final xfile = await _cameraController!.takePicture();
      final file = File(xfile.path);
      setState(() {
        _capturedImage = file;
      });
      _processImage(file);
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  // Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _capturedImage = file;
        });
        _processImage(file);
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  // Process Captured Image with Gemini
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _scanState = "scanning";
      _selectedItemIndex = null;
      _showPointers = true;
      _showMicro = false;
      _isEditingMacro = false;
      _scanText = "AI Sedang Menganalisis...";
    });

    _scanTextTimer?.cancel();
    _scanTextTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      if (timer.tick == 1) {
        setState(() => _scanText = "Memisahkan komponen makanan...");
      } else if (timer.tick == 2) {
        setState(() => _scanText = "Menghitung kalori & makronutrisi...");
      }
    });

    try {
      final result = await ScannerService().scanFoodPlate(imageFile, bodyGoal: _userBodyGoal);
      _scanTextTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _scanResult = result;
        _scanState = "success";
      });
    } catch (e) {
      _scanTextTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _scanState = "error";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menganalisis gambar: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleRetake() {
    setState(() {
      _scanState = "idle";
      _capturedImage = null;
      _scanResult = null;
      _selectedItemIndex = null;
      _showMicro = false;
      _isEditingMacro = false;
    });
  }

  // Start Inline Macro Editing
  void _startEditMacro() {
    final item = _currentDisplayData;
    if (item == null) return;
    _editCalController.text = item['calories'].toString();
    _editProController.text = item['protein'].toString();
    _editCarController.text = item['carbs'].toString();
    _editFatController.text = item['fat'].toString();
    setState(() => _isEditingMacro = true);
  }

  // Save Inline Macro Edit
  void _saveEditMacro() {
    if (_scanResult == null) return;
    final newCal = int.tryParse(_editCalController.text) ?? 0;
    final newPro = double.tryParse(_editProController.text) ?? 0.0;
    final newCar = double.tryParse(_editCarController.text) ?? 0.0;
    final newFat = double.tryParse(_editFatController.text) ?? 0.0;

    setState(() {
      if (_selectedItemIndex == null) {
        _scanResult!.total.calories = newCal;
        _scanResult!.total.protein = newPro;
        _scanResult!.total.carbs = newCar;
        _scanResult!.total.fat = newFat;
      } else {
        final item = _scanResult!.items[_selectedItemIndex!];
        item.calories = newCal;
        item.protein = newPro;
        item.carbs = newCar;
        item.fat = newFat;
      }
      _isEditingMacro = false;
    });
  }

  // Current selected item or total
  Map<String, dynamic>? get _currentDisplayData {
    if (_scanResult == null) return null;
    if (_selectedItemIndex != null && _selectedItemIndex! < _scanResult!.items.length) {
      final it = _scanResult!.items[_selectedItemIndex!];
      return {
        'name': it.name,
        'portion': it.portion,
        'calories': it.calories,
        'protein': it.protein,
        'carbs': it.carbs,
        'fat': it.fat,
        'micronutrients': it.micronutrients,
      };
    } else {
      final t = _scanResult!.total;
      return {
        'name': t.name,
        'portion': t.portion,
        'calories': t.calories,
        'protein': t.protein,
        'carbs': t.carbs,
        'fat': t.fat,
        'micronutrients': t.micronutrients,
      };
    }
  }

  // Save AI Food Scan to Firestore
  Future<void> _savePlateLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _scanResult == null || !_scanResult!.isFoodItem) return;

    final dataToSave = _currentDisplayData;
    if (dataToSave == null) return;

    final isTotal = _selectedItemIndex == null;
    final saveType = isTotal ? "Gizify Vision - Piring Lengkap" : "Gizify Vision - Item Satuan";

    setState(() => _isSavingLog = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('foodLogs').add({
        'name': dataToSave['name'],
        'calories': dataToSave['calories'],
        'protein': dataToSave['protein'],
        'carbs': dataToSave['carbs'],
        'fat': dataToSave['fat'],
        'score': _scanResult!.total.score,
        'type': saveType,
        'mealType': _mealType,
        'micronutrients': (dataToSave['micronutrients'] as FoodMicronutrients).toJson(),
        'scannedAt': FieldValue.serverTimestamp(),
      });

      // Notification
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').add({
        'title': 'Makanan Dicatat! 🥗',
        'message': 'Berhasil mencatat ${dataToSave['name']} (${dataToSave['calories']} kcal) untuk $_mealType.',
        'type': 'success',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil mencatat ${dataToSave['name']}! 🎉"),
          backgroundColor: const Color(0xFF1EAB57),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _loadUserData();
      _handleRetake();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSavingLog = false);
    }
  }

  // Share Plate Scan
  void _sharePlateResult() {
    final data = _currentDisplayData;
    if (data == null) return;
    final text = '''
🍽️ Hasil Scan Nutrisi Gizify Vision
Nama: ${data['name']}
Porsi: ${data['portion']}
🔥 Kalori: ${data['calories']} kcal
💪 Protein: ${data['protein']}g | 🌾 Karbo: ${data['carbs']}g | 🥑 Lemak: ${data['fat']}g

Di-scan menggunakan Gizify Mobile App!
''';
    Share.share(text, subject: 'Nutrisi Makanan Gizify');
  }

  // --- MANUAL MODE ACTIONS ---
  Future<void> _handleAutoGenerateMacro() async {
    final foodName = _manualNameController.text.trim();
    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ketik nama makanan terlebih dahulu!"),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGeneratingMacro = true);
    try {
      final data = await ScannerService().autoGenerateManualNutrition(foodName);
      setState(() {
        _manualBaseCalController.text = data.baseCalories;
        _manualBaseProController.text = data.basePro;
        _manualBaseCarController.text = data.baseCar;
        _manualBaseFatController.text = data.baseFat;
        _manualBaseVitCController.text = data.baseVitC;
        _manualBaseFiberController.text = data.baseFiber;
        _manualBaseCalciumController.text = data.baseCalcium;
        _manualBaseIronController.text = data.baseIron;
        _showManualMicro = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✨ Nutrisi per 100g untuk '$foodName' berhasil diisi AI!"),
          backgroundColor: const Color(0xFF1EAB57),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengisi nutrisi AI: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingMacro = false);
    }
  }

  // Save Manual Form to Firestore
  Future<void> _handleManualSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _manualNameController.text.trim();
    final portionStr = _manualPortionController.text.trim();
    final baseCalStr = _manualBaseCalController.text.trim();

    if (name.isEmpty || portionStr.isEmpty || baseCalStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Mohon lengkapi Nama Makanan, Porsi, dan Kalori Dasar!"),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final portion = double.tryParse(portionStr) ?? 100;
    final multiplier = portion / 100.0;

    final calcCals = ((double.tryParse(baseCalStr) ?? 0) * multiplier).round();
    final calcPro = (((double.tryParse(_manualBaseProController.text) ?? 0) * multiplier) * 10).round() / 10;
    final calcCar = (((double.tryParse(_manualBaseCarController.text) ?? 0) * multiplier) * 10).round() / 10;
    final calcFat = (((double.tryParse(_manualBaseFatController.text) ?? 0) * multiplier) * 10).round() / 10;

    final vitC = (((double.tryParse(_manualBaseVitCController.text) ?? 0) * multiplier).round()).toString();
    final fiber = (((double.tryParse(_manualBaseFiberController.text) ?? 0) * multiplier).round()).toString();
    final calcium = (((double.tryParse(_manualBaseCalciumController.text) ?? 0) * multiplier).round()).toString();
    final iron = (((double.tryParse(_manualBaseIronController.text) ?? 0) * multiplier).round()).toString();

    setState(() => _isSavingManual = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('foodLogs').add({
        'name': name,
        'calories': calcCals,
        'protein': calcPro,
        'carbs': calcCar,
        'fat': calcFat,
        'micronutrients': {
          'vitC': "${vitC}mg",
          'fiber': "${fiber}g",
          'calcium': "${calcium}mg",
          'iron': "${iron}mg",
        },
        'score': 8,
        'type': 'Input Manual',
        'mealType': _mealType,
        'scannedAt': FieldValue.serverTimestamp(),
      });

      // Notification
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').add({
        'title': 'Input Manual Berhasil! 📝',
        'message': 'Berhasil mencatat $name ($calcCals kcal) untuk $_mealType.',
        'type': 'success',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Catatan '$name' berhasil disimpan! 🎉"),
          backgroundColor: const Color(0xFF1EAB57),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Reset form
      _manualNameController.clear();
      _manualPortionController.text = "100";
      _manualBaseCalController.clear();
      _manualBaseProController.clear();
      _manualBaseCarController.clear();
      _manualBaseFatController.clear();
      _manualBaseVitCController.clear();
      _manualBaseFiberController.clear();
      _manualBaseCalciumController.clear();
      _manualBaseIronController.clear();
      _showManualMicro = false;

      _loadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSavingManual = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Back & Mode Switcher
              _buildTopBar(),
              const SizedBox(height: 16),

              // Main Section: Mode Piring (AI Camera) vs Mode Manual (Form)
              if (_activeMode == 'piring') ...[
                _buildPlateScannerView(),
              ] else ...[
                _buildManualTrackingView(),
              ],

              const SizedBox(height: 28),

              // Bottom Section: Riwayat Makanan Terbaru
              _buildRecentHistorySection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR & MODE SWITCHER (Web-Matched)
  // ==========================================
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row: Back Button + Title
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1EAB57), size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Gizify Vision",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "AI Vision & Nutritionist",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Dual-Mode Pill Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeTabButton(
                    id: 'piring',
                    title: 'Mode Piring',
                    icon: Icons.restaurant_rounded,
                  ),
                ),
                Expanded(
                  child: _buildModeTabButton(
                    id: 'manual',
                    title: 'Mode Manual',
                    icon: Icons.edit_note_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabButton({required String id, required String title, required IconData icon}) {
    final isSelected = _activeMode == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMode = id;
          _handleRetake();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODE PIRING: AI VISION CAMERA & RESULT
  // ==========================================
  Widget _buildPlateScannerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera/Captured Image Box
        Container(
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera or Frozen Image
              if (_capturedImage != null)
                Image.file(_capturedImage!, fit: BoxFit.cover)
              else if (_isCameraReady && _cameraController != null)
                CameraPreview(_cameraController!)
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                      const SizedBox(height: 10),
                      const Text(
                        "Kamera belum siap atau tidak tersedia.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text("Pilih dari Galeri"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1EAB57),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Animated Laser Scanner Overlay (During Scanning)
              if (_scanState == 'scanning') ...[
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 380 * _laserAnimation.value,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EAB57),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1EAB57).withValues(alpha: 0.9),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  color: const Color(0xFF1EAB57).withValues(alpha: 0.08),
                ),
                // Floating Scan Capsule
                Positioned(
                  top: 20,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF1EAB57),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _scanText,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 3. Interactive Component Pointers Overlay (When Scan Success)
              if (_scanState == 'success' && _scanResult != null && _scanResult!.isFoodItem) ...[
                if (_showPointers)
                  ..._scanResult!.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = _selectedItemIndex == idx;

                    // Compute normalized coordinates (0..1000 -> fraction)
                    final yCenter = ((item.box[0] + item.box[2]) / 2) / 1000.0;
                    final xCenter = ((item.box[1] + item.box[3]) / 2) / 1000.0;

                    final topPos = (380 * yCenter).clamp(30.0, 340.0);

                    return Positioned(
                      top: topPos - 20,
                      left: (MediaQuery.of(context).size.width - 32) * xCenter - 30,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItemIndex = idx;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Food Name Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1EAB57) : Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Pin Circle
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF1EAB57)
                                    : Colors.white.withValues(alpha: 0.85),
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? const Color(0xFF1EAB57) : Colors.black)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.white : const Color(0xFF1EAB57),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // Eye Toggle Button for Pointers
                Positioned(
                  top: 14,
                  right: 14,
                  child: InkWell(
                    onTap: () => setState(() => _showPointers = !_showPointers),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        _showPointers ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],

              // 4. Shutter & Control Buttons (When in Idle State)
              if (_scanState == 'idle')
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Picker
                      InkWell(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      // Shutter Capture Button
                      GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3.5),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white38,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.camera_alt_rounded, color: Color(0xFF1EAB57), size: 28),
                            ),
                          ),
                        ),
                      ),
                      // Flashlight Toggle
                      InkWell(
                        onTap: _toggleFlash,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isFlashOn
                                ? const Color(0xFFFACC15).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isFlashOn ? const Color(0xFFFACC15) : Colors.white30,
                            ),
                          ),
                          child: Icon(
                            _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _isFlashOn ? const Color(0xFFFACC15) : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Food Scan Results Card or Idle Guide
        if (_scanState == 'success' && _scanResult != null) ...[
          if (_scanResult!.isFoodItem)
            _buildScanResultDetailsCard()
          else
            _buildUnrecognizedFoodCard(),
        ] else if (_scanState == 'idle') ...[
          _buildScannerInstructionCard(),
        ],
      ],
    );
  }

  // Scanner Instruction Card (when idle)
  Widget _buildScannerInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.center_focus_strong_rounded, color: Color(0xFF1EAB57), size: 40),
          SizedBox(height: 10),
          Text(
            "Posisikan Makanan di Kamera",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Gizify Vision akan otomatis mendeteksi setiap lauk di piring, mengkalibrasi gramatur & menghitung kalori serta protein nyata.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Unrecognized Food Card
  Widget _buildUnrecognizedFoodCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_meals_rounded, color: Color(0xFFF43F5E), size: 48),
          const SizedBox(height: 12),
          const Text(
            "Objek Tidak Dikenali Sebagai Makanan",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Pastikan kamera terfokus pada hidangan makanan asli dengan pencahayaan yang cukup.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleRetake,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Coba Foto Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FOOD RESULT DETAILS CARD (Web-Matched)
  // ==========================================
  Widget _buildScanResultDetailsCard() {
    final data = _currentDisplayData!;
    final isSpecificItem = _selectedItemIndex != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Success badge + Total Menu Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF1EAB57), size: 14),
                    SizedBox(width: 5),
                    Text(
                      "HASIL SCAN BERHASIL",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1EAB57),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSpecificItem)
                InkWell(
                  onTap: () => setState(() => _selectedItemIndex = null),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_rounded, size: 12, color: Color(0xFF475569)),
                        SizedBox(width: 4),
                        Text(
                          "Total Menu",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Dish Name
          Text(
            data['name'],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Portion Pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: RichText(
                text: TextSpan(
                  text: "Porsi: ",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: data['portion'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1EAB57),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Calories Box + Edit Macro Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_fire_department_rounded, color: Color(0xFFF43F5E), size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpecificItem ? "KALORI KOMPONEN" : "TOTAL KALORI",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_isEditingMacro)
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _editCalController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1EAB57),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                            ),
                          ),
                        )
                      else
                        RichText(
                          text: TextSpan(
                            text: "${data['calories']} ",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(
                                text: "kcal",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Edit Nutrisi Button
                if (_isEditingMacro)
                  ElevatedButton.icon(
                    onPressed: _saveEditMacro,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text("Simpan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EAB57),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _startEditMacro,
                    icon: const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF64748B)),
                    label: const Text(
                      "Edit Nutrisi",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3 Macro Chips (Protein, Carbs, Fat)
          Row(
            children: [
              Expanded(
                child: _buildMacroChip(
                  label: "Protein",
                  value: "${data['protein']}g",
                  color: const Color(0xFF3B82F6),
                  bg: const Color(0xFFEFF6FF),
                  letter: "P",
                  isEditing: _isEditingMacro,
                  controller: _editProController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroChip(
                  label: "Karbo",
                  value: "${data['carbs']}g",
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFEF3C7),
                  letter: "C",
                  isEditing: _isEditingMacro,
                  controller: _editCarController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroChip(
                  label: "Lemak",
                  value: "${data['fat']}g",
                  color: const Color(0xFFF43F5E),
                  bg: const Color(0xFFFFE4E6),
                  letter: "F",
                  isEditing: _isEditingMacro,
                  controller: _editFatController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Protein Breakdown on Plate (when total plate is selected & multiple items)
          if (!isSpecificItem && _scanResult!.items.length > 1) ...[
            _buildProteinBreakdownList(),
            const SizedBox(height: 16),
          ],

          // Micronutrients Accordion
          _buildMicronutrientsAccordion(data['micronutrients'] as FoodMicronutrients),
          const SizedBox(height: 14),

          // AI Insight Bubble (when total plate is selected)
          if (!isSpecificItem && _scanResult!.total.aiInsight.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.smart_toy_rounded, color: Color(0xFF1EAB57), size: 16),
                      SizedBox(width: 6),
                      Text(
                        "GIZIFY AI INSIGHT",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1EAB57),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${_scanResult!.total.aiInsight}"',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meal Type Selector
          _buildMealTypeSelector(),
          const SizedBox(height: 18),

          // Action Buttons: Save Log, Share, Retake
          ElevatedButton.icon(
            onPressed: _isSavingLog ? null : _savePlateLog,
            icon: _isSavingLog
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_task_rounded, size: 18),
            label: Text(_isSavingLog ? "Menyimpan Catatan..." : "Catat Makanan Ini / Makan Ini"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1EAB57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharePlateResult,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text("Bagikan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF475569)),
                  label: const Text(
                    "Foto Ulang",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Macro Chip Widget
  Widget _buildMacroChip({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required String letter,
    required bool isEditing,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          if (isEditing)
            SizedBox(
              width: 50,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
        ],
      ),
    );
  }

  // Protein Breakdown List (Sorted by protein descending)
  Widget _buildProteinBreakdownList() {
    final sortedItems = List<FoodPlateItem>.from(_scanResult!.items)
      ..sort((a, b) => b.protein.compareTo(a.protein));

    final totalPro = _scanResult!.total.protein > 0 ? _scanResult!.total.protein : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "RINCIAN SUMBER PROTEIN DI PIRING",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Ketuk untuk detail",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...sortedItems.map((item) {
            final originalIdx = _scanResult!.items.indexOf(item);
            final pct = ((item.protein / totalPro) * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedItemIndex = originalIdx),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${item.protein}g",
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$pct%",
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            "💡 Info Nutrisi: Protein utama berasal dari lauk hewani/nabati (ikan, telur, tahu, tempe). Nasi dan sayur secara alami juga menyumbang sedikit protein nabati (~3-4g/porsi).",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  // Micronutrients Accordion
  Widget _buildMicronutrientsAccordion(FoodMicronutrients micro) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showMicro = !_showMicro),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "LIHAT MIKRONUTRISI & MINERAL",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),
                ),
                Icon(
                  _showMicro ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_showMicro) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMicroItem("Vitamin C", micro.vitC)),
                Expanded(child: _buildMicroItem("Serat", micro.fiber, isHighlight: true)),
                Expanded(child: _buildMicroItem("Kalsium", micro.calcium)),
                Expanded(child: _buildMicroItem("Zat Besi", micro.iron)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMicroItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isHighlight ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // Meal Type Dropdown Selector
  Widget _buildMealTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KATEGORI WAKTU MAKAN",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _mealType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _mealOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt['id'] as String,
                  child: Row(
                    children: [
                      Icon(opt['icon'] as IconData, size: 18, color: opt['color'] as Color),
                      const SizedBox(width: 10),
                      Text(
                        opt['label'] as String,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _mealType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODE MANUAL: FORM & AI AUTO-FILL (Web-Matched)
  // ==========================================
  Widget _buildManualTrackingView() {
    // Realtime calculation based on portion
    final portion = double.tryParse(_manualPortionController.text) ?? 100.0;
    final multiplier = portion / 100.0;

    final calcCals = ((double.tryParse(_manualBaseCalController.text) ?? 0) * multiplier).round();
    final calcPro = (((double.tryParse(_manualBaseProController.text) ?? 0) * multiplier) * 10).round() / 10;
    final calcCar = (((double.tryParse(_manualBaseCarController.text) ?? 0) * multiplier) * 10).round() / 10;
    final calcFat = (((double.tryParse(_manualBaseFatController.text) ?? 0) * multiplier) * 10).round() / 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Center(
                  child: Icon(Icons.edit_note_rounded, color: Color(0xFF1EAB57), size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Input Nutrisi Manual",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Catat Makanan Tanpa Kamera",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Food Name Input
          const Text(
            "NAMA MAKANAN *",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualNameController,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: "Contoh: Dada Ayam Panggang, Nasi Merah",
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1EAB57), width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Portion Input
          const Text(
            "BERAT / PORSI KONSUMSI *",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualPortionController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1EAB57)),
            decoration: InputDecoration(
              suffixText: "gram",
              suffixStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1EAB57), width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),

          // ✨ AI Auto-Fill Nutrisi Button
          InkWell(
            onTap: _isGeneratingMacro ? null : _handleAutoGenerateMacro,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGeneratingMacro)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                    )
                  else
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isGeneratingMacro ? "AI Sedang Menghitung Nutrisi..." : "✨ AI Auto-Fill Nutrisi Makanan",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Base Nutrition per 100g (Grid of 4 inputs)
          const Text(
            "KANDUNGAN GIZI DASAR (PER 100 GRAM)",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildMiniNumField(
                  label: "Kalori *",
                  suffix: "kcal",
                  controller: _manualBaseCalController,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniNumField(
                  label: "Protein",
                  suffix: "g",
                  controller: _manualBaseProController,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniNumField(
                  label: "Karbohidrat",
                  suffix: "g",
                  controller: _manualBaseCarController,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniNumField(
                  label: "Lemak",
                  suffix: "g",
                  controller: _manualBaseFatController,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Manual Micronutrients Accordion
          InkWell(
            onTap: () => setState(() => _showManualMicro = !_showManualMicro),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "MIKRONUTRISI (OPSIONAL)",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                  Icon(
                    _showManualMicro ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_showManualMicro) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMiniNumField(label: "Vit C", suffix: "mg", controller: _manualBaseVitCController)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniNumField(label: "Serat", suffix: "g", controller: _manualBaseFiberController)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMiniNumField(label: "Kalsium", suffix: "mg", controller: _manualBaseCalciumController)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniNumField(label: "Zat Besi", suffix: "mg", controller: _manualBaseIronController)),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Realtime Consumed Prediction & Daily Allowance Bar
          if (calcCals > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_fire_department_rounded, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 6),
                      Text(
                        "TOTAL NUTRISI DIKONSUMSI",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Kalori",
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          RichText(
                            text: TextSpan(
                              text: "$calcCals ",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                              children: const [
                                TextSpan(
                                  text: "kcal",
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMiniBadge("P", "${calcPro}g", const Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          _buildMiniBadge("C", "${calcCar}g", const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          _buildMiniBadge("F", "${calcFat}g", const Color(0xFFF43F5E)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Daily Allowance Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "BATAS HARIAN",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                      ),
                      Text(
                        "${_todayCalories + calcCals} / $_userDailyCalories kcal",
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ((_todayCalories + calcCals) / _userDailyCalories).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (_todayCalories + calcCals) > _userDailyCalories ? const Color(0xFFF43F5E) : const Color(0xFF1EAB57),
                      ),
                    ),
                  ),
                  if ((_todayCalories + calcCals) > _userDailyCalories) ...[
                    const SizedBox(height: 4),
                    const Text(
                      "⚠️ Melebihi target kalori harian Anda!",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF43F5E)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meal Type Selector
          _buildMealTypeSelector(),
          const SizedBox(height: 18),

          // Submit Manual Log Button
          ElevatedButton.icon(
            onPressed: _isSavingManual ? null : _handleManualSubmit,
            icon: _isSavingManual
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(_isSavingManual ? "Menyimpan Catatan..." : "Simpan Catatan Makanan"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1EAB57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNumField({
    required String label,
    required String suffix,
    required TextEditingController controller,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged?.call(),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String letter, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        children: [
          Text(letter, style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w900, color: color)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==========================================
  // RIWAYAT MAKANAN TERBARU (Web-Matched)
  // ==========================================
  Widget _buildRecentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Riwayat Makanan Terbaru",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_recentScans.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.history_rounded, size: 36, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text(
                    "Belum ada riwayat makanan",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Makanan yang Anda scan atau catat akan muncul di sini.",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentScans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _recentScans[index];
              final isManual = item['type'] == 'Input Manual';
              final timeStr = _formatTimestamp(item['scannedAt']);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isManual ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isManual ? const Color(0xFFDBEAFE) : const Color(0xFFD1FAE5)),
                      ),
                      child: Center(
                        child: Icon(
                          isManual ? Icons.edit_note_rounded : Icons.restaurant_rounded,
                          color: isManual ? const Color(0xFF3B82F6) : const Color(0xFF1EAB57),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                              ),
                              if (item['mealType'] != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['mealType'] as String,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1EAB57)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['name']?.toString() ?? 'Makanan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 13, color: Color(0xFFF43F5E)),
                          const SizedBox(width: 4),
                          Text(
                            "${item['calories'] ?? 0} kcal",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Baru saja";
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return DateFormat('HH:mm').format(date);
  }
}
