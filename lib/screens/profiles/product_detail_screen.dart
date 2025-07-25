import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_model.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  void _openMap(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Are you sure?"),
        content: const Text(
          "This data will be delete from your product store",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF2ECC71),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Product deleted successfully.",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  backgroundColor: Color(0xFFFF3B30),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "Confirm",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
      backgroundColor: const Color(0xFF2ECC71),
      body: Stack(
        children: [
          // Product image
          SizedBox(
            height: 340,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Top action buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showDeleteDialog(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, color: Color(0xFFFF3B30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Product details section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 350,
                maxHeight: 420,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Product title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Store info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.yellow,
                          backgroundImage: const AssetImage('assets/profile/profile.png'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.storeName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 15, color: Color(0xFF2ECC71)),
                              const SizedBox(width: 3),
                              Text(
                                product.location.address,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF8C8C8C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Divider
                  Container(
                    width: double.infinity,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFF2ECC71).withOpacity(0.2),
                  ),
                  // Product description
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        product.description,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF8C8C8C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Check Location Button & Edit Icon
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _openMap(product.location.latitude, product.location.longitude);
                            },
                            icon: const Icon(Icons.edit_location_alt, color: Colors.white),
                            label: const Text(
                              "Check Location",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(product: product),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}