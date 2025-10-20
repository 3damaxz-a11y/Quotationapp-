// lib/pages/purchase_order_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Page Imports
import 'package:business_manager_app/pages/customer_page.dart'; // Supplier ke liye use kar rahe
import 'package:business_manager_app/pages/add_product_page.dart';
import 'package:business_manager_app/pages/add_to_quotation_page.dart';
import 'package:business_manager_app/utils/purchase_order_helper.dart';

// PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ✅ Naye Template Imports
import 'package:business_manager_app/utils/business_helper.dart'; // BusinessInfo ke liye
import 'package:business_manager_app/utils/pdf_templates.dart'; // Templates ke liye

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  // Data and Variables (Pehle Jaisay)
  String poNumber = "PO-1001";
  DateTime poDate = DateTime.now();
  Map<String, dynamic>? selectedSupplier;
  List<Map<String, dynamic>> selectedProducts = [];
  double totalAmount = 0.0;
  double totalTax = 0.0;
  String currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // Load currency
    _generatePONo();
  }

  // --- Functions (Load Currency, Generate No, Selectors, Add Product, Calculate Totals, Save PO [old version]) ---
  // Yeh functions pehle jaisay hi hain
  Future<void> _loadCurrency() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _generatePONo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastPONo') ?? 1000;
    if (mounted) {
      setState(() {
        poNumber = "PO-${lastNo + 1}";
      });
    }
  }

  Future<void> _selectSupplier() async {
    /* ... Pehle Jaisa ... */
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerPage(selectMode: true),
      ),
    );
    if (selected != null && selected is Map<String, dynamic>) {
      setState(() => selectedSupplier = selected);
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
                            subtitle: Text(
                                "$currency ${p['price']} | Tax: ${p['tax'] ?? 0}%"),
                            onTap: () async {
                              final updatedProduct = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddToQuotationPage(product: p),
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
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(product['tax']?.toString() ?? '0') ?? 0.0;
    final qty = int.tryParse(product['quantity']?.toString() ?? '1') ?? 1;
    final existingIndex =
        selectedProducts.indexWhere((p) => (p['name'] ?? '') == name);
    if (existingIndex != -1) {
      setState(() {
        final existing = selectedProducts[existingIndex];
        existing['quantity'] = (existing['quantity'] ?? 1) + qty;
        existing['price'] = price;
        existing['tax'] = tax;
        _calculateTotals();
      });
    } else {
      final newEntry = Map<String, dynamic>.from(product);
      newEntry['price'] = price;
      newEntry['tax'] = tax;
      newEntry['quantity'] = qty;
      setState(() {
        selectedProducts.add(newEntry);
        _calculateTotals();
      });
    }
  }

  void _calculateTotals() {
    /* ... Pehle Jaisa ... */
    double subtotal = 0;
    double tax = 0;
    for (var p in selectedProducts) {
      double price = double.tryParse(p['price'].toString()) ?? 0.0;
      double t = double.tryParse(p['tax'].toString()) ?? 0.0;
      int qty = p['quantity'] ?? 1;
      double itemSubtotal = price * qty;
      subtotal += itemSubtotal;
      tax += itemSubtotal * t / 100;
    }
    setState(() {
      totalTax = tax;
      totalAmount = subtotal + tax;
    });
  }

  // ✅ UPDATED: Ab yeh function PDF bhi generate karega
  Future<void> _saveAndGeneratePO() async {
    if (selectedSupplier == null || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select supplier and add products")),
      );
      return;
    }

    final newPO = {
      'poNo': poNumber,
      'date': DateFormat('yyyy-MM-dd').format(poDate),
      'supplierName': selectedSupplier?['name'] ?? 'N/A',
      'supplierDetails': selectedSupplier,
      'items': selectedProducts,
      'subtotal': totalAmount - totalTax,
      'tax': totalTax,
      'total': totalAmount,
      'currency': currency,
    };

    // 1. Save PO
    await PurchaseOrderHelper.savePO(newPO);

    // 2. Save new PO number
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPONo', int.parse(poNumber.split('-')[1]));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ PO saved! Generating PDF...")),
    );

    // 3. ✅ Generate PDF using templates
    await _generatePdf(newPO);

    // 4. Reset form
    setState(() {
      poNumber = "PO-${int.parse(poNumber.split('-')[1]) + 1}";
      selectedSupplier = null;
      selectedProducts.clear();
      totalAmount = 0.0;
      totalTax = 0.0;
    });
  }

  // --- PDF Generation (✅ UPDATED TO USE TEMPLATES) ---
  Future<void> _generatePdf(Map<String, dynamic> po) async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header & Footer
    // Humara header business info dikhata hai, PO mein shayad supplier info dikhana behtar ho?
    // Filhal hum standard header istemal kar rahe hain. Aap isay customize kar saktay hain.
    final headerWidget = await buildPdfHeader(businessInfo, "Purchase Order");
    final footerWidget = await buildPdfFooter(businessInfo);

    // 3. Prepare PO Data
    final supplier = po['supplierDetails'] ?? {};
    final items = List<Map<String, dynamic>>.from(po['items'] ?? []);
    final pdfCurrency = businessInfo.currency;
    final String poDateFormatted = DateFormat('dd/MM/yyyy').format(poDate);
    final double subtotal = po['subtotal'] ?? 0.0;
    final double tax = po['tax'] ?? 0.0;
    final double total = po['total'] ?? 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          // Supplier & PO Details
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    /* Supplier */ crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TO (SUPPLIER):",
                          style: pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(supplier['name'] ?? '',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      if (supplier['company']?.isNotEmpty ?? false)
                        pw.Text(supplier['company']!),
                      if (supplier['phone']?.isNotEmpty ?? false)
                        pw.Text("Ph: ${supplier['phone']!}"),
                    ]),
                pw.Column(
                    /* PO Details */ crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("PO No: ${po['poNo']}"),
                      pw.Text("Date: $poDateFormatted"),
                    ])
              ]),
          pw.SizedBox(height: 25),
          // Items Table
          _buildPdfTable(items, pdfCurrency), // Reuse Helper
          pw.SizedBox(height: 20),
          // Totals
          pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.ConstrainedBox(
                  constraints: const pw.BoxConstraints(maxWidth: 250),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                            "Subtotal: $pdfCurrency ${subtotal.toStringAsFixed(2)}"),
                        pw.Text(
                            "Total Tax: $pdfCurrency ${tax.toStringAsFixed(2)}"),
                        pw.Divider(height: 5),
                        pw.Text(
                            "Total Amount: $pdfCurrency ${total.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ]))),
          // Add any specific PO notes or terms here if needed
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // PDF Table Helper (Slightly modified for PO)
  pw.Widget _buildPdfTable(List<Map<String, dynamic>> items, String currency) {
    final headers = ['Product', 'Qty', 'Price', 'Tax %', 'Total'];
    final data = items.map((p) {
      double price = p['price'] ?? 0.0;
      int qty = p['quantity'] ?? 1;
      double taxPercent = p['tax'] ?? 0.0;
      double total = (price * qty) * (1 + taxPercent / 100);
      return [
        p['name'] ?? '',
        qty.toString(),
        "$currency ${price.toStringAsFixed(2)}",
        "${taxPercent.toStringAsFixed(2)}%", // Show tax %
        "$currency ${total.toStringAsFixed(2)}"
      ];
    }).toList();

    // PO mein usually 'Other Charges' nahi hotay, agar add karne hain toh yahan logic daal saktay hain.

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
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FixedColumnWidth(30), // Qty
        2: const pw.FixedColumnWidth(60), // Price
        3: const pw.FixedColumnWidth(40), // Tax %
        4: const pw.FixedColumnWidth(70), // Total
      },
    );
  }

  // --- UI Build (Pehle Jaisa) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Purchase Order"),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              /* PO Info */ mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PO No: $poNumber",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd/MM/yyyy').format(poDate)),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              /* Select Supplier */ onTap: _selectSupplier,
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
                      selectedSupplier != null
                          ? "Supplier: ${selectedSupplier!['name']}"
                          : "TO (SUPPLIER)",
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
                    subtitle: Text(
                        "Price: ${product['price']} | Qty: ${product['quantity']} | Tax: ${product['tax']}%"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedProducts.removeAt(index);
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              /* Totals */ child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Tax:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$currency ${totalTax.toStringAsFixed(2)}"),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("$currency ${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              /* Save Button */
              // ✅ Function call update kar diya
              onPressed: _saveAndGeneratePO,
              icon: const Icon(Icons.save),
              label: const Text("Save & Generate PO PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
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
