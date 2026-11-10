import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:flutter_svg/flutter_svg.dart';

class SplashLogoScreen extends StatefulWidget {
  final Widget? nextScreen;
  
  const SplashLogoScreen({super.key, this.nextScreen});

  @override
  State<SplashLogoScreen> createState() => _SplashLogoScreenState();
}

class _SplashLogoScreenState extends State<SplashLogoScreen> {
  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Timer to navigate to the next screen after 3 seconds
      Timer(const Duration(seconds: 3), () {
        print("Timer completed - attempting navigation");
        if (widget.nextScreen != null) {
          print("nextScreen is not null, navigating to: ${widget.nextScreen.runtimeType}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.nextScreen!),
          );
        } else {
          print("ERROR: nextScreen is null, cannot navigate");
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF2ECC71), 
        child: Center(
          child: Container(
            width: 200,
            height: 200,
            child: Center(
              child: Image.asset(
                'assets/gizifylogo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}