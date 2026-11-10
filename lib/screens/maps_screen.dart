import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Model Store / Toko Bahan Sehat
class StoreItem {
  final dynamic id;
  final String name;
  final String distance;
  final double distanceNum;
  final String type; // Pasar, Supermarket, Toko Sayur, Organik
  final String status; // Buka, Tutup, Tutup 20:00
  final String price; // Murah, Menengah, Premium
  final List<String> items;
  final double lat;
  final double lng;

  StoreItem({
    required this.id,
    required this.name,
    required this.distance,
    required this.distanceNum,
    required this.type,
    required this.status,
    required this.price,
    required this.items,
    required this.lat,
    required this.lng,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      name: json['name']?.toString() ?? 'Toko Bahan Sehat',
      distance: json['distance']?.toString() ?? '1.0 km',
      distanceNum: (json['distanceNum'] as num?)?.toDouble() ?? 1.0,
      type: json['type']?.toString() ?? 'Pasar',
      status: json['status']?.toString() ?? 'Buka',
      price: json['price']?.toString() ?? 'Murah',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['tomat', 'bayam', 'sayur segar'],
      lat: (json['lat'] as num?)?.toDouble() ?? -6.1754,
      lng: (json['lng'] as num?)?.toDouble() ?? 106.8272,
    );
  }
}

// Fallback Store Data (Sesuai Web fallbackStores)
final List<StoreItem> fallbackStores = [
  StoreItem(
    id: 1,
    name: "Pasar Senen Tradisional",
    distance: "0.8 km",
    distanceNum: 0.8,
    type: "Pasar",
    status: "Buka",
    price: "Murah",
    items: ["tomat", "bayam", "daging ayam", "cabai"],
    lat: -6.1764,
    lng: 106.8423,
  ),
  StoreItem(
    id: 2,
    name: "Superindo Fresh",
    distance: "1.2 km",
    distanceNum: 1.2,
    type: "Supermarket",
    status: "Buka",
    price: "Menengah",
    items: ["susu", "daging sapi", "tomat", "apel"],
    lat: -6.1814,
    lng: 106.8282,
  ),
  StoreItem(
    id: 3,
    name: "Tukang Sayur (Mang Ujang)",
    distance: "0.1 km",
    distanceNum: 0.1,
    type: "Pasar",
    status: "Buka",
    price: "Murah",
    items: ["bayam", "kangkung", "tomat", "tahu", "tempe"],
    lat: -6.1734,
    lng: 106.8292,
  ),
  StoreItem(
    id: 4,
    name: "Organic Veggie Hub",
    distance: "2.5 km",
    distanceNum: 2.5,
    type: "Organik",
    status: "Tutup 20:00",
    price: "Premium",
    items: ["bayam organik", "tomat ceri", "susu almond"],
    lat: -6.1944,
    lng: 106.8229,
  ),
];

class MapsScreen extends StatefulWidget {
  final String? initialQuery;

  const MapsScreen({super.key, this.initialQuery});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _activeFilter = "Semua";

  // Location State
  double _userLat = -6.1754;
  double _userLng = 106.8272;
  bool _isTracking = false;
  StoreItem? _activeRoute;
  List<StoreItem> _stores = List.from(fallbackStores);

  // Animation for Radar Pulse
  late AnimationController _pulseController;

  final List<String> _filterCategories = [
    "Semua",
    "Pasar",
    "Supermarket",
    "Organik",
  ];

  // Profanity Guardrail (Sesuai Web)
  final List<String> _badWords = [
    "kontol", "memek", "anjing", "babi", "bangsat", "tolol",
    "ngentot", "tai", "jancok", "peler", "jembut", "goblok", "bego"
  ];

  bool get _isBannedWord {
    final lower = _searchQuery.toLowerCase();
    return _badWords.any((w) => lower.contains(w));
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchQuery = widget.initialQuery!;
      _searchController.text = widget.initialQuery!;
    }

