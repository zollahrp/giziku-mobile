import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gizify/data/dummy_recipes.dart';
import 'package:gizify/screens/recipe/recipe_detail_screen.dart';
import 'package:gizify/screens/gizi_chatbot_screen.dart';

// ==========================================
// INDEKS BIAYA PASAR BELANJA REGIONAL (BPS & TRADITIONAL MARKET BENCHMARK)
// ==========================================
const Map<String, Map<String, dynamic>> cityPriceIndex = {
  'jakarta': {'multiplier': 1.0, 'marketName': 'Pasar Jaya & Swalayan Jakarta'},
  'bogor': {'multiplier': 0.93, 'marketName': 'Pasar Anyar / Pasar Bogor'},
  'depok': {'multiplier': 0.96, 'marketName': 'Pasar Kemiri Muka Depok'},
  'tangerang': {'multiplier': 0.97, 'marketName': 'Pasar Lama Tangerang'},
  'bekasi': {'multiplier': 0.96, 'marketName': 'Pasar Kranji Bekasi'},
  'bandung': {'multiplier': 0.92, 'marketName': 'Pasar Baru / Ciroyom Bandung'},
  'yogyakarta': {'multiplier': 0.85, 'marketName': 'Pasar Beringharjo Yogyakarta'},
  'jogja': {'multiplier': 0.85, 'marketName': 'Pasar Beringharjo Yogyakarta'},
  'solo': {'multiplier': 0.84, 'marketName': 'Pasar Gede Solo'},
  'semarang': {'multiplier': 0.88, 'marketName': 'Pasar Johar Semarang'},
  'surabaya': {'multiplier': 0.93, 'marketName': 'Pasar Wonokromo Surabaya'},
  'malang': {'multiplier': 0.90, 'marketName': 'Pasar Besar Malang'},
  'bali': {'multiplier': 1.06, 'marketName': 'Pasar Badung Denpasar'},
  'denpasar': {'multiplier': 1.06, 'marketName': 'Pasar Badung Denpasar'},
  'medan': {'multiplier': 1.08, 'marketName': 'Pasar Petisah Medan'},
  'padang': {'multiplier': 1.04, 'marketName': 'Pasar Raya Padang'},
  'makassar': {'multiplier': 1.10, 'marketName': 'Pasar Terong Makassar'},
  'balikpapan': {'multiplier': 1.18, 'marketName': 'Pasar Klandasan Balikpapan'},
  'kuala lumpur': {'multiplier': 1.0, 'marketName': 'Pasar TTDI / Chow Kit KL'},
  'kelantan': {'multiplier': 0.88, 'marketName': 'Pasar Siti Khadijah Kelantan'},
  'penang': {'multiplier': 0.95, 'marketName': 'Pasar Chowrasta Penang'},
};

const List<String> popularCities = [
  'Jakarta',
  'Bogor',
  'Bandung',
  'Yogyakarta',
  'Surabaya',
  'Bali',
  'Medan',
  'Kuala Lumpur',
];

