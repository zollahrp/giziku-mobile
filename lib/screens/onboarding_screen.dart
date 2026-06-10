import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget? nextScreen;

  const OnboardingScreen({super.key, this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      image: 'assets/hero1.png',
      svgImage: 'assets/hero1.svg',

      title: 'Pahami Nutrisi Tubuhmu',

      description:
          'Pantau kebutuhan kalori, BMI, dan pola makan sehat dengan cara yang lebih mudah dan modern.',

      buttonText: 'Lanjut',
    ),

    OnboardingItem(
      image: 'assets/hero2.png',
      svgImage: 'assets/hero2.svg',

      title: 'AI Meal Planner',

      description:
          'Dapatkan rekomendasi menu makanan pintar sesuai budget, alergi, target tubuh, dan preferensi makanmu.',

      buttonText: 'Lanjut',
    ),

    OnboardingItem(
      image: 'assets/hero3.png',
      svgImage: 'assets/hero3.svg',

      title: 'Hidup Sehat Jadi Mudah',

      description:
          'Bangun kebiasaan sehat setiap hari bersama Giziku dengan pengalaman yang personal dan interaktif.',

      buttonText: 'Mulai',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    print(
      "_goToNextPage called, current page: $_currentPage, total pages: ${_pages.length}",
    );
    if (_currentPage < _pages.length - 1) {
      print("Moving to next page");
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.nextScreen != null) {
      print(
        "On last page, navigating to main app screen: ${widget.nextScreen.runtimeType}",
      );
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('onboarding_done', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen!),
      );
    } else {
      print("ERROR: nextScreen is null in onboarding, cannot navigate");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The actual PageView - NOT wrapped in AbsorbPointer
          PageView.builder(
            controller: _pageController,
            // Only use physics prevention, not AbsorbPointer
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                item: _pages[index],
                onButtonPressed: _goToNextPage,
                currentPage: _currentPage,
                totalPages: _pages.length,
              );
            },
          ),

          // Invisible overlay to block swipes but allow button presses
          Positioned.fill(
            child: GestureDetector(
              // This will consume horizontal swipes only
              onHorizontalDragStart: (_) {},
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (_) {},
              // Make it transparent so buttons can be clicked
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String? svgImage;
  final String title;
  final String description;
  final String buttonText;

  OnboardingItem({
    required this.image,
    this.svgImage,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final VoidCallback onButtonPressed;

  final int currentPage;
  final int totalPages;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.onButtonPressed,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4FFF8), Color(0xFFFFFFFF)],
        ),
      ),

      child: SafeArea(
        child: Column(
          children: [
            // ================= LOGO =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),

              child: Row(
                children: [Image.asset('assets/gizikulogo.png', height: 34)],
              ),
            ),

            // ================= IMAGE =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),

                child: Hero(
                  tag: item.title,

                  child: item.svgImage != null
                      ? SvgPicture.asset(item.svgImage!, fit: BoxFit.contain)
                      : Image.asset(item.image, fit: BoxFit.contain),
                ),
              ),
            ),

            // ================= CONTENT =================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(38),
                  topRight: Radius.circular(38),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // TITLE
                  Text(
                    item.title,

                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // DESCRIPTION
                  Text(
                    item.description,

                    style: TextStyle(
                      fontSize: 15,
                      height: 1.8,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 34),

                  // BUTTON
                  AnimatedPrimaryButton(
                    text: item.buttonText,
                    onPressed: onButtonPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                elevation: _isHovered ? 6 : 0,
                shadowColor: const Color(0xFF2ECC71),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
