import 'package:flutter/material.dart';
import 'package:giziku/screens/main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill email dan password untuk demo
    _emailController.text = 'admin@gmail.com';
    _passwordController.text = 'admin123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  void _handleStaticLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan Password tidak boleh kosong');
      return;
    }

    if (!isValidEmail(email)) {
      _showError('Format email tidak valid');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      if (email == 'admin@gmail.com' && password == 'admin123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        _showError('Email atau Password salah');
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/gizikulabel.png',
                    height: 70,
                    color: const Color(0xFF2ECC71),
                  ),
                ),
              ),

              // Ilustrasi
              Expanded(
                flex: 4,
                child: Center(
                  child: Image.asset('assets/signin.png', fit: BoxFit.contain),
                ),
              ),

              const Text(
                'Hi ! Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 20),

              // Email
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'Poppins',
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'Poppins',
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              // Tombol Sign In
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStaticLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Catatan akun demo
              const Center(
                child: Text(
                  'Demo Login: admin@gmail.com / admin123',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