    _requestLocation(showNotification: false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Haversine Formula untuk hitung jarak
  double _getDistanceFromLatLonInKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  // Request GPS Location & Fetch OSM Places
  Future<void> _requestLocation({bool showNotification = true}) async {
    setState(() {
      _isTracking = true;
      _activeRoute = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isTracking = false);
          if (showNotification) {
            _showToast("Layanan lokasi (GPS) belum diaktifkan.", isError: true);
          }
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isTracking = false);
            if (showNotification) {
              _showToast("Izin lokasi ditolak.", isError: true);
            }
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isTracking = false);
          if (showNotification) {
            _showToast("Izin lokasi ditolak permanen di pengaturan perangkat.", isError: true);
          }
        }
        return;
      }

      // Ambil posisi presisi tinggi
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _userLat = position.latitude;
      _userLng = position.longitude;

      // Cari pasar & toko sekitar via Overpass API
      await _fetchOverpassStores(_userLat, _userLng);

      if (mounted) {
        setState(() => _isTracking = false);
        if (showNotification) {
          _showToast("Lokasi Terkunci! Menampilkan toko bahan segar di sekitarmu.");
        }
      }
    } catch (e) {
      debugPrint("GPS / Overpass Error: $e");
      if (mounted) {
        setState(() {
          _isTracking = false;
          _stores = List.from(fallbackStores);
        });
        if (showNotification) {
          _showToast("Menggunakan titik cadangan Jakarta Pusat.");
        }
      }
    }
  }

  // Ambil Data Pasar Asli dari OpenStreetMap Overpass API
  Future<void> _fetchOverpassStores(double lat, double lng) async {
    try {
      final query = '''
[out:json][timeout:15];
(
  nwr["amenity"="marketplace"](around:5000, $lat, $lng);
  nwr["shop"="supermarket"](around:5000, $lat, $lng);
  nwr["shop"="greengrocer"](around:5000, $lat, $lng);
  nwr["shop"="convenience"](around:2000, $lat, $lng);
);
out center;
''';

      final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'text/plain',
          'User-Agent': 'GizifyMobileApp/2.0',
        },
        body: query,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final elements = data['elements'] as List<dynamic>? ?? [];

        final List<StoreItem> loaded = [];

        for (var el in elements) {
          final tags = el['tags'] as Map<String, dynamic>?;
          if (tags == null || tags['name'] == null) continue;

          final double? objLat = (el['lat'] as num?)?.toDouble() ??
              (el['center']?['lat'] as num?)?.toDouble();
          final double? objLon = (el['lon'] as num?)?.toDouble() ??
              (el['center']?['lon'] as num?)?.toDouble();

          if (objLat == null || objLon == null) continue;

          final double dist = _getDistanceFromLatLonInKm(lat, lng, objLat, objLon);

          String type = "Toko/Minimarket";
          if (tags['amenity'] == "marketplace") type = "Pasar";
          if (tags['shop'] == "supermarket") type = "Supermarket";
          if (tags['shop'] == "greengrocer") type = "Toko Sayur";

          final Map<String, List<String>> dummyItemsMap = {
            "Pasar": ["tomat", "bayam", "daging ayam", "bawang merah", "cabai segar", "ikan"],
            "Supermarket": ["susu sapi", "daging sapi", "tomat", "buah naga", "chia seed", "ayam filet"],
            "Toko Sayur": ["bayam", "kangkung", "tomat", "tahu", "tempe"],
            "Toko/Minimarket": ["telur", "susu", "roti", "beras", "minyak goreng", "tomat"],
          };

          loaded.add(
            StoreItem(
              id: el['id'] ?? Random().nextInt(999999),
              name: tags['name'].toString(),
              distanceNum: dist,
              distance: "${dist.toStringAsFixed(1)} km",
              type: type,
              status: "Buka",
              price: type == "Supermarket" ? "Menengah" : "Murah",
              items: dummyItemsMap[type] ?? ["bahan segar", "tomat"],
              lat: objLat,
              lng: objLon,
            ),
          );
        }

        if (loaded.isNotEmpty) {
          loaded.sort((a, b) => a.distanceNum.compareTo(b.distanceNum));
          setState(() {
            _stores = loaded.take(25).toList();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error Overpass API: $e");
    }

    // Fallback jika API gagal
    setState(() {
      _stores = List.from(fallbackStores);
    });
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF1EAB57),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Buka Google Maps Eksternal untuk Navigasi Nyata
  Future<void> _openExternalGoogleMaps(StoreItem store) async {
    final origin = "$_userLat,$_userLng";
    final destination = "${store.lat},${store.lng}";
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showToast("Tidak dapat membuka Google Maps", isError: true);
    }
  }

  // Buka E-commerce Tokopedia / Shopee
  Future<void> _openEcommerce(String platform, String query) async {
    final encoded = Uri.encodeComponent(query.trim());
    final urlStr = platform == "tokopedia"
        ? "https://www.tokopedia.com/search?q=$encoded"
        : "https://shopee.co.id/search?keyword=$encoded";

    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showToast("Tidak dapat membuka browser", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final searchLower = _searchQuery.toLowerCase().trim();

    final commonBasics = [
      "air", "es", "garam", "gula", "lada", "merica", "minyak", "kecap",
      "mentega", "butter", "kaldu", "tepung", "bawang", "beras", "buah",
      "sayur", "sayuran", "daging", "ayam", "ikan", "sapi", "kambing",
      "telur", "susu", "roti", "kacang", "tahu", "tempe", "cabe", "cabai", "bumbu", "mie"
    ];

    final isCommonBasic = commonBasics.any((b) => searchLower.contains(b));

    final processedStores = _stores.map((store) {
      final List<String> newItems = List.from(store.items);
      if (searchLower.isNotEmpty && isCommonBasic) {
        if (!newItems.any((i) => i.toLowerCase().contains(searchLower))) {
          newItems.insert(0, _searchQuery);
        }
      }
      return StoreItem(
        id: store.id,
        name: store.name,
        distance: store.distance,
        distanceNum: store.distanceNum,
        type: store.type,
        status: store.status,
        price: store.price,
        items: newItems,
        lat: store.lat,
        lng: store.lng,
      );
    }).toList();

    final filteredStores = processedStores.where((store) {
      final matchFilter = _activeFilter == "Semua" ||
          store.type == _activeFilter ||
          (_activeFilter == "Organik" && store.type == "Organik");

      final matchSearch = searchLower.isEmpty ||
          store.name.toLowerCase().contains(searchLower) ||
          store.items.any((item) => item.toLowerCase().contains(searchLower));

      return matchFilter && matchSearch;
    }).toList();

    // Fallback store alternatif
    final baseFallbackStore = processedStores.firstWhere(
      (s) => s.type == "Supermarket" || s.type == "Organik" || s.type == "Pasar",
      orElse: () => processedStores.first,
    );

    StoreItem? realFallbackStore;
    if (searchLower.isNotEmpty) {
      realFallbackStore = StoreItem(
        id: baseFallbackStore.id,
        name: baseFallbackStore.name,
        distance: baseFallbackStore.distance,
        distanceNum: baseFallbackStore.distanceNum,
        type: baseFallbackStore.type,
        status: baseFallbackStore.status,
        price: baseFallbackStore.price,
        items: [_searchQuery, ...baseFallbackStore.items.where((i) => i.toLowerCase() != searchLower)].take(4).toList(),
        lat: baseFallbackStore.lat,
        lng: baseFallbackStore.lng,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER: Peta Belanja & Subtitle
            _buildTopHeader(),

            // EXPANDED BODY (Map on Top + List on Bottom)
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1EAB57),
                onRefresh: () => _requestLocation(showNotification: true),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // GIS MAP VIEW CONTAINER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: _buildGisMapCard(),
                      ),
                    ),

                    // SEARCH BAR & CATEGORY FILTER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 10),
                            _buildCategoryFilterBar(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // STORE LIST CONTENT / EMPTY / BANNED
                    if (_isBannedWord)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: _buildBannedWordCard(),
                        ),
                      )
                    else if (filteredStores.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildEmptyStateWithAlternatives(realFallbackStore),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final store = filteredStores[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildStoreCard(store),
                              );
                            },
                            childCount: filteredStores.length,
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
    );
  }

  // ==========================================
  // 1. TOP HEADER
  // ==========================================
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Peta Belanja",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF1EAB57)),
                  SizedBox(width: 4),
                  Text(
                    "SISTEM INFORMASI GEOGRAFIS",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Recenter GPS Action Button
          GestureDetector(
            onTap: () => _requestLocation(showNotification: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isTracking ? Icons.sync_rounded : Icons.my_location_rounded,
                    size: 15,
                    color: const Color(0xFF1EAB57),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isTracking ? "Melacak..." : "GPS Saya",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
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

  // ==========================================
  // 2. ACTIVE GIS MAP VIEW CARD
  // ==========================================
  Widget _buildGisMapCard() {
    final bool hasRoute = _activeRoute != null;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1EAB57).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Simulated Map Background Grid & Vector Graphic
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _GisMapCanvasPainter(
                pulseValue: _pulseController.value,
                hasRoute: hasRoute,
                activeStore: _activeRoute,
                stores: _stores.take(6).toList(),
              ),
            ),
          ),

          // Top Badges & Control Buttons
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                // GPS Active / Route Active Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasRoute ? const Color(0xFF1A453A) : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasRoute ? const Color(0xFF1A453A) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: hasRoute ? Colors.white : const Color(0xFF1EAB57),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isTracking
                            ? "MELACAK..."
                            : hasRoute
                                ? "RUTE AKTIF"
                                : "GPS AKTIF",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: hasRoute ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Cancel route button (if route active)
                if (hasRoute)
                  GestureDetector(
                    onTap: () => setState(() => _activeRoute = null),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Route / Info Floating Bar
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasRoute
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasRoute ? Icons.directions_rounded : Icons.radar_rounded,
                      color: const Color(0xFF1EAB57),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasRoute
                              ? "Menuju: ${_activeRoute!.name}"
                              : "Cakupan Radar: Radius 5 KM",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          hasRoute
                              ? "Jarak ${_activeRoute!.distance} • Tekan 'Buka App' untuk navigasi belokan"
                              : "Pilih tombol 'Rute' pada daftar toko untuk petunjuk arah",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasRoute) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openExternalGoogleMaps(_activeRoute!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EAB57),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Buka Maps",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. SEARCH BAR
  // ==========================================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isBannedWord
              ? const Color(0xFFFDA4AF)
              : const Color(0xFFE2E8F0),
          width: _isBannedWord ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 19,
            color: _isBannedWord ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isBannedWord ? const Color(0xFFBE123C) : const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: "Cari Tomat, Ayam, Sayur, Buah...",
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. CATEGORY FILTER BAR
  // ==========================================
  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _filterCategories[index];
          final isSelected = _activeFilter == cat;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1EAB57) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1EAB57).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 5. STORE CARD
  // ==========================================
  Widget _buildStoreCard(StoreItem store) {
    final bool isSelected = _activeRoute?.id == store.id;

    IconData storeIcon;
    Color storeIconBg;
    Color storeIconColor;

    switch (store.type) {
      case "Supermarket":
        storeIcon = Icons.store_mall_directory_rounded;
        storeIconBg = const Color(0xFFEFF6FF);
        storeIconColor = const Color(0xFF3B82F6);
        break;
      case "Toko Sayur":
        storeIcon = Icons.eco_rounded;
        storeIconBg = const Color(0xFFECFDF5);
        storeIconColor = const Color(0xFF1EAB57);
        break;
      case "Organik":
        storeIcon = Icons.spa_rounded;
        storeIconBg = const Color(0xFFFEF3C7);
        storeIconColor = const Color(0xFFD97706);
        break;
      default:
        storeIcon = Icons.storefront_rounded;
        storeIconBg = const Color(0xFFF1F5F9);
        storeIconColor = const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeRoute = isSelected ? null : store;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1EAB57).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Name + Distance Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: storeIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(storeIcon, size: 18, color: storeIconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            store.type,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("•", style: TextStyle(color: Color(0xFFCBD5E1))),
                          const SizedBox(width: 6),
                          Text(
                            store.status,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: store.status == "Buka"
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1EAB57) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    store.distance,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Chips (dengan highlight jika cocok)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...store.items.take(4).map((item) {
                  final isMatched = _searchQuery.isNotEmpty &&
                      item.toLowerCase().contains(_searchQuery.toLowerCase());
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMatched
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isMatched
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }),
                if (store.items.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "+${store.items.length - 4}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Actions: Price Level & Route / Google Maps Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF1EAB57)),
                    const SizedBox(width: 4),
                    Text(
                      "Harga: ${store.price}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Tombol Rute GIS
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeRoute = isSelected ? null : store;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: 13,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSelected ? "Tutup Rute" : "Rute",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Buka di Google Maps
                    GestureDetector(
                      onTap: () => _openExternalGoogleMaps(store),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EAB57),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1EAB57).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Buka App",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. BANNED WORD CARD (PROFANITY GUARDRAIL)
  // ==========================================
  Widget _buildBannedWordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            "Astaghfirullah, Istighfar!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF9F1239),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Gizify ini aplikasi pemenuhan gizi yang sehat dan halal.\nTolong cari Tomat, Bayam, atau Ayam aja ya Komandan! 🙏",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFBE123C),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. EMPTY STATE WITH E-COMMERCE CARDS
  // ==========================================
  Widget _buildEmptyStateWithAlternatives(StoreItem? fallback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Not Found Info Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pencarian Spesifik",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Bahan '$_searchQuery' sulit dikonfirmasi ketersediaannya pada toko sekitar.",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // E-Commerce Banner (Tokopedia & Shopee)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1EAB57), Color(0xFF1A453A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1EAB57).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Beli Online Lebih Mudah?",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Untuk bahan spesifik atau langka, kami sangat menyarankan Anda berbelanja melalui E-Commerce resmi.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openEcommerce("tokopedia", _searchQuery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "TOKOPEDIA",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1EAB57),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openEcommerce("shopee", _searchQuery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "SHOPEE",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEE4D2D),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Toko Alternatif Header & Card
        if (fallback != null) ...[
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "ATAU CEK TOKO ALTERNATIF",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 12),
          _buildStoreCard(fallback),
        ],
      ],
    );
  }
}

