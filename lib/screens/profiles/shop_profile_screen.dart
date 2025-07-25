import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart'; 
import 'add_product_screen.dart';

class StoreProfileScreen extends StatelessWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeName = "Giziku Store";
    final storeLocation = "Bogor, Indonesia";
    final productCount = 255;

    final List<ProductModel> popularProducts = [
      ProductModel(
        title: "Sayur Bayam",
        description: "Sayur segar dari petani lokal.",
        price: 49000,
        storeName: "Giziku Store",
        location: ProductLocation(latitude: -6.5, longitude: 106.8, address: "Bogor, Indonesia"),
        imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
        expiredDate: "29/10/2025",
      ),
      ProductModel(
        title: "Daging Wagyu",
        description: "Daging wagyu premium.",
        price: 49000,
        storeName: "Giziku Store",
        location: ProductLocation(latitude: -6.5, longitude: 106.8, address: "Bogor, Indonesia"),
        imageUrl: "https://images.unsplash.com/photo-1519864600265-abb23847ef2c",
        expiredDate: "29/10/2025",
      ),
    ];

    final List<ProductModel> products = List.from(popularProducts)..addAll(popularProducts);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header: search, name, location, count, avatar
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 16),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  const Icon(Icons.search, color: Color(0xFFB0B0B0)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Search Product",
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Color(0xFFB0B0B0),
                                        ),
                                      ),
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Avatar toko
                      Row(
                        children: [
                          const SizedBox(width: 24),
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.yellow,
                              backgroundImage: const AssetImage('assets/profile/profile.png'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    storeLocation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_cart, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$productCount Produk",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Content: Populer and Product
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Populer Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.emoji_events_outlined, color: Color(0xFF262626)),
                            SizedBox(width: 8),
                            Text(
                              "Populer",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: popularProducts.length,
                          separatorBuilder: (c, i) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final product = popularProducts[i];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Product Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Product",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, i) {
                          final product = products[i];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Add Button
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(
                            product: ProductModel(
                            title: '',
                            description: '',
                            price: 0,
                            storeName: '',
                            location: ProductLocation(latitude: 0, longitude: 0, address: ''),
                            imageUrl: '',
                            expiredDate: '',
                          ),
                    ),
                  ),
                );
              }, // Add product action
              backgroundColor: const Color(0xFF2ECC71),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Navigate to detail on tap
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ECC71).withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                height: 95,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  width: double.infinity,
                  height: 95,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF2ECC71)),
                      const SizedBox(width: 4),
                      Text(
                        'Exp: ${product.expiredDate}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: Color(0xFFBDBDBD)),
                      const SizedBox(width: 4),
                      Text(
                        product.location.address,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                    ],
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