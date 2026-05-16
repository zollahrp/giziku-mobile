import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/food_scan_model.dart';
import '../../services/scanner_service.dart';
import 'scanner_result_screen.dart';

class ScanningScreen extends StatefulWidget {
  final File imageFile;

  const ScanningScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<ScanningScreen> createState() =>
      _ScanningScreenState();
}

class _ScanningScreenState
    extends State<ScanningScreen> {

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  Future<void> startScanning() async {

    final result =
        await ScannerService().scanFood(
      widget.imageFile,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerResultScreen(
          result: result,
          imageFile: widget.imageFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            /// AI LOADING
            const SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Color(0xFF2AD882),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Scanning Food...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "AI is analyzing nutrition data",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 50),

            Image.file(
              widget.imageFile,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}