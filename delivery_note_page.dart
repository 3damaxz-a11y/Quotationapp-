// lib/pages/delivery_note_page.dart

import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ YAQEENI BANAYEN KE YEH LINE SAHI HAI
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Page Imports
import 'package:business_manager_app/pages/customer_page.dart';
import 'package:business_manager_app/pages/add_product_page.dart';
import 'package:business_manager_app/pages/add_to_quotation_page.dart'; // Reuse karengey
import 'package:business_manager_app/utils/delivery_note_helper.dart';

// PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Template Imports
import 'package:business_manager_app/utils/business_helper.dart'; // BusinessInfo ke liye
import 'package:business_manager_app/utils/pdf_templates.dart'; // Templates ke liye

class DeliveryNotePage extends StatefulWidget {
  const DeliveryNotePage({super.key});

  @override
  State<DeliveryNotePage> createState() => _DeliveryNotePageState();
}

class _DeliveryNotePageState extends State<DeliveryNotePage> {
  // Data (Pehle Jaisay)
  String deliveryNoteNo = "DN-1001";
  DateTime deliveryDate = DateTime.now();
  Map<String, dynamic>? selectedCustomer;
  List<Map<String, dynamic>> selectedProducts = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateDeliveryNoteNo();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- Functions (Generate No, Selectors, Add Product, Save Note [old version]) ---
  // Yeh functions pehle jaisay hi hain
  Future<void> _generateDeliveryNoteNo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastDeliveryNoteNo') ?? 1000;
    if (mounted) {
      setState(() {
        deliveryNoteNo = "DN-${lastNo + 1}";
      });
    }
  }

  Future<void> _selectCustomer() async {
    /* ... Pehle Jaisa ... */
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerPage(selectMode: true),
      ),
    );
    if (selected != null && selected is Map<String, dynamic>) {
      setState(() => selectedCustomer = selected);
    }
  }

  Future<void> _selectProduct() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    List<String> storedProducts = prefs.getStringList('products') ?? [];
    List<Map<String, dynamic>> products = storedProducts
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                children: [
                  const Text("Select Product",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = Map<String, dynamic>.from(products[index]);
                        return Card(
                          child: ListTile(
                            title: Text(p['name'] ?? ''),
                            subtitle: Text("Unit: ${p['unit'] ?? 'N/A'}"),
                            onTap: () async {
                              p['price'] = 0.0;
                              p['tax'] = 0.0;
                              final updatedProduct = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddToQuotationPage(
                                      product: p, isDeliveryNote: true),
                                ),
                              );
                              if (updatedProduct != null &&
                                  updatedProduct is Map<String, dynamic>) {
                                _addOrIncrementProduct(updatedProduct);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final newProduct = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddProductPage()));
                      if (newProduct != null &&
                          newProduct is Map<String, dynamic>) {
                        _addOrIncrementProduct(newProduct);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add New Product"),
                  ),
                ],
              ),
            ));
  }

  void _addOrIncrementProduct(Map<String, dynamic> product) {
    /* ... Pehle Jaisa ... */
    final name = (product['name'] ?? '').toString();
    if (name.isEmpty) return;
    final qty = int.tryParse(product['quantity']?.toString() ?? '1') ?? 1;
    final existingIndex =
        selectedProducts.indexWhere((p) => (p['name'] ?? '') == name);
    if (existingIndex != -1) {
      setState(() {
        final existing = selectedProducts[existingIndex];
        existing['quantity'] = (existing['quantity'] ?? 1) + qty;
      });
    } else {
      final newEntry = Map<String, dynamic>.from(product);
      newEntry['quantity'] = qty;
      newEntry.remove('price');
      newEntry.remove('tax');
      setState(() {
        selectedProducts.add(newEntry);
      });
    }
  }

  // UPDATED: Ab yeh function PDF bhi generate karega
  Future<void> _saveAndGenerateNote() async {
    if (selectedCustomer == null || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select customer and add products")),
      );
      return;
    }

    final newDN = {
      'deliveryNoteNo': deliveryNoteNo,
      'date': DateFormat('yyyy-MM-dd').format(deliveryDate),
      'customerName': selectedCustomer?['name'] ?? 'N/A',
      'customerDetails': selectedCustomer,
      'items': selectedProducts,
      'notes': _notesController.text,
    };

    // 1. Save Delivery Note
    await DeliveryNoteHelper.saveDeliveryNote(newDN);

    // 2. Save new DN number
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'lastDeliveryNoteNo', int.parse(deliveryNoteNo.split('-')[1]));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Delivery Note saved! Generating PDF...")),
    );

    // 3. Generate PDF using templates
    await _generatePdf(newDN);

    // 4. Reset form
    setState(() {
      deliveryNoteNo = "DN-${int.parse(deliveryNoteNo.split('-')[1]) + 1}";
      selectedCustomer = null;
      selectedProducts.clear();
      _notesController.clear();
    });
  }

  // --- PDF Generation (UPDATED TO USE TEMPLATES) ---
  Future<void> _generatePdf(Map<String, dynamic> dn) async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header & Footer
    final headerWidget =
        await buildPdfHeader(businessInfo, "Delivery Note / Challan");
    final footerWidget = await buildPdfFooter(businessInfo);

    // 3. Prepare DN Data
    final customer = dn['customerDetails'] ?? {};
    final items = List<Map<String, dynamic>>.from(dn['items'] ?? []);
    final notes = dn['notes'] ?? '';
    final String dnDate = DateFormat('dd/MM/yyyy').format(deliveryDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          // Customer & DN Details
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    /* Customer */ crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TO (CUSTOMER):",
                          style: pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(customer['name'] ?? '',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      if (customer['company']?.isNotEmpty ?? false)
                        pw.Text(customer['company']!),
                      if (customer['phone']?.isNotEmpty ?? false)
                        pw.Text("Ph: ${customer['phone']!}"),
                    ]),
                pw.Column(
                    /* DN Details */ crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Note No: ${dn['deliveryNoteNo']}"),
                      pw.Text("Date: $dnDate"),
                    ])
              ]),
          pw.SizedBox(height: 25),
          // Items Table (Sirf Quantity)
          _buildPdfTable(items), // Reuse Helper (modified)
          pw.SizedBox(height: 20),

          // Notes
          if (notes.isNotEmpty) ...[
            pw.Text("Notes / Remarks:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(notes),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // PDF Table Helper (Modified for Delivery Note - No Price/Total)
  pw.Widget _buildPdfTable(List<Map<String, dynamic>> items) {
    final headers = ['#', 'Product Description', 'Quantity']; // Columns change
    int i = 1;
    final data = items.map((p) {
      return [
        (i++).toString(),
        p['name'] ?? '',
        p['quantity'].toString(),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      columnWidths: {
        // Adjust column widths
        0: const pw.FixedColumnWidth(25), // #
        1: const pw.FlexColumnWidth(4), // Description (Wider)
        2: const pw.FixedColumnWidth(50), // Qty
      },
    );
  }

  // --- UI Build (Pehle Jaisa) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Delivery Note"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              /* Note Info */ mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Note No: $deliveryNoteNo",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd/MM/yyyy').format(deliveryDate)),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              /* Select Customer */ onTap: _selectCustomer,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCustomer != null
                          ? "Customer: ${selectedCustomer!['name']}"
                          : "TO (CUSTOMER)",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.add),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              /* Select Product */ onTap: _selectProduct,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("PRODUCTS",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    Icon(Icons.add),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              /* Product List */ shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) {
                final product = selectedProducts[index];
                return Card(
                  child: ListTile(
                    title: Text(product['name'] ?? ''),
                    subtitle: Text("Quantity: ${product['quantity']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedProducts.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              /* Notes */ controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Notes / Remarks (Optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              /* Save Button */
              onPressed: _saveAndGenerateNote,
              icon: const Icon(Icons.save),
              label: const Text("Save & Generate PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
