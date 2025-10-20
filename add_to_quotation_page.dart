// lib/pages/add_to_quotation_page.dart

import 'package:flutter/material.dart';

class AddToQuotationPage extends StatefulWidget {
  final Map<String, dynamic> product;
  // ✅ Naya variable
  final bool isDeliveryNote;

  const AddToQuotationPage({
    super.key,
    required this.product,
    this.isDeliveryNote = false, // ✅ Default value
  });

  @override
  State<AddToQuotationPage> createState() => _AddToQuotationPageState();
}

class _AddToQuotationPageState extends State<AddToQuotationPage> {
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.product['price']?.toString() ?? '0');
    _qtyController = TextEditingController(
        text: widget.product['quantity']?.toString() ?? '1');
    _taxController =
        TextEditingController(text: widget.product['tax']?.toString() ?? '0');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    final updatedProduct = Map<String, dynamic>.from(widget.product);
    updatedProduct['price'] = double.tryParse(_priceController.text) ?? 0.0;
    updatedProduct['quantity'] = int.tryParse(_qtyController.text) ?? 1;
    updatedProduct['tax'] = double.tryParse(_taxController.text) ?? 0.0;
    Navigator.pop(context, updatedProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Add Product'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Naya Logic: Agar delivery note hai toh price/tax mat dikhao
            if (!widget.isDeliveryNote) ...[
              _buildTextField(
                controller: _priceController,
                label: "Price",
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _taxController,
                label: "Tax (%)",
                icon: Icons.percent,
              ),
              const SizedBox(height: 16),
            ],

            _buildTextField(
              controller: _qtyController,
              label: "Quantity",
              icon: Icons.production_quantity_limits,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Add to Document",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