const List<Map<String, String>> categoryItems = [
  {'id': 'Semua', 'icon': '🍽️', 'label': 'Semua'},
  {'id': 'Sarapan', 'icon': '🍳', 'label': 'Sarapan'},
  {'id': 'Makan Siang', 'icon': '🍱', 'label': 'Makan Siang'},
  {'id': 'Makan Malam', 'icon': '🥗', 'label': 'Makan Malam'},
  {'id': 'Cemilan', 'icon': '🥪', 'label': 'Cemilan'},
  {'id': 'Minuman', 'icon': '🍹', 'label': 'Minuman'},
  {'id': 'Vegan', 'icon': '🥬', 'label': 'Vegan'},
  {'id': 'Keto', 'icon': '🥩', 'label': 'Keto'},
  {'id': 'Low Carbs', 'icon': '🥑', 'label': 'Low Carbs'},
];

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _activeTab = "Eksplor"; // "Eksplor" or "Resep Kamu"
  String _activeCategory = "Semua";
  String _searchQuery = "";
  String _activeSort = "popular"; // "popular", "rating", "fastest", "lowestCalorie"
  String _selectedCurrency = "IDR"; // "IDR", "MYR", "USD"
  String _userLocation = "Jakarta";
  int _activeDayIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocationAndBookmarks() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Ambil lokasi user dari Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final loc = userDoc.data()?['domicile'] ?? userDoc.data()?['location'];
        if (loc != null && loc.toString().trim().isNotEmpty) {
          final cityName = loc.toString().split(',')[0].trim();
          if (mounted) {
            setState(() {
              _userLocation = cityName;
            });
          }
        }
      }

      // 2. Ambil bookmarks dari collection 'bookmarks'
      final bookmarksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .get();

      final ids = bookmarksSnap.docs.map((doc) => doc.id).toSet();

      // Tambahkan juga dari 'saved_recipes' lama jika ada
      final savedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_recipes')
          .get();
      for (final doc in savedSnap.docs) {
        ids.add(doc.id);
      }

      if (mounted) {
        setState(() {
          _bookmarkedIds.addAll(ids);
        });
      }
    } catch (e) {
      debugPrint("Error loading user location/bookmarks: $e");
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> recipe) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masuk untuk menyimpan resep"), backgroundColor: Colors.orange),
      );
      return;
    }

    final String recipeId = recipe['id']?.toString() ?? recipe['title'].toString();
    final bool isSaved = _bookmarkedIds.contains(recipeId);

    setState(() {
      if (isSaved) {
        _bookmarkedIds.remove(recipeId);
      } else {
        _bookmarkedIds.add(recipeId);
      }
    });

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(recipeId);

    try {
      if (isSaved) {
        await docRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Resep dihapus dari favorit"),
              backgroundColor: Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        final dataToSave = Map<String, dynamic>.from(recipe);
        dataToSave['savedAt'] = FieldValue.serverTimestamp();
        await docRef.set(dataToSave);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Resep berhasil disimpan ke favorit!"),
              backgroundColor: Color(0xFF1EAB57),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
    }
  }

  double _getCityMultiplier(String city) {
    final norm = city.toLowerCase().trim();
    for (final entry in cityPriceIndex.entries) {
      if (norm.contains(entry.key)) {
        return (entry.value['multiplier'] as num).toDouble();
      }
    }
    return 1.0;
  }

  String _getDynamicPrice(Map<String, dynamic> recipe) {
    int baseIdr = (recipe['priceIdr'] as num?)?.toInt() ?? 0;
    if (baseIdr == 0 && recipe['totalBudget'] != null) {
      final raw = recipe['totalBudget'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      baseIdr = int.tryParse(raw) ?? 30000;
    }
    if (baseIdr == 0) baseIdr = 30000;

    final multiplier = _getCityMultiplier(_userLocation);
    final adjustedIdr = ((baseIdr * multiplier) / 500).round() * 500;

    if (_selectedCurrency == "MYR") {
      final myr = (adjustedIdr / 3500).toStringAsFixed(2);
      return "RM $myr";
    } else if (_selectedCurrency == "USD") {
      final usd = (adjustedIdr / 16000).toStringAsFixed(2);
      return "\$ $usd";
    } else {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(adjustedIdr);
    }
  }

  List<Map<String, dynamic>> _getFilteredRecipes() {
    List<Map<String, dynamic>> list = dummyRecipesData.where((recipe) {
      final matchCategory = _activeCategory == "Semua" || recipe['category'] == _activeCategory;
      final q = _searchQuery.toLowerCase().trim();
      final title = (recipe['title'] ?? '').toString().toLowerCase();
      final author = (recipe['author'] ?? '').toString().toLowerCase();
      final matchSearch = q.isEmpty || title.contains(q) || author.contains(q);
      return matchCategory && matchSearch;
    }).toList();

    if (_activeSort == "rating") {
      list.sort((a, b) => ((b['rating'] as num?)?.toDouble() ?? 0).compareTo((a['rating'] as num?)?.toDouble() ?? 0));
    } else if (_activeSort == "lowestCalorie") {
      list.sort((a, b) => ((a['calories'] as num?)?.toInt() ?? 0).compareTo((b['calories'] as num?)?.toInt() ?? 0));
    } else if (_activeSort == "fastest") {
      int getMins(dynamic str) {
        final raw = str?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '999';
        return int.tryParse(raw) ?? 999;
      }
      list.sort((a, b) => getMins(a['prepTime']).compareTo(getMins(b['prepTime'])));
    } else {
      // Default: popular (by reviews)
      list.sort((a, b) => ((b['reviews'] as num?)?.toInt() ?? 0).compareTo((a['reviews'] as num?)?.toInt() ?? 0));
    }

    return list;
  }

  void _openSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                "URUTKAN RESEP",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption(ctx, "popular", "Paling Populer & Banyak Diulas", Icons.local_fire_department_rounded),
              _buildSortOption(ctx, "rating", "Rating Tertinggi (Bintang 5)", Icons.star_rounded),
              _buildSortOption(ctx, "fastest", "Waktu Masak Tercepat", Icons.timer_rounded),
              _buildSortOption(ctx, "lowestCalorie", "Kalori Terendah (Diet Friendly)", Icons.eco_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String sortKey, String label, IconData icon) {
    final bool isSelected = _activeSort == sortKey;
    return InkWell(
      onTap: () {
        setState(() => _activeSort = sortKey);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF1EAB57), size: 18),
          ],
        ),
      ),
    );
  }

  void _openCitySelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "PILIH KOTA PASAR ACUAN",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Indeks Harga BPS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1EAB57),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: popularCities.length,
                  itemBuilder: (context, idx) {
                    final city = popularCities[idx];
                    final factor = cityPriceIndex[city.toLowerCase()] ?? {'multiplier': 1.0, 'marketName': 'Pasar Lokal $city'};
                    final mult = (factor['multiplier'] as num).toDouble();
                    final pct = ((mult - 1.0) * 100).round();
                    final pctLabel = pct == 0 ? "Standar" : pct > 0 ? "+$pct%" : "$pct%";
                    final isSelected = _userLocation.toLowerCase().contains(city.toLowerCase());

                    return InkWell(
                      onTap: () {
                        setState(() => _userLocation = city);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  factor['marketName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: pct < 0
                                    ? const Color(0xFFD1FAE5)
                                    : pct > 0
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pctLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: pct < 0
                                      ? const Color(0xFF047857)
                                      : pct > 0
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF64748B),
                                  fontFamily: 'Poppins',
                                ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 1. TOP HEADER & GIZIFY BRANDING
            // ==========================================
            _buildTopHeader(),

            // ==========================================
            // 2. MAIN TABS SWITCHER (EKSPLOR vs RESEP KAMU)
            // ==========================================
            _buildMainTabsSwitcher(),

            // ==========================================
            // 3. TAB CONTENT
            // ==========================================
            Expanded(
              child: _activeTab == "Eksplor"
                  ? _buildEksplorTabContent()
                  : _buildResepKamuTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8EE), Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1EAB57).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF1EAB57), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Koleksi Resep Sehat",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Nutrisi seimbang, kalori akurat, ramah kantong",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
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
  // TAB SWITCHER
  // =========================================================================
  Widget _buildMainTabsSwitcher() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = "Eksplor"),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == "Eksplor" ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _activeTab == "Eksplor"
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
                      "EKSPLOR RESEP",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: _activeTab == "Eksplor" ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = "Resep Kamu"),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == "Resep Kamu" ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _activeTab == "Resep Kamu"
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "RESEP KAMU",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: _activeTab == "Resep Kamu" ? const Color(0xFF1EAB57) : const Color(0xFF64748B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (_bookmarkedIds.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1EAB57),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${_bookmarkedIds.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: EKSPLOR
  // =========================================================================
  Widget _buildEksplorTabContent() {
    final filtered = _getFilteredRecipes();
    final frequentlyViewed = List<Map<String, dynamic>>.from(dummyRecipesData)
      ..sort((a, b) => ((b['reviews'] as num?)?.toInt() ?? 0).compareTo((a['reviews'] as num?)?.toInt() ?? 0));
    final top4 = frequentlyViewed.take(4).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar & Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      hintText: "Cari resep sehat, bahan, menu...",
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openSortBottomSheet,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _activeSort != "popular" ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _activeSort != "popular" ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: _activeSort != "popular" ? Colors.white : const Color(0xFF475569),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Urutkan",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _activeSort != "popular" ? Colors.white : const Color(0xFF475569),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Control Bar: Mata Uang & Pasar Acuan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Currency Selector Chips
              Row(
                children: [
                  _buildCurrencyChip("IDR", "🇮🇩 Rp"),
                  const SizedBox(width: 4),
                  _buildCurrencyChip("MYR", "🇲🇾 RM"),
                  const SizedBox(width: 4),
                  _buildCurrencyChip("USD", "🌐 \$"),
                ],
              ),

              // City Selector Button
              GestureDetector(
                onTap: _openCitySelectorModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _userLocation,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Category Horizontal Pills
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categoryItems.length,
              itemBuilder: (context, idx) {
                final cat = categoryItems[idx];
                final isSelected = _activeCategory == cat['id'];

                return Padding(
                  padding: EdgeInsets.only(right: idx == categoryItems.length - 1 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeCategory = cat['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1EAB57) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1EAB57).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 4. Recipes List or Empty State
          if (filtered.isEmpty)
            _buildEmptyState()
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty ? "Hasil Pencarian" : "Rekomendasi Menu Sehat",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  "${filtered.length} Resep",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1EAB57),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                return _buildRecipeCardItem(filtered[idx]);
              },
            ),
          ],

          // 5. Frequently Viewed Section (if category == "Semua" and search is empty)
          if (_activeCategory == "Semua" && _searchQuery.isEmpty && top4.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 8),
                Text(
                  "Sering Dilihat Pengguna",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 215,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: top4.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: idx == top4.length - 1 ? 0 : 12),
                    child: _buildHorizontalFeaturedCard(top4[idx]),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String curr, String label) {
    final isSelected = _selectedCurrency == curr;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = curr),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1EAB57) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // RECIPE CARD ITEM
  // =========================================================================
  Widget _buildRecipeCardItem(Map<String, dynamic> recipe) {
    final String recipeId = recipe['id']?.toString() ?? recipe['title'].toString();
    final bool isSaved = _bookmarkedIds.contains(recipeId);
    final String priceStr = _getDynamicPrice(recipe);
    final String imageUrl = recipe['image']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipeMap: recipe,
                selectedCurrency: _selectedCurrency,
                userLocation: _userLocation,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Category & Calories Chips + Bookmark Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                          )
                        : Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Top Left: Category Chip
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF1EAB57)),
                        const SizedBox(width: 4),
                        Text(
                          recipe['category']?.toString() ?? 'Resep',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top Right: Bookmark Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleBookmark(recipe),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSaved ? const Color(0xFF1EAB57) : Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? Colors.white : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Bottom Left: Calories Chip
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EAB57),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          "${recipe['calories']} kkal",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags: Origin, Budget, Location
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (recipe['origin'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public_rounded, size: 11, color: Color(0xFFB45309)),
                              const SizedBox(width: 4),
                              Text(
                                "Asal: ${recipe['origin']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, size: 11, color: Color(0xFF047857)),
                            const SizedBox(width: 4),
                            Text(
                              priceStr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF065F46),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_rounded, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              _userLocation,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Author & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F8EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_rounded, size: 14, color: Color(0xFF1EAB57)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DIBUAT OLEH",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                recipe['author']?.toString() ?? 'Gizify',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF334155),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              "${recipe['rating']}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF92400E),
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
      ),
    );
  }

  // =========================================================================
  // HORIZONTAL FEATURED CARD (FREQUENTLY VIEWED)
  // =========================================================================
  Widget _buildHorizontalFeaturedCard(Map<String, dynamic> recipe) {
    final String recipeId = recipe['id']?.toString() ?? recipe['title'].toString();
    final bool isSaved = _bookmarkedIds.contains(recipeId);
    final String imageUrl = recipe['image']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipeMap: recipe,
                selectedCurrency: _selectedCurrency,
                userLocation: _userLocation,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                          )
                        : Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleBookmark(recipe),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSaved ? const Color(0xFF1EAB57) : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? Colors.white : const Color(0xFF64748B),
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${recipe['calories']} kkal",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1EAB57),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          Text(
                            "${recipe['rating']}",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // EMPTY SEARCH STATE
  // =========================================================================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            "Resep Tidak Ditemukan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Coba ubah kata kunci pencarian atau ganti kategori resep.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = "";
                _activeCategory = "Semua";
                _activeSort = "popular";
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text("Reset Filter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: RESEP KAMU (MEAL PLAN & BOOKMARKS)
  // =========================================================================
  Widget _buildResepKamuTabContent() {
    final uid = currentUser?.uid;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Jurnal Makanan Aktif Card (Hero)
          _buildMealPlanHeroCard(),

          const SizedBox(height: 20),

          // 2. Weekly Calendar Days Selector
          _buildWeeklyCalendarDays(),

          const SizedBox(height: 20),

          // 3. Meals Timeline of Active Day
          _buildMealScheduleTimeline(),

          const SizedBox(height: 28),

          // 4. Saved Bookmarks Header
          Row(
            children: const [
              Icon(Icons.bookmark_rounded, color: Color(0xFF1EAB57), size: 20),
              SizedBox(width: 8),
              Text(
                "Resep Favorit Tersimpan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Koleksi menu sehat yang sudah Anda simpan untuk dimasak nanti",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),

          // 5. Bookmarks List from Firestore
          if (uid == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text("Silakan masuk untuk melihat resep tersimpan"),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('bookmarks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: Color(0xFF1EAB57)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.bookmark_border_rounded, size: 40, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          "Belum Ada Resep Tersimpan",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Buka tab 'Eksplor Resep' dan tap ikon bookmark pada menu yang Anda sukai.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    data['id'] = docs[idx].id;
                    return _buildRecipeCardItem(data);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // MEAL PLAN HERO CARD
  // =========================================================================
  Widget _buildMealPlanHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge: Jurnal Makanan Aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1EAB57),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "JURNAL MAKANAN AKTIF",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF047857),
                    letterSpacing: 0.6,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "Meal Plan Nutrisi & Budget",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontFamily: 'Poppins',
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Menu makan otomatis yang disesuaikan dengan target kalori dan preferensi belanja Anda.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          // Budget Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ESTIMASI BUDGET HARIAN",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedCurrency == "MYR"
                          ? "RM 24.50"
                          : (_selectedCurrency == "USD" ? "\$ 4.80" : "Rp 75.000"),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF1EAB57)),
                      SizedBox(width: 4),
                      Text(
                        "7 Hari",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Button: Buat Meal Plan AI
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GizifyChatbotScreen()),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              label: const Text(
                "Buat Meal Plan AI Baru",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WEEKLY CALENDAR DAYS
  // =========================================================================
  Widget _buildWeeklyCalendarDays() {
    final now = DateTime.now();
    final dayNames = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7,
        itemBuilder: (context, idx) {
          final date = now.add(Duration(days: idx));
          final isSelected = _activeDayIndex == idx;
          final dayName = dayNames[(date.weekday - 1) % 7];

          return GestureDetector(
            onTap: () => setState(() => _activeDayIndex = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              margin: EdgeInsets.only(right: idx == 6 ? 0 : 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1EAB57) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1EAB57).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFFD1FAE5) : const Color(0xFF94A3B8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // MEAL SCHEDULE TIMELINE
  // =========================================================================
  Widget _buildMealScheduleTimeline() {
    final List<Map<String, dynamic>> dailyMeals = [
      {
        'time': '07:30',
        'type': 'Sarapan',
        'recipe': dummyRecipesData[0], // Smoothie bowl
        'status': 'Selesai',
      },
      {
        'time': '12:30',
        'type': 'Makan Siang',
        'recipe': dummyRecipesData[1], // Ayam Bakar Taliwang
        'status': 'Waktunya Masak',
      },
      {
        'time': '19:00',
        'type': 'Makan Malam',
        'recipe': dummyRecipesData[2], // Pepes Ikan Nila
        'status': 'Mendatang',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Jadwal Makan Hari Ini",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              "Total: 1.450 kkal",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1EAB57),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...dailyMeals.map((item) {
          final recipe = item['recipe'] as Map<String, dynamic>;
          final status = item['status'] as String;
          final bool isCookingTime = status == 'Waktunya Masak';
          final bool isDone = status == 'Selesai';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCookingTime ? const Color(0xFFECFDF5) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCookingTime ? const Color(0xFF86EFAC) : const Color(0xFFF1F5F9),
                width: isCookingTime ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(
                      recipeMap: recipe,
                      selectedCurrency: _selectedCurrency,
                      userLocation: _userLocation,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  // Time & Type
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['time'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isCookingTime ? const Color(0xFF047857) : const Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          item['type'],
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFE2E8F0),
                      child: Image.network(
                        recipe['image']?.toString() ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.asset('assets/foods/default.jpg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Macro
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "${recipe['calories']} kkal",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1EAB57),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCookingTime
                                    ? const Color(0xFF1EAB57)
                                    : (isDone ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: isCookingTime
                                      ? Colors.white
                                      : (isDone ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
