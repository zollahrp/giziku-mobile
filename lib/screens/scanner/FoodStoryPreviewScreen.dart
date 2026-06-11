import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/food_scan_model.dart';

class FoodStoryPreviewScreen extends StatefulWidget {
  final FoodScanModel result;
  final File imageFile;

  const FoodStoryPreviewScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  @override
  State<FoodStoryPreviewScreen> createState() => _FoodStoryPreviewScreenState();
}

class _FoodStoryPreviewScreenState extends State<FoodStoryPreviewScreen> {
  final GlobalKey _storyKey = GlobalKey();
  int selectedFilter = 0;
  bool isSharing = false;

  Widget buildImage() {
    Widget image = Image.file(
      widget.imageFile,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    switch (selectedFilter) {
      case 1:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.1,
            0,
            0,
            0,
            0,
            0,
            1.1,
            0,
            0,
            0,
            0,
            0,
            1.1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: image,
        );

      case 2:
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.orange.withOpacity(0.10),
            BlendMode.overlay,
          ),
          child: image,
        );

      case 3:
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            const Color(0xFF2AD882).withOpacity(0.08),
            BlendMode.softLight,
          ),
          child: image,
        );

      default:
        return image;
    }
  }

  Widget filterChip(String title, int index) {
    final selected = selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2AD882) : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Story Preview"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.1)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSharing
                  ? Container(
                      key: const ValueKey("loading"),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.all(12),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : IconButton(
                      key: const ValueKey("share"),
                      onPressed: shareStory,
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: _storyKey,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        buildImage(),

                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(.35),
                                Colors.transparent,
                                Colors.black.withOpacity(.75),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.18),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(.08),
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/gizikulogo_ceper.png',
                                    height: 42,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              Text(
                                result.foodName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(.30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _miniNutrition(
                                      "${result.calories}",
                                      "Kalori",
                                    ),
                                    _miniNutrition(
                                      "${result.protein}g",
                                      "Protein",
                                    ),
                                    _miniNutrition("${result.carbs}g", "Karbo"),
                                    _miniNutrition("${result.fats}g", "Lemak"),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "Dipindai dengan GIZIKU",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.7),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (isSharing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF2AD882),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Menyiapkan Story",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Mohon tunggu sebentar",
                          style: TextStyle(color: Colors.white.withOpacity(.7)),
                        ),
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

  Future<void> shareStory() async {
    if (isSharing) return;

    setState(() {
      isSharing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 250));

      RenderRepaintBoundary boundary =
          _storyKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3);

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        setState(() {
          isSharing = false;
        });
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();

      final file = File('${dir.path}/giziku_story.png');

      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Lihat hasil analisis dan informasi nutrisi makananmu dengan GIZIKU.');
    } catch (e) {
      debugPrint('Share error: $e');
    }

    if (mounted) {
      setState(() {
        isSharing = false;
      });
    }
  }

  Widget _miniNutrition(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }

  Widget _nutritionItem({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
}
