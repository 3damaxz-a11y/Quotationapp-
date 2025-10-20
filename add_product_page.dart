// lib/pages/add_product_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;

  const AddProductPage({
    super.key,
    this.existingProduct,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _taxController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hsnController = TextEditingController();

  String _appBarTitle = "Add Product"; // ✅ Title ko "Add Product" kar diya

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _nameController.text = product['name'] ?? '';
      _priceController.text = product['price']?.toString() ?? '';
      _unitController.text = product['unit'] ?? '';
      _taxController.text = product['tax']?.toString() ?? '';
      _descriptionController.text = product['description'] ?? '';
      _hsnController.text = product['hsn'] ?? '';
      _appBarTitle = "Edit Product";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _taxController.dispose();
    _descriptionController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = {
        'name': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'unit': _unitController.text,
        'tax': double.tryParse(_taxController.text) ?? 0.0,
        'description': _descriptionController.text,
        'hsn': _hsnController.text,
      };

      final prefs = await SharedPreferences.getInstance();
      List<String> products = prefs.getStringList('products') ?? [];

      if (widget.existingProduct != null) {
        // Edit mode
        String oldName = widget.existingProduct!['name'] ?? '';
        int existingIndex = products.indexWhere((p) {
          try {
            Map<String, dynamic> decoded = jsonDecode(p);
            return decoded['name'] == oldName;
          } catch (e) {
            return false;
          }
        });
        if (existingIndex != -1) {
          products[existingIndex] = jsonEncode(newProduct);
        } else {
          products.add(jsonEncode(newProduct));
        }
      } else {
        // Add mode
        products.add(jsonEncode(newProduct));
      }

      await prefs.setStringList('products', products);
      Navigator.pop(context, newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Background white
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_appBarTitle),
        // ✅ AppBar style update
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1, // Thora sa shadow
      ),
      body: SingleChildScrollView(
        // ✅ Padding update
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10), // Thora space oopar
              _buildTextField(_nameController, "Product Name",
                  isRequired: true),
              _buildTextField(_priceController, "Price",
                  keyboardType: TextInputType.number, isRequired: true),
              _buildTextField(
                  _unitController, "Unit Of Measure (SET, KG etc.)"),
              // ✅ Tax field update (% sign ke sath)
              _buildTextField(_taxController, "TAX",
                  keyboardType: TextInputType.number, suffixText: "%"),
              _buildTextField(_descriptionController, "Description",
                  maxLines: 2),
              _buildTextField(_hsnController, "HSN"),
              const SizedBox(height: 30), // Button se pehle space
            ],
          ),
        ),
      ),
      // ✅ Naya Bottom Button Style
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Black background
            foregroundColor: Colors.white, // White text
            minimumSize:
                const Size(double.infinity, 50), // Full width, height 50
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12) // Thore rounded corners
                ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // ✅ Button text update
          child: Text(widget.existingProduct != null ? "Update" : "Add"),
        ),
      ),
    );
  }

  // ✅ Helper widget for text fields (Updated Decoration)
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      bool isRequired = false,
      String? suffixText}) {
    // ✅ suffixText add kiya
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          // ✅ Nayi Decoration (Screenshot jaisi)
          hintText: label, // Label ko hint banaya
          filled: true,
          fillColor: Colors.grey[100], // Halka grey background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
            borderSide: BorderSide.none, // Koi border nahi
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixText: suffixText, // ✅ % sign ke liye
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                if (keyboardType == TextInputType.number &&
                    double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
