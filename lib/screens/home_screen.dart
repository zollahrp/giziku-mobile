import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:gizify/screens/scanner/scanner_screen.dart';
import 'package:gizify/screens/gizi_chatbot_screen.dart';
import 'package:gizify/screens/meal_plan_screen.dart';
import 'package:gizify/screens/profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Animation Controllers for Staggered Entrance & Ambient Pulses
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  // Tab State: Harian, Mingguan, Bulanan
  String _activeTab = "Harian";

  // Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  // User Profile Data from Firestore
  Map<String, dynamic> _userData = {
    'name': 'User Gizify',
    'role': 'BASIC',
    'photoURL': '',
    'calories': '2000',
    'bmiStatus': 'Normal',
    'idealWeight': '-',
    'bodyGoal': 'Menjaga Berat Badan',
    'dislikedFoods': 'Tidak Ada',
  };

  // Nutrition Totals for Today
  int _todayCalories = 0;
  int _todayProtein = 0;
  int _todayCarbs = 0;
  int _todayFat = 0;

  // Micronutrients
  double _vitC = 0.0;
  double _fiber = 0.0;
  double _calcium = 0.0;
  double _iron = 0.0;

  // Food lists & logs
  List<Map<String, dynamic>> _todayFoodList = [];
  List<Map<String, dynamic>> _scanHistory = [];
  List<int> _weeklyData = [0, 0, 0, 0, 0, 0, 0]; // Senin (0) s/d Minggu (6)
  Set<int> _loggedDays = {};
  Set<int> _planDays = {};

  // Calendar State
  DateTime _calDate = DateTime.now();

  // Notifications State
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _notifSubscription;

  // Today's Scheduled Meals
  List<Map<String, dynamic>> _todayScheduledMeals = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fetchUserDataAndLogs();
    _listenToNotifications();
    _fetchScheduledMeals();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _notifSubscription?.cancel();
    super.dispose();
  }

  // Greeting based on current hour (matching web)
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Selamat Pagi";
    if (hour >= 12 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "G";
    return name.trim().substring(0, 1).toUpperCase();
  }

  // Fetch Firestore User Data & Food Logs for Current Month
  Future<void> _fetchUserDataAndLogs() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch User Profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() ?? {};
        setState(() {
          _userData = {
            'name': data['name'] ?? currentUser?.displayName ?? 'User Gizify',
            'role': data['role'] ?? 'BASIC',
            'photoURL': data['photoURL'] ?? currentUser?.photoURL ?? '',
            'calories': (data['daily_calories'] ?? data['calories'] ?? '2000').toString(),
            'bmiStatus': (data['bmiStatus'] ?? data['bmi_status'] ?? 'Normal').toString(),
            'idealWeight': (data['idealWeight'] ?? data['ideal_weight'] ?? '-').toString(),
            'bodyGoal': (data['body_goal'] ?? data['bodyGoal'] ?? 'Menjaga Berat Badan').toString(),
            'dislikedFoods': (data['dislikedFoods'] ?? data['disliked_foods'] ?? 'Tidak Ada').toString(),
          };
        });
      }

      // 2. Fetch Food Logs for this Month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final todayStart = DateTime(now.year, now.month, now.day);

      // Current week Monday (Senin)
      final currentWeekday = now.weekday; // 1 (Mon) - 7 (Sun)
      final firstDayOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));

      final logsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();

      List<int> weekTotals = [0, 0, 0, 0, 0, 0, 0];
      int calsToday = 0;
      int pro = 0;
      int car = 0;
      int fat = 0;
      double vitCVal = 0.0;
      double fiberVal = 0.0;
      double calciumVal = 0.0;
      double ironVal = 0.0;

      final List<Map<String, dynamic>> todayFoods = [];
      final Set<int> loggedDaysSet = {};

      double parseNum(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) {
          final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
          return double.tryParse(cleaned) ?? 0.0;
        }
        return 0.0;
      }

      for (var doc in logsSnap.docs) {
        final data = doc.data();
        DateTime scannedAt = (data['scannedAt'] as Timestamp?)?.toDate() ?? now;

        loggedDaysSet.add(scannedAt.day);

        // Check if within current week (Senin..Minggu)
        if (!scannedAt.isBefore(firstDayOfWeek)) {
          int dayIdx = scannedAt.weekday - 1; // 0 for Mon, 6 for Sun
          if (dayIdx >= 0 && dayIdx < 7) {
            weekTotals[dayIdx] += (data['calories'] as num?)?.toInt() ?? 0;
          }
        }

        // Check if today
        if (!scannedAt.isBefore(todayStart)) {
          calsToday += (data['calories'] as num?)?.toInt() ?? 0;
          pro += (data['protein'] as num?)?.toInt() ?? 0;
          car += (data['carbs'] as num?)?.toInt() ?? 0;
          fat += (data['fat'] as num?)?.toInt() ?? 0;

          final micro = data['micronutrients'] as Map<String, dynamic>? ?? {};
          vitCVal += parseNum(micro['vitC'] ?? micro['vitaminC'] ?? data['vitC']);
          fiberVal += parseNum(micro['fiber'] ?? data['fiber']);
          calciumVal += parseNum(micro['calcium'] ?? data['calcium']);
          ironVal += parseNum(micro['iron'] ?? data['iron']);

          todayFoods.add({
            'id': doc.id,
            'name': data['name'] ?? 'Makanan',
            'calories': (data['calories'] as num?)?.toInt() ?? 0,
            'protein': (data['protein'] as num?)?.toInt() ?? 0,
            'carbs': (data['carbs'] as num?)?.toInt() ?? 0,
            'fat': (data['fat'] as num?)?.toInt() ?? 0,
            'mealType': data['mealType'] ?? 'Makan',
            'time': DateFormat('HH:mm').format(scannedAt),
            'scannedAt': scannedAt,
          });
        }
      }

      // 3. Fetch Recent Scan History (Latest 5 items)
      final histSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .orderBy('scannedAt', descending: true)
          .limit(5)
          .get();

      final List<Map<String, dynamic>> history = [];
      for (var doc in histSnap.docs) {
        final d = doc.data();
        history.add({
          'id': doc.id,
          'name': d['name'] ?? 'Makanan',
          'type': d['type'] ?? 'Gizify Vision',
          'mealType': d['mealType'] ?? 'Makan',
          'calories': (d['calories'] as num?)?.toInt() ?? 0,
          'scannedAt': (d['scannedAt'] as Timestamp?)?.toDate() ?? now,
        });
      }

      if (mounted) {
        setState(() {
          _weeklyData = weekTotals;
          _todayCalories = calsToday;
          _todayProtein = pro;
          _todayCarbs = car;
          _todayFat = fat;
          _vitC = (vitCVal * 10).round() / 10;
          _fiber = (fiberVal * 10).round() / 10;
          _calcium = (calciumVal * 10).round() / 10;
          _iron = (ironVal * 10).round() / 10;
          _todayFoodList = todayFoods;
          _loggedDays = loggedDaysSet;
          _scanHistory = history;
          _isLoading = false;
        });
        _entranceController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint("Error fetching home data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _entranceController.forward(from: 0.0);
      }
    }
  }

  // Realtime Notifications Listener
  void _listenToNotifications() {
    final uid = currentUser?.uid;
    if (uid == null) return;

    _notifSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      final notifs = snapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'title': d['title'] ?? 'Notifikasi',
          'message': d['message'] ?? '',
          'type': d['type'] ?? 'info',
          'isRead': d['isRead'] ?? false,
          'createdAt': (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = notifs;
        });
      }
    }, onError: (e) {
      debugPrint("Notif stream error: $e");
    });
  }

  // Fetch Scheduled Meals for Today
  Future<void> _fetchScheduledMeals() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scheduled_meals')
          .get();

      final Set<int> planDaysSet = {};
      final List<Map<String, dynamic>> todayMeals = [];

      for (var doc in snap.docs) {
        final d = doc.data();
        final dateStr = (d['date'] ?? '').toString();
        if (dateStr.isNotEmpty) {
          try {
            final parsedDate = DateTime.parse(dateStr);
            if (parsedDate.month == _calDate.month && parsedDate.year == _calDate.year) {
              planDaysSet.add(parsedDate.day);
            }
            if (dateStr == todayStr) {
              todayMeals.add({
                'id': doc.id,
                'title': d['title'] ?? 'Menu Makanan',
                'time': d['time'] ?? '12:00',
                'type': d['category'] ?? d['type'] ?? 'Makan Siang',
                'calories': (d['estimated_calories'] ?? d['calories'] ?? 350) as int,
                'price': (d['estimated_price'] ?? d['price'] ?? 0) as int,
                'recipeData': d,
              });
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _planDays = planDaysSet;
          _todayScheduledMeals = todayMeals;
        });
      }
    } catch (e) {
      debugPrint("Error fetching scheduled meals: $e");
    }
  }

  // Notification Actions
  Future<void> _markNotifAsRead(String notifId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("Error mark as read: $e");
    }
  }

  Future<void> _markAllNotifsAsRead() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var n in _notifications) {
        if (n['isRead'] == false) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(n['id']);
          batch.update(ref, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error mark all read: $e");
    }
  }

  Future<void> _deleteNotif(String notifId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      debugPrint("Error delete notif: $e");
    }
  }

  Future<void> _deleteAllNotifs() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var n in _notifications) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(n['id']);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error delete all notifs: $e");
    }
  }

  // Target macro calculations (30% Protein, 40% Carbs, 30% Fat)
  int get _targetCals => int.tryParse(_userData['calories'] ?? '2000') ?? 2000;
  int get _targetProtein => ((_targetCals * 0.3) / 4).round();
  int get _targetCarbs => ((_targetCals * 0.4) / 4).round();
  int get _targetFat => ((_targetCals * 0.3) / 9).round();

  // Helper Staggered Entrance Animation
  Widget _buildAnimatedSection(Widget child, double startInterval) {
    final double endInterval = (startInterval + 0.35).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildHomeSkeleton();
    }

    final unreadNotifCount = _notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1EAB57),
          onRefresh: () async {
            await _fetchUserDataAndLogs();
            await _fetchScheduledMeals();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BRAND TOP APP BAR (Gizify Logo + Flag + Action Icons)
                _buildAnimatedSection(_buildTopBrandHeader(), 0.0),
                const SizedBox(height: 12),

                // 2. SEARCH BAR & NOTIFICATION BELL
                _buildAnimatedSection(_buildSearchBar(unreadNotifCount), 0.08),
                const SizedBox(height: 16),

                // 3. HERO DASHBOARD BANNER (Greeting, Goals, Calorie Target, Scan CTA, Tabs)
                _buildAnimatedSection(_buildHeroBanner(), 0.16),
                const SizedBox(height: 16),

                // 4. CALORIE TREND CHART (Tren Konsumsi Kalori)
                _buildAnimatedSection(_buildCalorieTrendChartCard(), 0.24),
                const SizedBox(height: 16),

                // 5. 4 PILAR METRIK MAKRO (Sisa Kalori, Protein, Karbo, Lemak)
                _buildAnimatedSection(_buildMacroCardsGrid(), 0.32),
                const SizedBox(height: 16),

                // 6. KONDISI TUBUH & BUTTON DETAIL NUTRISI
                _buildAnimatedSection(_buildBodyConditionCard(), 0.40),
                const SizedBox(height: 16),

                // 7. AI RINGKASAN HARIAN WIDGET
                _buildAnimatedSection(_buildAiSummaryWidget(), 0.48),
                const SizedBox(height: 16),

                // 8. KALENDER INTERAKTIF
                _buildAnimatedSection(_buildInteractiveCalendarCard(), 0.56),
                const SizedBox(height: 16),

                // 9. JADWAL MAKAN HARI INI (Timeline)
                _buildAnimatedSection(_buildMealScheduleCard(), 0.64),
                const SizedBox(height: 16),

                // 10. RIWAYAT SCAN GIZIFY VISION TERAKHIR
                _buildAnimatedSection(_buildRecentScanHistoryCard(), 0.72),
                const SizedBox(height: 16),

                // 11. REKOMENDASI INSTAN WIDGET (Gizibot)
                _buildAnimatedSection(_buildGiziBotRecommendationCard(), 0.80),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. BRAND TOP APP BAR
  // ==========================================
  Widget _buildTopBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Gizify Logo & Typography
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EAB57), Color(0xFF127236)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1EAB57).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'Gizify',
                    style: TextStyle(color: Color(0xFF1EAB57)),
                  ),
                  TextSpan(
                    text: '®',
                    style: TextStyle(
                      color: Color(0xFF1EAB57),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Right Action Badges: Flag, Community, Tips, Profile Initial
        Row(
          children: [
            // Country Flag Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Text("🇮🇩", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    "ID",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Lightbulb Tip Icon
            GestureDetector(
              onTap: () {
                _showHealthTipDialog();
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF1EAB57),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Profile Avatar / Initial Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1EAB57), width: 1.5),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1A453A),
                  backgroundImage: _userData['photoURL'] != null && _userData['photoURL'].toString().isNotEmpty
                      ? NetworkImage(_userData['photoURL'])
                      : null,
                  child: (_userData['photoURL'] == null || _userData['photoURL'].toString().isEmpty)
                      ? Text(
                          _getInitials(_userData['name'] ?? ''),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. SEARCH BAR & NOTIFICATION BELL
  // ==========================================
  Widget _buildSearchBar(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _isSearching = val.trim().isNotEmpty;
                    });
                  },
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    hintText: "Cari riwayat scan Gizify Vision...",
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_isSearching)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _isSearching = false;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              const SizedBox(width: 6),

              // Notification Bell with Badge
              GestureDetector(
                onTap: () {
                  _showNotificationsBottomSheet();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Live Search Results Dropdown
          if (_isSearching) ...[
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            _buildLiveSearchResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveSearchResults() {
    final filtered = _scanHistory.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || type.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "Pencarian riwayat tidak ditemukan",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF1EAB57)),
                  const SizedBox(width: 8),
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                "${item['calories']} kcal",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1EAB57),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // 3. HERO DASHBOARD BANNER
  // ==========================================
  Widget _buildHeroBanner() {
    final firstName = (_userData['name'] ?? 'User').toString().split(' ').first;
    final int target = _targetCals;
    final int consumed = _todayCalories;
    final int percent = target > 0 ? ((consumed / target) * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0FDF4),
            Color(0xFFF4FBF7),
            Color(0xFFE8F8EE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1EAB57).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Sparkle Badge with Ambient Pulse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final scale = 1.0 + 0.04 * _pulseController.value;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1EAB57), Color(0xFF127236)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1EAB57).withOpacity(0.25 + 0.15 * _pulseController.value),
                            blurRadius: 8 + 6 * _pulseController.value,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "${_getGreeting()}, $firstName",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        _scanHistory.isEmpty ? "Selamat datang di Gizify" : "Ringkasan Hari Ini",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pills: Target Tubuh, Kalori Terpakai
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Target Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF1EAB57)),
                    const SizedBox(width: 6),
                    Text(
                      _userData['bodyGoal'] ?? 'Target Sehat',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),

              // Calorie Progress Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: consumed.toDouble()),
                              builder: (context, val, _) => Text(
                                "${val.round()}",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 11, fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: " / $target kcal Terpakai",
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (consumed > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${percent.clamp(0, 100)}%",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Scan Button CTA with Breathing Glow Pulse
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  );
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1EAB57),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1EAB57).withOpacity(0.25 + 0.2 * _pulseController.value),
                            blurRadius: 6 + 6 * _pulseController.value,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        "Scan Makanan",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Switcher: Harian, Mingguan, Bulanan
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                _buildTabButton("Harian"),
                _buildTabButton("Mingguan"),
                _buildTabButton("Bulanan"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    final isSelected = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. CALORIE TREND CHART (Tren Konsumsi Kalori)
  // ==========================================
  Widget _buildCalorieTrendChartCard() {
    final currentDayIdx = DateTime.now().weekday == 7 ? 6 : DateTime.now().weekday - 1;
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final bool hasData = _weeklyData.any((val) => val > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TREN KONSUMSI KALORI",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$_activeTab vs Target Harian",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EAB57),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "AKTUAL",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "BATAS",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Painted Chart Area
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                // Custom Paint for Chart
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CalorieChartPainter(
                      weeklyData: _weeklyData,
                      targetCals: _targetCals,
                      currentDayIndex: currentDayIdx,
                      hasData: hasData,
                    ),
                  ),
                ),

                // Empty State Overlay if no calories recorded this week
                if (!hasData)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.insights_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 32,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Belum ada data kalori minggu ini.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Day Labels below chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (idx) {
              final isToday = idx == currentDayIdx;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: isToday ? 8 : 4, vertical: 3),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFDCFCE7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  days[idx],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                    color: isToday ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. 4 PILAR METRIK MAKRO (2x2 Grid)
  // ==========================================
  Widget _buildMacroCardsGrid() {
    final int target = _targetCals;
    final int sisa = (target - _todayCalories).clamp(0, 99999);
    final double calProgress = target > 0 ? (_todayCalories / target).clamp(0.0, 1.0) : 0.0;
    final double proProgress = _targetProtein > 0 ? (_todayProtein / _targetProtein).clamp(0.0, 1.0) : 0.0;
    final double carProgress = _targetCarbs > 0 ? (_todayCarbs / _targetCarbs).clamp(0.0, 1.0) : 0.0;
    final double fatProgress = _targetFat > 0 ? (_todayFat / _targetFat).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Sisa Kalori",
                value: "$sisa",
                unit: "kcal",
                icon: Icons.monitor_heart_rounded,
                iconColor: const Color(0xFF1EAB57),
                iconBg: const Color(0xFFECFDF5),
                progress: calProgress,
                progressColor: _todayCalories > target ? const Color(0xFFEF4444) : const Color(0xFF1EAB57),
                caption: "$_todayCalories / $target Kkal Terpakai",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Protein Harian",
                value: "$_todayProtein",
                unit: "g",
                icon: Icons.fitness_center_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBg: const Color(0xFFEFF6FF),
                progress: proProgress,
                progressColor: const Color(0xFF3B82F6),
                caption: "Target: ${_targetProtein}g",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Karbo Harian",
                value: "$_todayCarbs",
                unit: "g",
                icon: Icons.bakery_dining_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                progress: carProgress,
                progressColor: const Color(0xFFF59E0B),
                caption: "Target: ${_targetCarbs}g",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Lemak Harian",
                value: "$_todayFat",
                unit: "g",
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFF43F5E),
                iconBg: const Color(0xFFFFE4E6),
                progress: fatProgress,
                progressColor: const Color(0xFFF43F5E),
                caption: "Target: ${_targetFat}g",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required double progress,
    required Color progressColor,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Poppins'),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
                    builder: (context, val, _) => Text(
                      "${val.round()}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: " $unit",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: progress),
              builder: (context, animProgress, _) => LinearProgressIndicator(
                value: animProgress,
                minHeight: 5,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. KONDISI TUBUH & BUTTON DETAIL NUTRISI
  // ==========================================
  Widget _buildBodyConditionCard() {
    final bmi = _userData['bmiStatus'] ?? 'Normal';
    Color bmiColor = const Color(0xFF1EAB57);
    if (bmi.contains('Kurus')) bmiColor = const Color(0xFFF59E0B);
    if (bmi.contains('Gemuk') || bmi.contains('Obesitas')) bmiColor = const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 4 Grid status boxes
          Row(
            children: [
              Expanded(
                child: _buildBodyMetricBox(
                  label: "TARGET TUBUH",
                  value: _userData['bodyGoal'] ?? '-',
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBodyMetricBox(
                  label: "BMI STATUS",
                  value: bmi,
                  color: bmiColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBodyMetricBox(
                  label: "BERAT IDEAL",
                  value: "${_userData['idealWeight'] ?? '-'} Kg",
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBodyMetricBox(
                  label: "ALERGI",
                  value: _userData['dislikedFoods'] ?? 'Tidak Ada',
                  color: _userData['dislikedFoods'] == 'Tidak Ada'
                      ? const Color(0xFF64748B)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Button: DETAIL NUTRISI ->
          GestureDetector(
            onTap: () {
              _showDetailNutrisiModal();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A453A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A453A).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "DETAIL NUTRISI",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF4ADE80),
                      size: 16,
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

  Widget _buildBodyMetricBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. AI RINGKASAN HARIAN WIDGET
  // ==========================================
  Widget _buildAiSummaryWidget() {
    final int consumed = _todayCalories;
    final int target = _targetCals;

    String title;
    String desc;

    if (consumed == 0) {
      title = "Mulai Harimu!";
      desc = "Belum ada kalori yang masuk. Jangan lupa sarapan agar punya energi beraktivitas hari ini.";
    } else if (consumed >= target) {
      title = "Hebat!";
      desc = "Kamu sudah mencapai target kalori harianmu ($target Kkal). Jaga pola makan dan hidrasi yang cukup!";
    } else {
      final sisa = target - consumed;
      title = "Ayo Semangat!";
      desc = "Kamu sudah mengonsumsi $consumed Kkal hari ini. Masih ada sisa $sisa Kkal lagi untuk mencapai target.";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1EAB57), Color(0xFF127236)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1EAB57).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "AI Ringkasan Harian",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFA7F3D0),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD1FAE5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.95),
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

  // ==========================================
  // 8. KALENDER INTERAKTIF
  // ==========================================
  Widget _buildInteractiveCalendarCard() {
    final months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    final currentMonthName = months[_calDate.month - 1];
    final currentYear = _calDate.year;

    final daysInMonth = DateTime(currentYear, _calDate.month + 1, 0).day;
    final firstWeekday = DateTime(currentYear, _calDate.month, 1).weekday; // 1 (Mon) - 7 (Sun)
    final emptyLeadingDays = firstWeekday - 1; // 0 for Mon

    final now = DateTime.now();
    final isThisMonth = now.year == currentYear && now.month == _calDate.month;
    final currentDay = isThisMonth ? now.day : -1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Month Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Kalender",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _calDate = DateTime(_calDate.year, _calDate.month - 1, 1);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                  Text(
                    "$currentMonthName $currentYear",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _calDate = DateTime(_calDate.year, _calDate.month + 1, 1);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Day Headers: S S R K J S M
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _DayHeader(label: "S"),
              _DayHeader(label: "S"),
              _DayHeader(label: "R"),
              _DayHeader(label: "K"),
              _DayHeader(label: "J"),
              _DayHeader(label: "S"),
              _DayHeader(label: "M"),
            ],
          ),
          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emptyLeadingDays + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < emptyLeadingDays) {
                return const SizedBox.shrink();
              }
              final dayNum = index - emptyLeadingDays + 1;
              final isToday = dayNum == currentDay;
              final hasPlan = _planDays.contains(dayNum);
              final hasLog = _loggedDays.contains(dayNum);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF1EAB57) : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1EAB57).withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "$dayNum",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isToday ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasPlan)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasLog)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Rencana Menu",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Riwayat Scan",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 9. JADWAL MAKAN HARI INI (Timeline)
  // ==========================================
  Widget _buildMealScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Jadwal Makan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                  );
                },
                child: const Text(
                  "ATUR",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1EAB57),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_todayScheduledMeals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Belum ada jadwal makan hari ini.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Buat rencana menu untuk mencapai target kalori.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        "BUAT RENCANA MENU",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _todayScheduledMeals.map((meal) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF1EAB57), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    meal['time'] ?? '12:00',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  meal['type'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              meal['title'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${meal['calories']} Kkal",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1EAB57),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 10. RIWAYAT SCAN GIZIFY VISION TERAKHIR
  // ==========================================
  Widget _buildRecentScanHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Riwayat Scan Terakhir",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showDetailNutrisiModal();
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1EAB57),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_scanHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.fastfood_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Belum Ada Data",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Kamu belum scan atau mencatat makanan apapun hari ini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        "MULAI GIZIFY VISION",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _scanHistory.map((item) {
                DateTime scannedAt = item['scannedAt'] as DateTime? ?? DateTime.now();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Color(0xFF1EAB57), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${item['type']} • ${item['mealType']}",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${item['calories']} Kkal",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(scannedAt),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 11. REKOMENDASI INSTAN WIDGET (Gizibot)
  // ==========================================
  Widget _buildGiziBotRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + 0.08 * _pulseController.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Bingung Mau Makan Apa?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Gizibot siap berikan rekomendasi menu instan sesuai target kalori harianmu.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GizifyChatbotScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF6366F1)),
                        SizedBox(width: 6),
                        Text(
                          "Tanya Gizibot",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Atur Rencana",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL / BOTTOM SHEET: DETAIL NUTRISI HARIAN
  // ==========================================
  void _showDetailNutrisiModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF1EAB57), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Detail Nutrisi Harian",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "Pantauan Mikro & Makro Gizi (Hari Ini)",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. GIZI MAKRO
                      const Text(
                        "GIZI MAKRO (ENERGI UTAMA)",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalMacroItem(
                              label: "Kalori",
                              value: "$_todayCalories",
                              target: "$_targetCals",
                              color: const Color(0xFF1EAB57),
                              bg: const Color(0xFFF0FDF4),
                              progress: _targetCals > 0 ? (_todayCalories / _targetCals).clamp(0.0, 1.0) : 0.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModalMacroItem(
                              label: "Protein",
                              value: "${_todayProtein}g",
                              target: "${_targetProtein}g",
                              color: const Color(0xFF3B82F6),
                              bg: const Color(0xFFEFF6FF),
                              progress: _targetProtein > 0 ? (_todayProtein / _targetProtein).clamp(0.0, 1.0) : 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalMacroItem(
                              label: "Karbo",
                              value: "${_todayCarbs}g",
                              target: "${_targetCarbs}g",
                              color: const Color(0xFFF59E0B),
                              bg: const Color(0xFFFEF3C7),
                              progress: _targetCarbs > 0 ? (_todayCarbs / _targetCarbs).clamp(0.0, 1.0) : 0.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModalMacroItem(
                              label: "Lemak",
                              value: "${_todayFat}g",
                              target: "${_targetFat}g",
                              color: const Color(0xFFF43F5E),
                              bg: const Color(0xFFFFE4E6),
                              progress: _targetFat > 0 ? (_todayFat / _targetFat).clamp(0.0, 1.0) : 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. GIZI MIKRO
                      const Text(
                        "GIZI MIKRO (VITAMIN & MINERAL)",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildMicroBar(
                              label: "Vitamin C",
                              sub: "(Imunitas & Kolagen)",
                              current: "${_vitC}mg",
                              target: "90mg",
                              color: const Color(0xFFF97316),
                              progress: (_vitC / 90).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 12),
                            _buildMicroBar(
                              label: "Serat Pangan",
                              sub: "(Pencernaan & Gula Darah)",
                              current: "${_fiber}g",
                              target: "30g",
                              color: const Color(0xFF1EAB57),
                              progress: (_fiber / 30).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 12),
                            _buildMicroBar(
                              label: "Kalsium",
                              sub: "(Kekuatan Tulang & Gigi)",
                              current: "${_calcium}mg",
                              target: "1000mg",
                              color: const Color(0xFF06B6D4),
                              progress: (_calcium / 1000).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 12),
                            _buildMicroBar(
                              label: "Zat Besi",
                              sub: "(Hemoglobin & Stamina)",
                              current: "${_iron}mg",
                              target: "18mg",
                              color: const Color(0xFF8B5CF6),
                              progress: (_iron / 18).clamp(0.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. SARAN NUTRISI AI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC7D2FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Saran Nutrisi AI",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF312E81),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _todayCalories == 0
                                        ? "Belum ada makanan yang dicatat hari ini. Mulai dengan sarapan bergizi untuk mengisi kebutuhan energimu!"
                                        : _fiber < 15
                                            ? "Asupan serat Anda hari ini masih di bawah anjuran. Tambahkan porsi sayuran hijau, kacang-kacangan, atau buah seperti apel/pepaya."
                                            : _vitC < 45
                                                ? "Kebutuhan Vitamin C Anda belum optimal hari ini. Nikmati buah jeruk, jambu biji, atau tomat untuk daya tahan tubuh."
                                                : "Asupan makro dan mikro Anda hari ini terpantau sangat seimbang. Pertahankan konsistensi pola makan sehat Anda!",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4338CA),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. MAKANAN TERPANTAU HARI INI
                      const Text(
                        "MAKANAN TERPANTAU HARI INI",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_todayFoodList.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Belum ada makanan yang dicatat hari ini.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                                  );
                                },
                                child: const Text(
                                  "Mulai Scan Makanan Sekarang →",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1EAB57),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _todayFoodList.map((food) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (food['mealType'] ?? 'Makan').toString().toUpperCase(),
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              food['time'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          food['name'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "P: ${food['protein']}g • K: ${food['carbs']}g • L: ${food['fat']}g",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      "${food['calories']} kcal",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_todayFoodList.length} makanan tercatat hari ini",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "TUTUP",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalMacroItem({
    required String label,
    required String value,
    required String target,
    required Color color,
    required Color bg,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Poppins'),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                TextSpan(
                  text: " / $target",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroBar({
    required String label,
    required String sub,
    required String current,
    required String target,
    required Color color,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Poppins'),
                children: [
                  TextSpan(
                    text: current,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  TextSpan(
                    text: " / $target",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODAL: NOTIFIKASI
  // ==========================================
  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Notifikasi",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_notifications.any((n) => n['isRead'] == false))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${_notifications.where((n) => n['isRead'] == false).length}",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF43F5E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_notifications.any((n) => n['isRead'] == false))
                              GestureDetector(
                                onTap: () async {
                                  await _markAllNotifsAsRead();
                                  setSheetState(() {});
                                },
                                child: const Text(
                                  "Baca Semua",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1EAB57),
                                  ),
                                ),
                              ),
                            if (_notifications.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  await _deleteAllNotifs();
                                  setSheetState(() {});
                                },
                                child: const Text(
                                  "Hapus Semua",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF43F5E),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notifications List
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.notifications_off_rounded, size: 40, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 8),
                                Text(
                                  "Belum ada notifikasi.",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, idx) {
                              final notif = _notifications[idx];
                              final isRead = notif['isRead'] == true;
                              return GestureDetector(
                                onTap: () {
                                  if (!isRead) {
                                    _markNotifAsRead(notif['id']);
                                    setSheetState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isRead ? const Color(0xFFF1F5F9) : const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isRead)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4, right: 8),
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF43F5E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notif['title'] ?? '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              notif['message'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('d MMM, HH:mm').format(notif['createdAt'] as DateTime),
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 9,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await _deleteNotif(notif['id']);
                                          setSheetState(() {});
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.close_rounded, size: 16, color: Color(0xFFCBD5E1)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  // Health Tip Dialog
  void _showHealthTipDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text(
              "Tips Gizify Hari Ini",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Minum minimal 2 liter air putih dan pastikan piring makanmu terdiri dari 50% sayur & buah, 25% karbohidrat kompleks, serta 25% protein bermutu tinggi.",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF1EAB57))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SKELETON LOADING WIDGETS
  // ==========================================
  Widget _buildHomeSkeleton() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ShimmerLoading(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER SKELETON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSkeletonBlock(width: 110, height: 32, borderRadius: 10),
                    Row(
                      children: [
                        _buildSkeletonBlock(width: 44, height: 32, borderRadius: 16),
                        const SizedBox(width: 8),
                        _buildSkeletonBlock(width: 34, height: 34, borderRadius: 17),
                        const SizedBox(width: 8),
                        _buildSkeletonBlock(width: 34, height: 34, borderRadius: 17),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. SEARCH BAR SKELETON
                _buildSkeletonBlock(height: 48, borderRadius: 18),
                const SizedBox(height: 16),

                // 3. HERO BANNER SKELETON
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildSkeletonBlock(width: 44, height: 44, borderRadius: 14),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBlock(width: 150, height: 18, borderRadius: 6),
                              const SizedBox(height: 6),
                              _buildSkeletonBlock(width: 110, height: 14, borderRadius: 12),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSkeletonBlock(width: 125, height: 30, borderRadius: 10),
                          _buildSkeletonBlock(width: 155, height: 30, borderRadius: 10),
                          _buildSkeletonBlock(width: 115, height: 30, borderRadius: 10),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSkeletonBlock(height: 36, borderRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. CHART SKELETON
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBlock(width: 160, height: 16, borderRadius: 6),
                              const SizedBox(height: 6),
                              _buildSkeletonBlock(width: 120, height: 11, borderRadius: 4),
                            ],
                          ),
                          _buildSkeletonBlock(width: 40, height: 14, borderRadius: 6),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSkeletonBlock(height: 100, borderRadius: 12),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          7,
                          (_) => _buildSkeletonBlock(width: 28, height: 16, borderRadius: 6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. 4 PILAR MAKRO SKELETON (Grid 2x2)
                Row(
                  children: [
                    Expanded(child: _buildMetricCardSkeleton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricCardSkeleton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. BOTTOM PROMO / GIZIBOT SKELETON
                _buildSkeletonBlock(height: 90, borderRadius: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBlock(width: 60, height: 11, borderRadius: 4),
              _buildSkeletonBlock(width: 26, height: 26, borderRadius: 13),
            ],
          ),
          const SizedBox(height: 10),
          _buildSkeletonBlock(width: 75, height: 22, borderRadius: 6),
          const SizedBox(height: 10),
          _buildSkeletonBlock(height: 5, borderRadius: 5),
          const SizedBox(height: 8),
          _buildSkeletonBlock(width: 90, height: 10, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildSkeletonBlock({
    double? width,
    required double height,
    double borderRadius = 8,
    Color color = const Color(0xFFE2E8F0),
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ==========================================
// CALORIE CHART CUSTOM PAINTER
// ==========================================
class _CalorieChartPainter extends CustomPainter {
  final List<int> weeklyData;
  final int targetCals;
  final int currentDayIndex;
  final bool hasData;

  _CalorieChartPainter({
    required this.weeklyData,
    required this.targetCals,
    required this.currentDayIndex,
    required this.hasData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double maxVal = 3000.0;
    const double leftMargin = 32.0;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - 20;

    final axisTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y Axis labels helper
    void drawYLabel(String text, double y, Color color, {bool isBold = false}) {
      axisTextPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          color: color,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(0, y - axisTextPainter.height / 2));
    }

    // Grid Lines Painter
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    // Draw reference levels: 3000, 2000, 1000, 0
    final y3000 = 10.0;
    final y1000 = chartHeight * (1 - (1000 / maxVal));
    final y0 = chartHeight;

    canvas.drawLine(Offset(leftMargin, y3000), Offset(size.width, y3000), gridPaint);
    drawYLabel("3000", y3000, const Color(0xFF94A3B8));

    canvas.drawLine(Offset(leftMargin, y1000), Offset(size.width, y1000), gridPaint);
    drawYLabel("1000", y1000, const Color(0xFF94A3B8));

    canvas.drawLine(Offset(leftMargin, y0), Offset(size.width, y0), gridPaint);
    drawYLabel("0", y0, const Color(0xFF94A3B8));

    // Dynamic Target Calorie Line (Red Dashed)
    final double targetY = (chartHeight * (1 - (targetCals / maxVal))).clamp(10.0, chartHeight);
    final redDashPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.7)
      ..strokeWidth = 1.5;

    // Dashed line
    double startX = leftMargin;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, targetY), Offset(startX + 6, targetY), redDashPaint);
      startX += 10;
    }
    drawYLabel("$targetCals", targetY, const Color(0xFFEF4444), isBold: true);

    // If no weekly data, don't draw line
    if (!hasData) return;

    // Calculate (x, y) coordinates for the 7 days
    final points = <Offset>[];
    for (int i = 0; i < 7; i++) {
      final double x = leftMargin + (i / 6.0) * chartWidth;
      final int cals = weeklyData[i];
      final double y = (chartHeight * (1 - (cals / maxVal))).clamp(10.0, chartHeight);
      points.add(Offset(x, y));
    }

    // Draw Smooth or Polyline
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    // Area Fill under the line
    final fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1EAB57).withOpacity(0.2),
          const Color(0xFF1EAB57).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Green Stroke
    final linePaint = Paint()
      ..color = const Color(0xFF1EAB57)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw Dots
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final val = weeklyData[i];
      final isToday = i == currentDayIndex;

      if (val > 0 || isToday) {
        // Outer dot
        canvas.drawCircle(
          pt,
          5.0,
          Paint()
            ..color = val > 0 ? const Color(0xFF1EAB57) : Colors.white
            ..style = PaintingStyle.fill,
        );
        // Border
        canvas.drawCircle(
          pt,
          5.0,
          Paint()
            ..color = val > 0 ? Colors.white : const Color(0xFF1EAB57)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieChartPainter oldDelegate) {
    return oldDelegate.weeklyData != weeklyData ||
        oldDelegate.targetCals != targetCals ||
        oldDelegate.currentDayIndex != currentDayIndex ||
        oldDelegate.hasData != hasData;
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SHIMMER LOADING EFFECT (SHADOW/LIGHT WAVE)
// ==========================================
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.2, -0.3),
              end: const Alignment(1.2, 0.3),
              stops: const [0.1, 0.3, 0.5],
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
