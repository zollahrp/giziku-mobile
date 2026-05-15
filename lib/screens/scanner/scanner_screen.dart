import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/food_scan_model.dart';
import '../../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {

  File? image;
  bool isLoading = false;

  Future<void> scanFood() async {

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile == null) return;

    setState(() {
      image = File(pickedFile.path);
      isLoading = true;
    });

    try {

      FoodScanModel result =
          await ScannerService().scanFood(image!);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(result.foodName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calories: ${result.calories} kcal'),
              Text('Protein: ${result.protein} g'),
              Text('Carbs: ${result.carbs} g'),
              Text('Fats: ${result.fats} g'),
              Text('Health Score: ${result.healthScore}/10'),
            ],
          ),
        ),
      );

    } catch (e) {

      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
      ),

      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: scanFood,
                child: const Text('Scan Food'),
              ),
      ),
    );
  }
}