import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _goToNextPage() {
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
                  SizedBox(
                    width: double.infinity,
                    height: 60,

                    child: ElevatedButton(
                      onPressed: onButtonPressed,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            item.buttonText,

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
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
