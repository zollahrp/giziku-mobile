import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductRepository {
  final String apiUrl;
  ProductRepository({required this.apiUrl});

  Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(Uri.parse('$apiUrl/products'));
    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    final response = await http.post(
      Uri.parse('$apiUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
    return response.statusCode == 201;
  }

  // Update produk
  Future<bool> updateProduct(ProductModel product) async {
    final response = await http.put(
      Uri.parse('$apiUrl/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
    return response.statusCode == 200;
  }
}