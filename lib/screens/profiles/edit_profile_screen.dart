import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers untuk form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // Dummy data
  final Map<String, dynamic> _profileData = {
    'name': 'Jenny Perdana',
    'phoneNumber': '',
    'birthDate': '',
    'height': '',
    'weight': '',
    'photoUrl': 'assets/profile/profile_picture.png',
  };
  
  @override
  void initState() {
    super.initState();
    // Mengisi controller dengan data dummy
    _nameController.text = _profileData['name'];
    _phoneController.text = _profileData['phoneNumber'];
    _birthDateController.text = _profileData['birthDate'];
    _heightController.text = _profileData['height'];
    _weightController.text = _profileData['weight'];
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2ECC71),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header dengan background hijau dan foto profil
          _buildHeader(),
          
          // Form fields dalam scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  
                  // Full Name Field
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Phone Number Field with country flag
                  _buildPhoneField(),
                  
                  const SizedBox(height: 15),
                  
                  // Date of Birth Field
                  _buildDateField(),
                  
                  const SizedBox(height: 15),
                  
                  // Height Field
                  _buildTextField(
                    controller: _heightController,
                    hintText: 'Height',
                    suffix: 'Cm',
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Weight Field
                  _buildTextField(
                    controller: _weightController,
                    hintText: 'Weight',
                    suffix: 'Kg',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          // Save button at bottom
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2ECC71),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Profile picture with edit icon
          Positioned(
            bottom: -50,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.yellow,
                    backgroundImage: AssetImage(_profileData['photoUrl']),
                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.blue,
                    ),
                  ),
                  
                  // Edit icon on bottom-right of the avatar
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: const Color(0xFF2ECC71),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User name below avatar
          Positioned(
            bottom: 70,
            child: Text(
              'Jenny Perdana',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                suffix,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Flag container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Image.asset(
              'assets/profile/indonesia_flag.png',
              width: 30,
              height: 20,
            ),
          ),
          
          // Divider line
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),
          
          // Phone number input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintText: 'Phone Number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _birthDateController,
                enabled: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  hintText: 'Date of birth',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  void _saveProfile() {
    // Disini akan ada logika untuk update data ke API
    
    // Dummy update untuk data sementara
    setState(() {
      _profileData['name'] = _nameController.text;
      _profileData['phoneNumber'] = _phoneController.text;
      _profileData['birthDate'] = _birthDateController.text;
      _profileData['height'] = _heightController.text;
      _profileData['weight'] = _weightController.text;
    });
    
    // Mock API call with Future.delayed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
      },
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // dismiss dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      
      Navigator.pop(context); // back to profile
    });
  }
}
