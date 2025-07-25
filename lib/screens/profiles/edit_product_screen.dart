import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../models/product_model.dart';
import '../../repositories/product_repository.dart'; 

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _expiredDateController;

  String _selectedCategory = "Veggie";
  DateTime? _selectedDate;

  final List<String> _categories = [
    "Veggie", "Meal +", "Veggie +", "Meal +",
    "Veggie +", "Meal +", "Veggie +", "Meal +"
  ];

  String? _selectedFileName;
  String? _uploadedImageUrl;
  late ProductLocation _location;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.title);
    _descController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _expiredDateController = TextEditingController(text: widget.product.expiredDate);
    _selectedCategory = widget.product.storeName.isNotEmpty ? widget.product.storeName : "Veggie";
    _selectedDate = widget.product.expiredDate.isNotEmpty
        ? DateTime.tryParse(widget.product.expiredDate)
        : null;
    _location = widget.product.location;
    _uploadedImageUrl = widget.product.imageUrl.isNotEmpty ? widget.product.imageUrl : null;
    _selectedFileName = _uploadedImageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    var status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _selectedFileName = picked.name;
    });

    // Upload image to server
    final uri = Uri.parse('https://api.yourdomain.com/upload'); // Ganti URL upload API-mu
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final url = (jsonDecode(respStr) as Map<String, dynamic>)['url'];
      setState(() => _uploadedImageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiredDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProduct = ProductModel(
      id: widget.product.id,
      title: _nameController.text,
      description: _descController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      storeName: _selectedCategory,
      location: _location,
      imageUrl: _uploadedImageUrl ?? '',
      expiredDate: _expiredDateController.text,
    );

    final repo = ProductRepository(apiUrl: 'https://api.yourdomain.com'); // Ganti endpoint

    final success = await repo.updateProduct(updatedProduct);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              // Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71), size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Image/Ilustration
              Image.asset(
                'assets/profile/adproduct.png',
                height: 170,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              // Title
              const Text(
                "Edit Product",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 22),
              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.isEmpty ? "Product name required" : null,
                      decoration: InputDecoration(
                        hintText: "Product Name",
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category
                    const Text(
                      "Category",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_categories.length, (idx) {
                        final cat = _categories[idx];
                        final selected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF2ECC71) : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: selected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Description
                    TextFormField(
                      controller: _descController,
                      minLines: 2,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? "Description required" : null,
                      decoration: InputDecoration(
                        hintText: "Description",
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? "Price required" : null,
                      decoration: InputDecoration(
                        hintText: "Price",
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Expired Date
                    TextFormField(
                      controller: _expiredDateController,
                      readOnly: true,
                      validator: (v) => v == null || v.isEmpty ? "Expired date required" : null,
                      decoration: InputDecoration(
                        hintText: "Expired Date",
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71))),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today, color: Color(0xFF2ECC71)),
                          onPressed: _pickDate,
                        ),
                      ),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    // Product Photo
                    const Text(
                      "Product Photo",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickAndUploadImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F3F3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            "Choose Image",
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF8C8C8C)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _uploadedImageUrl != null
                            ? Image.network(_uploadedImageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                            : (_pickedImage != null
                                ? Image.file(_pickedImage!, width: 50, height: 50, fit: BoxFit.cover)
                                : const Text("No file chosen")),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}