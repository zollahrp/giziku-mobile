import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizify/widgets/avatar_helper.dart';
import 'edit_profile_screen.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final String name = data['name'] ?? user.displayName ?? "Guest User";
          final String email = data['email'] ?? user.email ?? "No Email";
          final String photo = data['photoURL'] ?? data['photo_url'] ?? user.photoURL ?? "";

          final String birthDate = data['date_of_birth'] ?? data['birthDate'] ?? data['dateOfBirth'] ?? '';
          final String calories = data['daily_calories']?.toString() ?? data['calories']?.toString() ?? data['dailyCalories']?.toString() ?? '';
          final String activity = data['activity_level'] ?? data['activity'] ?? data['activityLevel'] ?? '';
          final String exercise = data['exercise_level'] ?? data['exercise'] ?? data['exerciseLevel'] ?? '';
          final String bodyGoal = data['body_goal'] ?? data['bodyGoal'] ?? '';
          final String bmiStatus = data['bmi_category'] ?? data['bmiStatus'] ?? data['bmiCategory'] ?? '';
          final String idealWeight = data['ideal_weight']?.toString() ?? data['idealWeight']?.toString() ?? '';

          dynamic rawFood = data['food_type'] ?? data['dietTypes'] ?? data['dietType'];
          final String foodType = rawFood is List ? rawFood.join(', ') : (rawFood?.toString() ?? '');

          final String favoriteFoods = data['favorite_foods'] ?? data['favoriteFoods'] ?? '';
          final String dislikedFoods = data['disliked_foods'] ?? data['dislikedFoods'] ?? '';

          dynamic rawAllergies = data['allergies'];
          final String allergiesStr = rawAllergies is List ? (rawAllergies.isEmpty ? 'Tidak ada' : rawAllergies.join(', ')) : (rawAllergies?.toString() ?? 'Tidak ada');

          dynamic rawDisease = data['chronic_disease'] ?? data['chronicDisease'] ?? data['medicalHistory'];
          final String diseaseStr = rawDisease is List ? (rawDisease.isEmpty ? 'Tidak ada' : rawDisease.join(', ')) : (rawDisease?.toString() ?? 'Tidak ada');

          String v(dynamic value, [String suffix = '']) {
            if (value == null || value.toString().trim().isEmpty) {
              return '-';
            }
            return '$value$suffix';
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),

            slivers: [
              // ================= HEADER =================
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                backgroundColor: const Color(0xFF2ECC71),
                elevation: 0,

                leading: Padding(
                  padding: const EdgeInsets.all(8),

                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2ECC71),
                      ),

                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2AD882), Color(0xFF2ECC71)],

                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),

                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          const SizedBox(height: 40),

                          Container(
                            padding: const EdgeInsets.all(4),

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),

                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: getProfileImageProvider(photo),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            name,

                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            email,

                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 22),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),

                            child: Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    title: 'BMI',
                                    value: v(data['bmi']),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: _MiniStat(
                                    title: 'Kalori',
                                    value: "${v(calories)} kcal",
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: _MiniStat(
                                    title: 'Target',
                                    value: bodyGoal == 'Menambah Massa Otot'
                                        ? 'Bulking'
                                        : bodyGoal == 'Menurunkan Berat Badan'
                                            ? 'Cutting'
                                            : bodyGoal == 'Menjaga Berat Badan'
                                                ? 'Maintain'
                                                : v(bodyGoal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ================= CONTENT =================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ================= INFORMASI DASAR =================
                      const _SectionTitle(title: 'Informasi Dasar'),

                      const SizedBox(height: 18),

                      _infoCard(
                        children: [
                          _InfoTile(
                            icon: Icons.person_outline,
                            title: 'Nama Lengkap',
                            value: name,
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.wc,
                            title: 'Jenis Kelamin',
                            value: v(data['gender']),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.cake_outlined,
                            title: 'Tanggal Lahir',
                            value: v(birthDate),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.calendar_today,
                            title: 'Umur',
                            value: v(data['age'], ' Tahun'),
                          ),
                        ],
                      ),

                      // ================= ANALISIS TUBUH =================
                      const SizedBox(height: 28),

                      const _SectionTitle(title: 'Analisis Tubuh'),

                      const SizedBox(height: 18),

                      _infoCard(
                        children: [
                          _InfoTile(
                            icon: Icons.height,
                            title: 'Tinggi Badan',
                            value: v(data['height'], ' cm'),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.monitor_weight_outlined,
                            title: 'Berat Badan',
                            value: v(data['weight'], ' kg'),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.calculate_outlined,
                            title: 'BMI',
                            value: v(data['bmi']),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.favorite,
                            title: 'Status BMI',
                            value: v(bmiStatus),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.fitness_center,
                            title: 'Berat Ideal',
                            value: v(idealWeight, ' kg'),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.local_fire_department,
                            title: 'Kebutuhan Kalori',
                            value: v(calories, ' kcal'),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.directions_run,
                            title: 'Tingkat Aktivitas',
                            value: v(activity),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.sports_gymnastics,
                            title: 'Tingkat Olahraga',
                            value: v(exercise),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.track_changes,
                            title: 'Target Tubuh',
                            value: v(bodyGoal),
                          ),
                        ],
                      ),

                      // ================= PREFERENSI NUTRISI =================
                      const SizedBox(height: 28),

                      const _SectionTitle(title: 'Preferensi Nutrisi'),

                      const SizedBox(height: 18),

                      _infoCard(
                        children: [
                          _InfoTile(
                            icon: Icons.restaurant,
                            title: 'Tipe Makanan',
                            value: v(foodType),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.favorite_outline,
                            title: 'Makanan Favorit',
                            value: v(favoriteFoods),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.thumb_down_alt_outlined,
                            title: 'Makanan Tidak Disukai',
                            value: v(dislikedFoods),
                          ),

                          const _InfoDivider(),

                          _InfoTile(
                            icon: Icons.warning_amber_outlined,
                            title: 'Alergi',
                            value: allergiesStr,
                          ),
                        ],
                      ),

                      // ================= KONDISI KESEHATAN =================
                      const SizedBox(height: 28),

                      const _SectionTitle(title: 'Kondisi Kesehatan'),

                      const SizedBox(height: 18),

                      _infoCard(
                        children: [
                          _InfoTile(
                            icon: Icons.medical_services_outlined,
                            title: 'Riwayat Penyakit',
                            value: diseaseStr,
                          ),
                        ],
                      ),

                      const SizedBox(height: 34),

                      // ================= BUTTON =================
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),

                            elevation: 0,

                            padding: const EdgeInsets.symmetric(vertical: 18),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),

                          child: const Text(
                            'Edit Profil',

                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,

      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            value,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: const Color(0xFFE8FFF1),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: const Color(0xFF2ECC71), size: 22),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,

                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),

      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
