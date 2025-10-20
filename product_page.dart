// lib/pages/product_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_page.dart';
// Note: We are removing AddToQuotationPage import for now as list items won't navigate there directly anymore.

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = []; // For search
  final TextEditingController _searchController =
      TextEditingController(); // For search
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Listener for search controller
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter logic
  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredProducts = List.from(allProducts);
      });
    } else {
      setState(() {
        filteredProducts = allProducts.where((p) {
          final name = p['name']?.toString().toLowerCase() ?? '';
          return name.contains(query);
        }).toList();
      });
    }
  }

  // Load products from SharedPreferences
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final productData = prefs.getStringList('products') ?? [];
    setState(() {
      allProducts = productData
          .map((p) => Map<String, dynamic>.from(jsonDecode(p)))
          .toList();
      // ✅ Sort products alphabetically by name
      allProducts.sort((a, b) => (a['name'] ?? '')
          .toLowerCase()
          .compareTo((b['name'] ?? '').toLowerCase()));
      filteredProducts = List.from(allProducts); // Initialize filtered list
      _isLoading = false;
    });
  }

  // Save products list to SharedPreferences
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Sort before saving to maintain order
    allProducts.sort((a, b) => (a['name'] ?? '')
        .toLowerCase()
        .compareTo((b['name'] ?? '').toLowerCase()));
    final productData = allProducts.map((p) => jsonEncode(p)).toList();
    await prefs.setStringList('products', productData);
  }

  // Navigate to Add Product Page
  Future<void> _navigateToAddProduct(
      {Map<String, dynamic>? existingProduct}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          // ✅ YAHAN existingProduct PASS KIYA JAYEGA
          builder: (context) =>
              AddProductPage(existingProduct: existingProduct)),
    );

    // If a product was added or updated, reload the list
    if (result != null && result is Map<String, dynamic>) {
      await _loadProducts(); // Reload to reflect changes

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingProduct != null
                ? 'Product updated successfully!'
                : 'Product added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Delete Product
  Future<void> _deleteProduct(int indexInFilteredList) async {
    // Confirm deletion
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Product"),
            content:
                const Text("Are you sure you want to delete this product?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Delete",
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      // Find the product in the original list using a unique identifier (like name, assuming names are unique for now)
      Map<String, dynamic> productToDelete =
          filteredProducts[indexInFilteredList];
      String productName = productToDelete['name'] ?? '';
      allProducts.removeWhere((p) => p['name'] == productName);
      // Update the filtered list as well
      _filterProducts();
    });
    await _saveProducts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Build individual product card
  Widget _productCard(Map<String, dynamic> product, int index) {
    final name = product['name']?.toString() ?? 'No Name';
    final price = product['price']?.toString() ?? '-';
    final unit = product['unit']?.toString().isEmpty ?? true
        ? '-'
        : product['unit'].toString();
    final tax = product['tax']?.toString().isEmpty ?? true
        ? '0'
        : product['tax'].toString();
    final desc = product['description']?.toString() ?? '';
    final hsn = product['hsn']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.black87,
          child:
              Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Price: Rs $price"),
              Text("Unit: $unit | TAX: $tax%"),
              if (desc.isNotEmpty)
                Text("Desc: $desc",
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              if (hsn.isNotEmpty) Text("HSN: $hsn"),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
              tooltip: "Edit",
              // ✅ YAHAN existingProduct PASS KIYA JAYEGA
              onPressed: () => _navigateToAddProduct(existingProduct: product),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Delete",
              onPressed: () => _deleteProduct(index),
            ),
          ],
        ),
        // onTap: () => _openAddToQuotation(product), // Removed direct navigation
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Updated background
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.black, // Updated AppBar color
        foregroundColor: Colors.white, // Updated text/icon color
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Product Name',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No products added yet.\nTap + button to add one.'
                                : 'No products found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 80), // Space for FAB
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _productCard(filteredProducts[index], index);
                          },
                        ),
                ),
              ],
            ),
      // Updated Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black, // Match AppBar
        onPressed: () => _navigateToAddProduct(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