// ==========================================
// GIS MAP CANVAS PAINTER (VECTOR GRAPHIC)
// ==========================================
class _GisMapCanvasPainter extends CustomPainter {
  final double pulseValue;
  final bool hasRoute;
  final StoreItem? activeStore;
  final List<StoreItem> stores;

  _GisMapCanvasPainter({
    required this.pulseValue,
    required this.hasRoute,
    required this.activeStore,
    required this.stores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background roads and water blocks
    final roadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final greenParkPaint = Paint()
      ..color = const Color(0xFFDCFCE7).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Parks / green areas
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, 80, 50), const Radius.circular(8)),
      greenParkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 110, size.height - 70, 90, 50), const Radius.circular(8)),
      greenParkPaint,
    );

    // Roads Grid
    final Path roads = Path();
    roads.moveTo(0, size.height * 0.45);
    roads.lineTo(size.width, size.height * 0.45);
    roads.moveTo(size.width * 0.35, 0);
    roads.lineTo(size.width * 0.35, size.height);
    roads.moveTo(size.width * 0.75, 0);
    roads.lineTo(size.width * 0.75, size.height);
    canvas.drawPath(roads, roadPaint);

    final Path secondaryRoads = Path();
    secondaryRoads.moveTo(0, size.height * 0.75);
    secondaryRoads.lineTo(size.width, size.height * 0.75);
    secondaryRoads.moveTo(0, size.height * 0.2);
    secondaryRoads.lineTo(size.width, size.height * 0.2);
    canvas.drawPath(secondaryRoads, thinRoadPaint);

    // 2. User Location Pin (Center-Left)
    final userCenter = Offset(size.width * 0.35, size.height * 0.45);

    // Radar Pulse Circle
    final pulsePaint = Paint()
      ..color = const Color(0xFF1EAB57).withValues(alpha: 0.3 * (1.0 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 15 + 20 * pulseValue, pulsePaint);

    // User Dot
    final userPinPaint = Paint()
      ..color = const Color(0xFF1EAB57)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 7, userPinPaint);

    final userWhiteBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userCenter, 7, userWhiteBorder);

    // 3. Store Pins
    final List<Offset> storeOffsets = [
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.65, size.height * 0.68),
      Offset(size.width * 0.20, size.height * 0.75),
      Offset(size.width * 0.85, size.height * 0.45),
    ];

    for (int i = 0; i < storeOffsets.length; i++) {
      final isTarget = hasRoute && activeStore != null;
      final targetOffset = storeOffsets[0];
      final pos = isTarget && i == 0 ? targetOffset : storeOffsets[i];

      final pinPaint = Paint()
        ..color = (isTarget && i == 0) ? const Color(0xFFE11D48) : const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, 5.5, pinPaint);
      canvas.drawCircle(pos, 5.5, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // 4. Active Navigation Route Line
    if (hasRoute) {
      final destOffset = storeOffsets[0];
      final routePaint = Paint()
        ..color = const Color(0xFF1EAB57)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final Path routePath = Path();
      routePath.moveTo(userCenter.dx, userCenter.dy);
      routePath.lineTo(destOffset.dx, userCenter.dy);
      routePath.lineTo(destOffset.dx, destOffset.dy);

      canvas.drawPath(routePath, routePaint);

      // Destination Target Pin Highlight
      canvas.drawCircle(destOffset, 10, Paint()..color = const Color(0xFFE11D48).withValues(alpha: 0.2));
      canvas.drawCircle(destOffset, 6, Paint()..color = const Color(0xFFE11D48));
      canvas.drawCircle(destOffset, 6, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GisMapCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.hasRoute != hasRoute ||
        oldDelegate.activeStore != activeStore;
  }
}
