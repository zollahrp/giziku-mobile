import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _captchaChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final remember = prefs.getBool('remember_me') ?? true;
      if (savedEmail != null && remember) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (_) {}
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _captchaChecked &&
      !_isLoading &&
      !_isGoogleLoading;

  Future<void> _handleLogin() async {
    if (!_canSubmit) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.signInWithEmailPassword(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await _saveCredentials();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      _showErrorDialog(
        title: 'Gagal Masuk',
        message: authService.errorMessage ?? 'Email atau password salah.',
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      _showErrorDialog(
        title: 'Gagal Masuk dengan Google',
        message: authService.errorMessage ?? 'Proses login Google dibatalkan.',
      );
    }
  }

  void _showForgotPasswordSheet() {
    final resetController =
        TextEditingController(text: _emailController.text.trim());
    bool isResetting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lupa Sandi?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email terdaftar kamu. Kami akan mengirimkan instruksi untuk reset kata sandi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'nama@email.com',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isResetting
                        ? null
                        : () async {
                            final targetEmail = resetController.text.trim();
                            if (targetEmail.isEmpty) return;

                            setSheetState(() => isResetting = true);
                            final authService = context.read<AuthService>();
                            final success =
                                await authService.sendPasswordReset(targetEmail);
                            setSheetState(() => isResetting = false);

                            if (!context.mounted) return;
                            Navigator.pop(ctx);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Link reset sandi telah dikirim ke email kamu!',
                                  ),
                                  backgroundColor: Color(0xFF1A453A),
                                ),
                              );
                            } else {
                              _showErrorDialog(
                                title: 'Gagal Mengirim',
                                message: authService.errorMessage ??
                                    'Email tidak ditemukan.',
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A453A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: isResetting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'KIRIM LINK RESET',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF1A453A),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Ambient Glow Decorators
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2ECC71).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A453A).withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Bar: Back & Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (Navigator.canPop(context))
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Color(0xFF374151),
                                  size: 20,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 40),

                          // Brand Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A453A)
                                      .withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/gizifyicon.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Gizify',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A453A),
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 40),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ================= HERO ILLUSTRATION =================
                      Container(
                        height: 210,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient Radial Mint Aura
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF2ECC71).withOpacity(0.22),
                                    const Color(0xFF1A453A).withOpacity(0.04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.65, 1.0],
                                ),
                              ),
                            ),

                            // Main Illustration
                            Image.asset(
                              'assets/login_hero.png',
                              height: 200,
                              fit: BoxFit.contain,
                            ),

                            // Floating Luxury Chip 1 (Top Right)
                            Positioned(
                              top: 6,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD1FAE5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1A453A)
                                          .withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🥗', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 5),
                                    Text(
                                      'AI Nutrition',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A453A),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Floating Luxury Chip 2 (Bottom Left)
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD1FAE5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1A453A)
                                          .withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✨', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Pola Sehat',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF059669),
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

                      const SizedBox(height: 12),

                      // Title & Subtitle
                      const Text(
                        'Mulai Sehatmu',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Masuk untuk melihat asupan kalori hari ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form: EMAIL ADDRESS
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                            letterSpacing: 1.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'nama@email.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Form: PASSWORD
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                            letterSpacing: 1.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Ingat Saya & Lupa Sandi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _rememberMe
                                        ? const Color(0xFF1A453A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: _rememberMe
                                          ? const Color(0xFF1A453A)
                                          : const Color(0xFFD1D5DB),
                                      width: 1.8,
                                    ),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 15,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                child: const Text(
                                  'Ingat Saya',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordSheet,
                            child: const Text(
                              'Lupa sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // reCAPTCHA Box
                      _buildRecaptchaBox(),

                      const SizedBox(height: 20),

                      // Submit Button
                      _buildSubmitButton(
                        title: 'MASUK SEKARANG',
                        loadingText: 'Menyiapkan Nutrisimu...',
                        isEnabled: _canSubmit,
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),

                      const SizedBox(height: 22),

                      // Divider "ATAU"
                      _buildOrDivider(),

                      const SizedBox(height: 22),

                      // Google Button
                      _buildGoogleButton(
                        title: 'MASUK DENGAN GOOGLE',
                        isLoading: _isGoogleLoading,
                        onPressed: _handleGoogleLogin,
                      ),

                      const SizedBox(height: 26),

                      // Bottom Link: Belum punya akun? Daftar Gratis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar Gratis',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A453A),
                                fontFamily: 'Poppins',
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Disclaimer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Dengan melanjutkan, Anda menyetujui Kebijakan Privasi dan Syarat Ketentuan kami.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                            fontFamily: 'Poppins',
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRecaptchaBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          InkWell(
            onTap: () {
              setState(() => _captchaChecked = !_captchaChecked);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _captchaChecked
                    ? const Color(0xFF1A453A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _captchaChecked
                      ? const Color(0xFF1A453A)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: _captchaChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {
              setState(() => _captchaChecked = !_captchaChecked);
            },
            child: const Text(
              "I'm not a robot",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF3B82F6),
                size: 26,
              ),
              Text(
                'reCAPTCHA',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({
    required String title,
    required String loadingText,
    required bool isEnabled,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF1A453A), Color(0xFF059669)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isEnabled ? null : const Color(0xFFCBD5E1),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A453A).withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.4,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ATAU',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton({
    required String title,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF1A453A),
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/google_icon.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF374151),
                      fontFamily: 'Poppins',
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
