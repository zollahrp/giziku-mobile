import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gizify/screens/login_screen.dart';
import 'package:gizify/screens/profiles/about_screen.dart';
import 'package:gizify/screens/profiles/edit_profile_screen.dart';
import 'package:gizify/screens/profiles/faq_screen.dart';
import 'package:gizify/widgets/avatar_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAnnual = false;
  int _selectedPlanIndex = 1; // Default: GIZIFY PRO (Paling Populer)
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: uid.isNotEmpty
              ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            if (!snapshot.hasData && uid.isNotEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1EAB57)),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            final String name = data['name'] ?? user?.displayName ?? "User Gizify";
            final String email = data['email'] ?? user?.email ?? "";
            final String role = (data['role'] ?? "BASIC").toString().toUpperCase();
            final String? photoURL = data['photoURL'] ?? data['photo_url'] ?? user?.photoURL;
            final String location = data['location'] ?? "Lokasi belum diatur";
            final String gender = data['gender'] ?? "Belum diatur";
            final String birthDate = data['birthDate'] ?? data['date_of_birth'] ?? "Belum diatur";

            final String height = data['height']?.toString() ?? "0";
            final String weight = data['weight']?.toString() ?? "0";
            final String bmi = data['bmi']?.toString() ?? "0";
            final String bmiStatus = data['bmiStatus'] ?? data['bmi_category'] ?? "-";
            final String idealWeight = data['idealWeight']?.toString() ?? data['ideal_weight']?.toString() ?? "0";
            final String calories = data['calories']?.toString() ?? data['daily_calories']?.toString() ?? "0";

            final String bodyGoal = data['bodyGoal'] ?? data['body_goal'] ?? "Belum diatur";
            final String activity = data['activity'] ?? data['activity_level'] ?? "Belum diatur";
            final String exercise = data['exercise'] ?? data['exercise_level'] ?? "Belum diatur";

            // Diet
            dynamic rawDiet = data['dietTypes'] ?? data['food_type'] ?? data['dietType'];
            List<String> dietTypes = [];
            if (rawDiet is List) {
              dietTypes = List<String>.from(rawDiet.map((e) => e.toString()));
            } else if (rawDiet is String && rawDiet.isNotEmpty && rawDiet != "Belum diatur") {
              dietTypes = [rawDiet];
            }

            final String macroFocus = data['macroFocus'] ?? "Seimbang";
            final String mealsPerDay = data['mealsPerDay'] ?? data['eating_pattern'] ?? "Belum diatur";
            final String waterIntake = data['waterIntake'] ?? "Belum diatur";
            final String favoriteFoods = data['favoriteFoods'] ?? data['favorite_foods'] ?? "Belum diatur";
            final String dislikedFoods = data['dislikedFoods'] ?? data['disliked_foods'] ?? "Tidak Ada";

            // Medis
            final String medicalHistory = data['medicalHistory'] ?? (data['chronic_disease'] is List ? (data['chronic_disease'] as List).join(', ') : "Tidak Ada");
            dynamic rawAllergies = data['allergies'];
            List<String> allergies = [];
            if (rawAllergies is List) {
              allergies = List<String>.from(rawAllergies.map((e) => e.toString()));
            }

            // Dapur
            final String cookingSkill = data['cookingSkill'] ?? "Pemula";
            dynamic rawKitchen = data['kitchenEquipments'];
            List<String> kitchenEquipments = [];
            if (rawKitchen is List) {
              kitchenEquipments = List<String>.from(rawKitchen.map((e) => e.toString()));
            }

            // Macros
            final macrosMap = data['macros'] is Map ? (data['macros'] as Map) : null;
            final int pro = int.tryParse(macrosMap?['pro']?.toString() ?? data['protein_need']?.toString() ?? '') ?? 0;
            final int car = int.tryParse(macrosMap?['car']?.toString() ?? data['carb_need']?.toString() ?? '') ?? 0;
            final int fat = int.tryParse(macrosMap?['fat']?.toString() ?? data['fat_need']?.toString() ?? '') ?? 0;
            final int totalMacros = pro + car + fat;

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ==========================================
                      // 1. VIP HEADER BANNER (PROFILE SUMMARY)
                      // ==========================================
                      _buildHeaderBanner(
                        context: context,
                        name: name,
                        email: email,
                        role: role,
                        photoURL: photoURL,
                        location: location,
                        bodyGoal: bodyGoal,
                      ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 2. 4 METRIK KESEHATAN LIVE (SAAS STYLE)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: "TARGET KALORI",
                                value: calories,
                                unit: "kkal",
                                subtitle: "Kebutuhan harian metabolik",
                                icon: Icons.local_fire_department_rounded,
                                iconColor: const Color(0xFF1EAB57),
                                iconBg: const Color(0xFFE8F8EE),
                                accentColor: const Color(0xFF1EAB57),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: "STATUS BMI",
                                value: bmiStatus,
                                unit: "($bmi)",
                                subtitle: "Kategori massa tubuh WHO",
                                icon: Icons.favorite_rounded,
                                iconColor: bmiStatus.contains("Normal") || bmiStatus.contains("Atletis")
                                    ? const Color(0xFF1EAB57)
                                    : const Color(0xFFF59E0B),
                                iconBg: bmiStatus.contains("Normal") || bmiStatus.contains("Atletis")
                                    ? const Color(0xFFE8F8EE)
                                    : const Color(0xFFFEF3C7),
                                accentColor: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: "BERAT AKTUAL",
                                value: weight,
                                unit: "kg",
                                subtitle: "Tinggi badan: $height cm",
                                icon: Icons.monitor_weight_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                iconBg: const Color(0xFFFEF3C7),
                                accentColor: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: "BERAT IDEAL",
                                value: idealWeight,
                                unit: "kg",
                                subtitle: "Standar modifikasi Broca",
                                icon: Icons.track_changes_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                iconBg: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 3. BREAKDOWN MAKRONUTRISI
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildMacroCard(
                      pro: pro,
                      car: car,
                      fat: fat,
                      total: totalMacros,
                      macroFocus: macroFocus,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 4. INFORMASI DASAR
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildCardContainer(
                      title: "Informasi Dasar",
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF1EAB57),
                      children: [
                        _buildInfoRow(
                          icon: Icons.account_circle_outlined,
                          label: "Nama & Email",
                          value: "$name ($email)",
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.wc_rounded,
                          label: "Jenis Kelamin & Tinggi",
                          value: "$gender • $height cm",
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.cake_outlined,
                          label: "Tanggal Lahir",
                          value: birthDate,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: "Lokasi",
                          value: location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 6. KESEHATAN, ALERGI & MEDIS
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildCardContainer(
                      title: "Kesehatan & Riwayat Medis",
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFFF43F5E),
                      children: [
                        _buildChipRow(
                          label: "Pantangan & Alergi",
                          chips: allergies.isNotEmpty ? allergies : ["Tidak Ada Alergi"],
                          isDanger: allergies.isNotEmpty,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildChipRow(
                          label: "Makanan Tidak Disukai",
                          chips: dislikedFoods.isNotEmpty && dislikedFoods != "Tidak Ada"
                              ? dislikedFoods.split(',').map((e) => e.trim()).toList()
                              : ["Tidak Ada"],
                          isDanger: false,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.healing_rounded,
                          label: "Riwayat Penyakit",
                          value: medicalHistory,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 7. POLA HIDUP & AKTIVITAS FISIK
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildCardContainer(
                      title: "Pola Hidup & Aktivitas",
                      icon: Icons.directions_run_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      children: [
                        _buildInfoRow(
                          icon: Icons.work_outline_rounded,
                          label: "Aktivitas Harian",
                          value: activity,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.fitness_center_rounded,
                          label: "Olahraga Mingguan",
                          value: exercise,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 8. PREFERENSI DIET & DAPUR
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildCardContainer(
                      title: "Preferensi Diet & Dapur",
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      children: [
                        _buildChipRow(
                          label: "Tipe Diet",
                          chips: dietTypes.isNotEmpty ? dietTypes : ["Normal / Bebas"],
                          isDanger: false,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.schedule_rounded,
                          label: "Pola Makan Harian",
                          value: mealsPerDay,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: "Asupan Air",
                          value: waterIntake,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.favorite_border_rounded,
                          label: "Makanan Favorit",
                          value: favoriteFoods,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.soup_kitchen_rounded,
                          label: "Keahlian Memasak",
                          value: cookingSkill,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildChipRow(
                          label: "Peralatan Dapur Dimiliki",
                          chips: kitchenEquipments.isNotEmpty
                              ? kitchenEquipments
                              : ["Kompor", "Rice Cooker"],
                          isDanger: false,
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 9. ANGGOTA KELUARGA (FAMILY PLAN ONLY)
                  // ==========================================
                  if (role == "FAMILY" || data['familyId'] != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildFamilySection(context, uid),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ==========================================
                  // 10. MENU PENGATURAN & AKUN
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildCardContainer(
                      title: "Pengaturan & Bantuan",
                      icon: Icons.settings_rounded,
                      iconColor: const Color(0xFF64748B),
                      children: [
                        _buildMenuItem(
                          icon: Icons.workspace_premium_rounded,
                          title: "Paket Langganan (Pricing)",
                          subtitle: "Tingkatkan akun ke Pro atau Family",
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showPricingModal(context, role, uid),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildMenuItem(
                          icon: Icons.edit_note_rounded,
                          title: "Ubah Profil",
                          subtitle: "Perbarui data berat, target, dan gizi",
                          color: const Color(0xFF1EAB57),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: "Pusat Bantuan & FAQ",
                          subtitle: "Tanya jawab seputar gizi dan aplikasi",
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FAQScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildMenuItem(
                          icon: Icons.info_outline_rounded,
                          title: "Tentang Gizify",
                          subtitle: "Versi 2.0 • Solusi Nutrisi Cerdas AI",
                          color: const Color(0xFF8B5CF6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildMenuItem(
                          icon: Icons.delete_outline_rounded,
                          title: "Hapus Akun",
                          subtitle: "Hapus permanen profil & data Anda",
                          color: const Color(0xFFF43F5E),
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildMenuItem(
                          icon: Icons.logout_rounded,
                          title: "Keluar",
                          subtitle: "Keluar dari sesi akun Anda",
                          color: const Color(0xFF64748B),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Extra space at bottom so content never gets covered by curved navigation bar
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ==========================================
            // STICKY COMPACT TOP NAVBAR (WHEN SCROLLED)
            // ==========================================
            _buildStickyHeader(
              context: context,
              name: name,
              email: email,
              role: role,
              photoURL: photoURL,
            ),
          ],
        );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // POPUP MODAL: PRICING & UPGRADE PLANS (GIZIFY.ID/ID/PRICING)
  // =========================================================================
  void _showPricingModal(BuildContext context, String currentRole, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final plans = [
              {
                'id': 'BASIC',
                'name': 'GIZIFY BASIC',
                'badge': 'GRATIS SELAMANYA',
                'tagline': 'Langkah awal sadar kalori harian.',
                'priceMonthly': 0,
                'priceAnnual': 0,
                'features': [
                  {'text': '5x Scan Kalori AI / Hari', 'included': true},
                  {'text': 'Akses Resep Standar', 'included': true},
                  {'text': 'Tracking BB & BMI Dasar', 'included': true},
                  {'text': 'Laporan Nutrisi Mingguan', 'included': false},
                  {'text': 'Custom Meal Plan AI Otomatis', 'included': false},
                ],
              },
              {
                'id': 'PRO',
                'name': 'GIZIFY PRO',
                'badge': 'PALING PAS BUAT KAMU',
                'tagline': 'Unlock semua kekuatan AI untuk capai body goals lebih cepat.',
                'priceMonthly': 25000,
                'priceAnnual': 240000,
                'features': [
                  {'text': 'Unlimited AI Food Scan', 'included': true},
                  {'text': 'Akses 1000+ Resep Premium', 'included': true},
                  {'text': 'Tracking Makro & Mikro Lengkap', 'included': true},
                  {'text': 'Custom Meal Plan AI Otomatis', 'included': true},
                  {'text': 'Gizibot Assistant 24/7', 'included': true},
                ],
              },
              {
                'id': 'FAMILY',
                'name': 'GIZIFY FAMILY',
                'badge': 'MAKSIMAL 10 ANGGOTA',
                'tagline': 'Satu langganan untuk seluruh anggota keluarga di rumah.',
                'priceMonthly': 80000,
                'priceAnnual': 780000,
                'features': [
                  {'text': 'Semua Fitur Pro Member', 'included': true},
                  {'text': 'Sampai 10 Profil Anggota Keluarga', 'included': true},
                  {'text': 'Dashboard Nutrisi Terintegrasi', 'included': true},
                  {'text': 'Laporan Gizi Anak & Dewasa', 'included': true},
                  {'text': 'Priority CS Support 24/7', 'included': true},
                ],
              },
            ];

            final activePlan = plans[_selectedPlanIndex];
            final isCurrentPlan = currentRole == activePlan['id'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle & Close Button Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE8F8EE), Color(0xFFD1FAE5)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF1EAB57).withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, color: Color(0xFF1EAB57), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "PRICING PLAN",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1EAB57),
                                        letterSpacing: 0.8,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentRole == "FAMILY"
                                      ? const Color(0xFFFEF3C7)
                                      : (currentRole == "PRO" ? const Color(0xFFE8F8EE) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: currentRole == "FAMILY"
                                        ? const Color(0xFFF59E0B).withOpacity(0.4)
                                        : (currentRole == "PRO" ? const Color(0xFF1EAB57).withOpacity(0.4) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Text(
                                  "STATUS: $currentRole",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: currentRole == "FAMILY"
                                        ? const Color(0xFFB45309)
                                        : (currentRole == "PRO" ? const Color(0xFF1EAB57) : const Color(0xFF64748B)),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            "Mulai Dari Nol, Upgrade Kapan Aja.",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Poppins',
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Pilih paket langganan terbaik untuk memaksimalkan hasil kesehatanmu dan keluarga.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                              height: 1.4,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Billing Cycle Switch (Bulanan vs Tahunan)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => _isAnnual = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: !_isAnnual ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_isAnnual
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Bulanan",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: !_isAnnual ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => _isAnnual = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _isAnnual ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isAnnual
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Tahunan",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: _isAnnual ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1EAB57),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "-20%",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Plan Selector Tabs
                          Row(
                            children: List.generate(plans.length, (idx) {
                              final p = plans[idx];
                              final isSel = _selectedPlanIndex == idx;
                              final isPopular = p['id'] == 'PRO';

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: idx == 0 ? 0 : 4,
                                    right: idx == plans.length - 1 ? 0 : 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => _selectedPlanIndex = idx),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? (isPopular ? const Color(0xFF1EAB57) : const Color(0xFF0F172A))
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSel
                                              ? (isPopular ? const Color(0xFF1EAB57) : const Color(0xFF0F172A))
                                              : const Color(0xFFE2E8F0),
                                          width: isSel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          if (isPopular)
                                            const Text(
                                              "⭐ POPULER",
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFFDE047),
                                                letterSpacing: 0.5,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          Text(
                                            p['name'].toString().replaceAll("GIZIFY ", ""),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: isSel ? Colors.white : const Color(0xFF475569),
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Active Selected Plan Card (Featured Layout)
                          _buildActivePlanCard(
                            context: context,
                            plan: activePlan,
                            isAnnual: _isAnnual,
                            isCurrentPlan: isCurrentPlan,
                            uid: uid,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // CARD DETAIL: ACTIVE SELECTED PLAN
  // =========================================================================
  Widget _buildActivePlanCard({
    required BuildContext context,
    required Map<String, dynamic> plan,
    required bool isAnnual,
    required bool isCurrentPlan,
    required String uid,
  }) {
    final String planId = plan['id'];
    final bool isPro = planId == 'PRO';
    final bool isFamily = planId == 'FAMILY';
    final int price = isAnnual ? (plan['priceAnnual'] as int) : (plan['priceMonthly'] as int);
    final String formattedPrice = price == 0
        ? "Gratis"
        : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
    final String periodLabel = price == 0 ? "Selamanya" : (isAnnual ? "/ tahun" : "/ bulan");

    final List<Map<String, dynamic>> features = (plan['features'] as List).cast<Map<String, dynamic>>();

    return Container(
      decoration: BoxDecoration(
        color: isPro
            ? const Color(0xFF0D3823)
            : (isFamily ? const Color(0xFF1E1B4B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPro
              ? const Color(0xFF24C667)
              : (isFamily ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
          width: isPro || isFamily ? 1.5 : 1,
        ),
        boxShadow: isPro
            ? [
                BoxShadow(
                  color: const Color(0xFF1EAB57).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badge & Category Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro
                      ? const Color(0xFF1EAB57)
                      : (isFamily ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plan['badge'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPro || isFamily ? Colors.white : const Color(0xFF475569),
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(
                isPro
                    ? Icons.bolt_rounded
                    : (isFamily ? Icons.diversity_1_rounded : Icons.spa_outlined),
                color: isPro
                    ? const Color(0xFFFDE047)
                    : (isFamily ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8)),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Plan Name & Tagline
          Text(
            plan['name'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isPro || isFamily ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan['tagline'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPro || isFamily ? Colors.white70 : const Color(0xFF64748B),
              fontFamily: 'Poppins',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Price Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedPrice,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isPro
                      ? const Color(0xFF4ADE80)
                      : (isFamily ? const Color(0xFFA5B4FC) : const Color(0xFF0F172A)),
                  fontFamily: 'Poppins',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                periodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPro || isFamily ? Colors.white60 : const Color(0xFF94A3B8),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          if (isAnnual && price > 0) ...[
            const SizedBox(height: 2),
            Text(
              "Setara ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price ~/ 12)} / bulan (Hemat 20%)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPro
                    ? const Color(0xFF86EFAC)
                    : (isFamily ? const Color(0xFFC7D2FE) : const Color(0xFF1EAB57)),
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 18),

          Divider(
            color: isPro || isFamily ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
            height: 1,
          ),
          const SizedBox(height: 16),

          // Features List
          ...features.map((feat) {
            final bool included = feat['included'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    included ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: included
                        ? (isPro
                            ? const Color(0xFF4ADE80)
                            : (isFamily ? const Color(0xFF818CF8) : const Color(0xFF1EAB57)))
                        : (isPro || isFamily ? Colors.white24 : const Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feat['text'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: included ? FontWeight.w600 : FontWeight.w500,
                        decoration: included ? TextDecoration.none : TextDecoration.lineThrough,
                        color: included
                            ? (isPro || isFamily ? Colors.white : const Color(0xFF1E293B))
                            : (isPro || isFamily ? Colors.white38 : const Color(0xFF94A3B8)),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // CTA Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isCurrentPlan
                ? Container(
                    decoration: BoxDecoration(
                      color: isPro || isFamily ? Colors.white.withOpacity(0.15) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPro || isFamily ? Colors.white30 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: isPro || isFamily ? const Color(0xFF4ADE80) : const Color(0xFF1EAB57),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Paket Aktif Anda",
                            style: TextStyle(
                              color: isPro || isFamily ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _openUpgradeModal(context, plan, isAnnual, uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPro
                          ? const Color(0xFF1EAB57)
                          : (isFamily ? const Color(0xFF6366F1) : const Color(0xFF0F172A)),
                      elevation: isPro ? 8 : 2,
                      shadowColor: isPro ? const Color(0xFF1EAB57).withOpacity(0.5) : Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPro
                              ? Icons.rocket_launch_rounded
                              : (isFamily ? Icons.group_add_rounded : Icons.arrow_forward_rounded),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          planId == 'BASIC'
                              ? "Gunakan Paket Gratis"
                              : "Tingkatkan ke ${plan['name'].toString().replaceAll("GIZIFY ", "")}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          // Trust Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_rounded,
                size: 12,
                color: isPro || isFamily ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                "14-Hari Jaminan Uang Kembali • Batal Kapan Saja",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPro || isFamily ? Colors.white38 : const Color(0xFF94A3B8),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODAL UPGRADE & CHECKOUT (SIMULASI MIDTRANS SNAP SEPERTI WEB GIZIFY)
  // =========================================================================
  void _openUpgradeModal(BuildContext context, Map<String, dynamic> plan, bool isAnnual, String uid) {
    final int price = isAnnual ? (plan['priceAnnual'] as int) : (plan['priceMonthly'] as int);
    final String formattedPrice = price == 0
        ? "Gratis"
        : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
    final String cycleLabel = price == 0 ? "Akses Dasar Selamanya" : (isAnnual ? "Tahunan (Hemat 20%)" : "Bulanan");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selectedPayment = "QRIS (GoPay, OVO, Dana)";

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plan['badge'],
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1EAB57),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(
                          plan['id'] == 'PRO'
                              ? Icons.bolt_rounded
                              : (plan['id'] == 'FAMILY' ? Icons.diversity_1_rounded : Icons.spa_outlined),
                          color: const Color(0xFF1EAB57),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan['tagline'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ringkasan Pembayaran
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Biaya Langganan",
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                            ),
                            Text(
                              formattedPrice,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Siklus Penagihan",
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'Poppins'),
                            ),
                            Text(
                              cycleLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1EAB57),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pilihan Metode Pembayaran
                  if (price > 0) ...[
                    const Text(
                      "PILIH METODE PEMBAYARAN",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      {"name": "QRIS (GoPay, OVO, Dana, ShopeePay)", "icon": Icons.qr_code_rounded},
                      {"name": "Virtual Account BCA / Mandiri / BRI", "icon": Icons.account_balance_rounded},
                      {"name": "Kartu Kredit / Debit Online", "icon": Icons.credit_card_rounded},
                    ].map((m) {
                      final isSelected = selectedPayment == m['name'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setModalState(() => selectedPayment = m['name'] as String),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F8EE) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  m['icon'] as IconData,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    m['name'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF334155),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF1EAB57), size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                  ],

                  // Tombol Konfirmasi & Aktivasi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(uid).update({
                            'role': plan['id'],
                          });
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F8EE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.celebration_rounded,
                                      color: Color(0xFF1EAB57),
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Selamat Datang di ${plan['name']}!",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Paket Anda telah berhasil diaktifkan. Nikmati fitur premium AI dan panduan nutrisi eksklusif Gizify.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontFamily: 'Poppins',
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(c),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1EAB57),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text(
                                        "Mulai Eksplorasi",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Gagal mengaktifkan paket: $e"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EAB57),
                        elevation: 4,
                        shadowColor: const Color(0xFF1EAB57).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        price == 0 ? "Aktifkan Paket Dasar" : "Bayar & Aktivasi Sekarang",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // WIDGET HELPER: STICKY COMPACT TOP NAVBAR (WHEN SCROLLED DOWN)
  // =========================================================================
  Widget _buildStickyHeader({
    required BuildContext context,
    required String name,
    required String email,
    required String role,
    required String? photoURL,
  }) {
    final bool isVip = role == "FAMILY" || role == "PRO";
    final String cleanUsername = email.isNotEmpty ? email.split('@').first : "user";

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, _) {
        final double offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
        // Fade & slide in between offset 140 and 220
        final double progress = ((offset - 130) / 70).clamp(0.0, 1.0);

        if (progress <= 0.01) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, -12 * (1 - progress)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF147A3E),
                      Color(0xFF1EAB57),
                      Color(0xFF24C667),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1EAB57).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button if pushed route
                    if (Navigator.canPop(context)) ...[
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ],

                    // Tap on User Info -> Scroll to top smoothly
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Row(
                          children: [
                            // Compact Avatar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isVip ? const Color(0xFFFDE68A) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFFE2E8F0),
                                backgroundImage: getProfileImageProvider(photoURL),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Name & Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFFFDE047),
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "@$cleanUsername",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Compact "Ubah Profil & Target" Pill Action Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF1EAB57),
                                size: 12,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Ubah Profil",
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // WIDGET HELPER: AESTHETIC GEN-Z PROFILE HEADER
  // =========================================================================
  Widget _buildHeaderBanner({
    required BuildContext context,
    required String name,
    required String email,
    required String role,
    required String? photoURL,
    required String location,
    required String bodyGoal,
  }) {
    final bool isVip = role == "FAMILY" || role == "PRO";
    final String cleanUsername = email.isNotEmpty ? email.split('@').first : "user";
    final String cleanLocation = location.isNotEmpty && location != "Lokasi belum diatur"
        ? location.split(',').first.trim()
        : "Indonesia";

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF18994E),
            Color(0xFF1EAB57),
            Color(0xFF22C55E),
            Color(0xFF2AD882),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x302AD882),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Aesthetic Floating Circles (Glass Orbs)
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Header Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Mini Bar (Cute Handle & Status Pill)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (Navigator.canPop(context)) ...[
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.35)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                        // Handle Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.28)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alternate_email_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                cleanUsername,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // VIP Status Chip (Pastel Cream / Gold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isVip
                              ? const [Color(0xFFFEF3C7), Color(0xFFFDE68A)]
                              : [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.15)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isVip
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            role == "FAMILY"
                                ? Icons.diversity_3_rounded
                                : (role == "PRO" ? Icons.workspace_premium_rounded : Icons.eco_rounded),
                            size: 13,
                            color: isVip ? const Color(0xFF92400E) : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            role == "FAMILY"
                                ? "Family VIP"
                                : (role == "PRO" ? "Pro VIP" : "Basic Member"),
                            style: TextStyle(
                              color: isVip ? const Color(0xFF92400E) : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Center Row: Avatar & Profile Bio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Aesthetic Clean Avatar with Double Ring
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.95),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: getProfileImageProvider(photoURL),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isVip ? const Color(0xFFFBBF24) : const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              isVip ? Icons.workspace_premium_rounded : Icons.check_rounded,
                              color: isVip ? const Color(0xFF78350F) : Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Name, Email, & Aesthetic Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFFFDE047),
                                size: 19,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Cute Aesthetic Pill Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      cleanLocation,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (bodyGoal.isNotEmpty && bodyGoal != "Belum diatur")
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.track_changes_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        bodyGoal,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.5,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Aesthetic Action Buttons (Edit Profile Pill + Quick Help Button)
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  color: Color(0xFF1EAB57),
                                  size: 19,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Ubah Profil & Target",
                                  style: TextStyle(
                                    color: Color(0xFF1EAB57),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Quick Action: FAQ / Bantuan Glass Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FAQScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: METRIC CARD
  // =========================================================================
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: MAKRONUTRISI LIVE CARD
  // =========================================================================
  Widget _buildMacroCard({
    required int pro,
    required int car,
    required int fat,
    required int total,
    required String macroFocus,
  }) {
    final double safeTotal = total > 0 ? total.toDouble() : 1.0;
    final double proWidth = (pro / safeTotal);
    final double carWidth = (car / safeTotal);
    final double fatWidth = (fat / safeTotal);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF1EAB57),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Distribusi Makronutrisi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      "Fokus: $macroFocus",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  _buildMacroBarSegment(proWidth, const Color(0xFF3B82F6)),
                  _buildMacroBarSegment(carWidth, const Color(0xFF10B981)),
                  _buildMacroBarSegment(fatWidth, const Color(0xFFF43F5E)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Kolom Makro (Protein, Karbo, Lemak)
          Row(
            children: [
              Expanded(
                child: _buildMacroBox(
                  label: "PROTEIN",
                  value: "${pro}g",
                  color: const Color(0xFF3B82F6),
                  bg: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBox(
                  label: "KARBO",
                  value: "${car}g",
                  color: const Color(0xFF10B981),
                  bg: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBox(
                  label: "LEMAK",
                  value: "${fat}g",
                  color: const Color(0xFFF43F5E),
                  bg: const Color(0xFFFFF1F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1EAB57), size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Dihitung otomatis berbasis standar nutrisi klinis Mifflin-St Jeor & WHO.",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
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

  Widget _buildMacroBarSegment(double flexValue, Color color) {
    if (flexValue <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: (flexValue * 100).toInt().clamp(1, 100),
      child: Container(color: color),
    );
  }

  Widget _buildMacroBox({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: CARD CONTAINER STANDAR
  // =========================================================================
  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: INFO ROW
  // =========================================================================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: CHIP ROW
  // =========================================================================
  Widget _buildChipRow({
    required String label,
    required List<String> chips,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDanger ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDanger ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDanger ? const Color(0xFFE11D48) : const Color(0xFF334155),
                    fontFamily: 'Poppins',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPER: FAMILY SECTION
  // =========================================================================
  Widget _buildFamilySection(BuildContext context, String ownerUid) {
    return _buildCardContainer(
      title: "Anggota Keluarga (Family Plan)",
      icon: Icons.family_restroom_rounded,
      iconColor: const Color(0xFF1EAB57),
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('familyId', isEqualTo: ownerUid)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final members = docs.where((d) => d.id != ownerUid).toList();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${members.length} dari 9 Anggota Tambahan",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "OWNER",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1EAB57),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.group_add_rounded, color: Color(0xFF94A3B8), size: 32),
                          SizedBox(height: 8),
                          Text(
                            "Belum ada anggota keluarga tambahan.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Kelola dan tambahkan anggota keluarga Anda langsung melalui website Gizify.id",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...members.map((m) {
                      final mData = m.data() as Map<String, dynamic>;
                      final mName = mData['name'] ?? "Anggota";
                      final mRelation = mData['relation'] ?? "Keluarga";
                      final mCal = mData['calories'] ?? mData['daily_calories'] ?? "-";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                mName.isNotEmpty ? mName[0].toUpperCase() : 'F',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Poppins'),
                                  ),
                                  Text(
                                    "$mRelation • $mCal kkal",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // WIDGET HELPER: MENU ITEM
  // =========================================================================
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }



  // =========================================================================
  // DIALOG: HAPUS AKUN
  // =========================================================================
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Hapus Akun Permanen",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontFamily: 'Poppins'),
        ),
        content: const Text(
          "Tindakan ini tidak dapat dibatalkan. Seluruh data nutrisi, histori, dan profil Anda di Gizify akan dihapus secara permanen.",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  await user.delete();
                }
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal menghapus akun: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Hapus Permanen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
