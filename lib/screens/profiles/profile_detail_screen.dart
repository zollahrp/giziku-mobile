import 'package:flutter/material.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data untuk preview tampilan
    final profile = _DummyProfile();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header background
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 24,
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF2ECC71),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Profile photo
                  Positioned(
                    bottom: -36, // Use Positioned for negative margin
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.yellow,
                        backgroundImage: const AssetImage('assets/profile/profile.png'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
            // Name & edit icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 18, color: Color(0xFF2ECC71)),
              ],
            ),
            const SizedBox(height: 20),
            // Personal Information title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Personal Information",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Info list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _ProfileInfoRow(label: "Full name", value: profile.name),
                  _ProfileInfoRow(label: "Email", value: profile.email),
                  _ProfileInfoRow(label: "Phone Number", value: profile.phoneNumber),
                  _ProfileInfoRow(label: "Gender", value: profile.gender),
                  _ProfileInfoRow(label: "Date of birth", value: profile.dateOfBirth),
                  _ProfileInfoRow(label: "Height", value: "${profile.height} Cm"),
                  _ProfileInfoRow(label: "Weight", value: "${profile.weight} Kg"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFFBDBDBD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy data class for preview
class _DummyProfile {
  final String name = "Jenny Perdana";
  final String email = "Jenny123@gmail.com";
  final String phoneNumber = "081385997264";
  final String gender = "Male";
  final String dateOfBirth = "21 Januari 2025";
  final int height = 178;
  final int weight = 66;
}