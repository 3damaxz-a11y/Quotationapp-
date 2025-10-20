// lib/pages/quotation_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Page Imports
import 'package:business_manager_app/pages/terms_selection_page.dart';
import 'package:business_manager_app/pages/add_product_page.dart';
import 'package:business_manager_app/pages/add_to_quotation_page.dart';
import 'package:business_manager_app/pages/customer_page.dart';

// ✅ Naye Imports
import 'package:business_manager_app/utils/business_helper.dart';
import 'package:business_manager_app/utils/pdf_templates.dart';

class QuotationPage extends StatefulWidget {
  final Map<String, dynamic>? existingQuotation;
  final int? editIndex;

  const QuotationPage({super.key, this.existingQuotation, this.editIndex});

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  // Controllers and Data (Pehle Jaisa)
  Map<String, dynamic>? selectedCustomer;
  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> _otherCharges = [];
  List<String> selectedTerms = [];
  final TextEditingController _otherInfoController = TextEditingController();

  // Calculation Variables (Pehle Jaisa)
  double totalAmount = 0;
  double totalTax = 0;
  String currency = 'Rs';
  String quotationNo = '-';
  DateTime quotationDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateQuotationNo();
    _loadCurrency();

    if (widget.existingQuotation != null) {
      final q = widget.existingQuotation!;
      setState(() {
        quotationNo = q['quotationNumber'] ?? '-';
        try {
          quotationDate = DateFormat('yyyy-MM-dd').parse(q['date']);
        } catch (_) {
          quotationDate = DateTime.now();
        }
        selectedCustomer = q['customer'];
        selectedProducts = (q['products'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _otherCharges = (q['otherCharges'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _otherInfoController.text = q['otherInfo'] ?? '';
        selectedTerms = List<String>.from(q['terms'] ?? []);
        _calculateTotals();
      });
    }
  }

  // --- Functions (Load Currency, Generate No, Selectors, Add Product/Charge/Terms, Calculate Totals, Save Quotation) ---
  // Yeh saare functions bilkul pehle jaisay hi hain, in mein koi tabdeeli nahi
  Future<void> _loadCurrency() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _generateQuotationNo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastQuotationNo') ?? 1000;
    if (widget.existingQuotation == null) {
      setState(() {
        quotationNo = (lastNo + 1).toString();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            const Text(
              "Select Product",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products available.'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = Map<String, dynamic>.from(products[index]);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(p['name'] ?? ''),
                            subtitle: Text(
                                "$currency ${p['price']} | Tax: ${p['tax'] ?? 0}%"),
                            trailing:
                                const Icon(Icons.add_circle_outline_outlined),
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
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final newProduct = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddProductPage()),
                    );
                    if (newProduct != null &&
                        newProduct is Map<String, dynamic>) {
                      _addOrIncrementProduct(newProduct);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Product"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _addOtherCharge() {
    /* ... Pehle Jaisa ... */
    String label = "Other Charges";
    String amount = "";
    bool isTaxable = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Other Charge Info",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Other Charges"),
                    onChanged: (value) => label = value,
                    controller: TextEditingController(text: label),
                  ),
                  TextField(
                    decoration: const InputDecoration(hintText: "Enter amount"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => amount = value,
                  ),
                  Row(
                    children: [
                      const Text("Is Taxable?"),
                      Checkbox(
                        value: isTaxable,
                        onChanged: (val) {
                          setModalState(() => isTaxable = val ?? false);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (amount.isNotEmpty) {
                          setState(() {
                            _otherCharges.add({
                              'label': label,
                              'amount': double.tryParse(amount) ?? 0.0,
                              'isTaxable': isTaxable,
                            });
                            _calculateTotals();
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _selectTerms() async {
    /* ... Pehle Jaisa ... */
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsSelectionPage()),
    );
    if (result != null && result is List<String>) {
      setState(() {
        selectedTerms = result;
      });
    }
  }

  void _calculateTotals() {
    /* ... Pehle Jaisa ... */
    double total = 0;
    double tax = 0;
    for (var p in selectedProducts) {
      double price = double.tryParse(p['price'].toString()) ?? 0.0;
      double t = double.tryParse(p['tax'].toString()) ?? 0.0;
      int qty = p['quantity'] ?? 1;
      total += price * qty;
      tax += (price * qty) * t / 100;
    }
    for (var o in _otherCharges) {
      total += (o['amount'] ?? 0);
      if (o['isTaxable'] == true) {
        tax += (o['amount'] ?? 0) * 0.18;
      }
    }
    setState(() {
      totalTax = tax;
      totalAmount = total + tax;
    });
  }

  Future<void> _saveQuotation() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    List<String> quotations = prefs.getStringList('quotations') ?? [];
    Map<String, dynamic> newQuotation = {
      'quotationNumber': quotationNo,
      'date': DateFormat('yyyy-MM-dd').format(quotationDate),
      'customerName': selectedCustomer?['name'] ?? '',
      'customer': selectedCustomer,
      'products': selectedProducts,
      'otherCharges': _otherCharges,
      'totalTax': totalTax,
      'totalAmount': totalAmount,
      'currency': currency,
      'otherInfo': _otherInfoController.text,
      'terms': selectedTerms,
    };
    if (widget.editIndex != null) {
      quotations[widget.editIndex!] = jsonEncode(newQuotation);
    } else {
      quotations.add(jsonEncode(newQuotation));
      await prefs.setInt('lastQuotationNo', int.parse(quotationNo));
    }
    await prefs.setStringList('quotations', quotations);
  }

  Future<void> _generateAndSaveQuotation() async {
    /* ... Pehle Jaisa ... */
    if (selectedCustomer == null || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select customer and add products")));
      return;
    }
    await _saveQuotation();
    await _generatePDF();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editIndex != null
            ? "Quotation updated & PDF generated!"
            : "Quotation saved & PDF generated!"),
      ),
    );
    if (widget.editIndex == null) {
      setState(() {
        quotationNo = (int.parse(quotationNo) + 1).toString();
        selectedCustomer = null;
        selectedProducts.clear();
        _otherCharges.clear();
        selectedTerms.clear();
        _otherInfoController.clear();
        _calculateTotals();
      });
    }
  }

  // --- PDF Generation (✅ UPDATED TO USE TEMPLATES) ---

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    // 1. Load Business Info using the helper
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header using the template
    final headerWidget =
        await buildPdfHeader(businessInfo, "Quotation"); // Pass title

    // 3. Build Footer using the template
    final footerWidget = await buildPdfFooter(businessInfo);

    // 4. Prepare data specific to this quotation
    final customer = selectedCustomer ?? {};
    final products = selectedProducts;
    final otherCharges = _otherCharges;
    final terms = selectedTerms;
    final otherInfo = _otherInfoController.text;
    final String qDate = DateFormat('dd/MM/yyyy').format(quotationDate);

    pdf.addPage(
      pw.MultiPage(
        // Use MultiPage in case content is long
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30), // Standard margin

        // Use the header template
        header: (context) => headerWidget,

        // Use the footer template (for every page)
        footer: (context) => footerWidget,

        build: (context) => [
          // List of widgets for the main content
          // Customer Info and Quotation Details
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    // Customer Info
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TO (CUSTOMER):",
                          style: pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(customer['name'] ?? '',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14)), // Larger font
                      if (customer['company']?.isNotEmpty ?? false)
                        pw.Text(customer['company']!,
                            style: const pw.TextStyle(fontSize: 9)),
                      if (customer['phone']?.isNotEmpty ?? false)
                        pw.Text("Ph: ${customer['phone']!}",
                            style: const pw.TextStyle(fontSize: 9)),
                      // Add Address if needed
                    ]),
                pw.Column(
                    // Quotation Details
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Quotation No: $quotationNo",
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Date: $qDate",
                          style: const pw.TextStyle(fontSize: 9)),
                      if (otherInfo.isNotEmpty)
                        pw.Text("Info: $otherInfo",
                            style: const pw.TextStyle(fontSize: 9)),
                    ]),
              ]),
          pw.SizedBox(height: 25), // More space before table

          // Products Table
          _buildPdfTable(
              products, otherCharges, currency), // Reuse table helper
          pw.SizedBox(height: 20),

          // Totals Section (Right Aligned)
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("Total Tax: $currency ${totalTax.toStringAsFixed(2)}"),
              pw.Divider(height: 5, color: PdfColors.grey),
              pw.Text("Amount Due: $currency ${totalAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16) // Larger font
                  ),
            ])
          ]),
          pw.SizedBox(height: 30), // Space before terms

          // Terms & Conditions (if any)
          if (terms.isNotEmpty) ...[
            pw.Text("Terms & Conditions:",
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: terms
                  .map((term) => pw.Text("• $term",
                      style: const pw.TextStyle(fontSize: 9)))
                  .toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // PDF Table Helper (Pehle Jaisa)
  pw.Widget _buildPdfTable(List<Map<String, dynamic>> products,
      List<Map<String, dynamic>> charges, String currency) {
    final headers = ['Product', 'Qty', 'Price', 'Tax %', 'Total'];
    final data = products.map((p) {
      double pr = p['price'] ?? 0.0;
      int q = p['quantity'] ?? 1;
      double t = p['tax'] ?? 0.0;
      double tot = (pr * q) * (1 + t / 100);
      return [
        p['name'],
        q.toString(),
        pr.toStringAsFixed(2),
        t.toStringAsFixed(2),
        tot.toStringAsFixed(2)
      ];
    }).toList();
    for (var o in charges) {
      data.add([
        o['label'],
        '1',
        (o['amount'] ?? 0.0).toStringAsFixed(2),
        o['isTaxable'] ? '18.00' : '0.00',
        (o['amount'] ?? 0.0).toStringAsFixed(2)
      ]);
    }
    return pw.Table.fromTextArray(
      headers: headers, data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9), // Smaller font
      cellStyle: const pw.TextStyle(fontSize: 9), // Smaller font
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(
          color: PdfColors.grey600, width: 0.5), // Lighter border
      columnWidths: {
        // Adjust column widths if needed
        0: const pw.FlexColumnWidth(3), // Description wider
        1: const pw.FixedColumnWidth(30), // Qty narrow
        2: const pw.FixedColumnWidth(60), // Price
        3: const pw.FixedColumnWidth(40), // Tax narrow
        4: const pw.FixedColumnWidth(70), // Total
      },
    );
  }

  // --- UI Build (Pehle Jaisa) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuotation != null
            ? "Edit Quotation"
            : "Make Quotation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        children: [
          _buildTopInfo(),
          const Divider(),
          _buildSectionCard(
            title: "TO (CUSTOMER)",
            details: selectedCustomer?['name'],
            onTap: _selectCustomer,
          ),
          _buildSectionCard(
            title: "PRODUCTS",
            details: selectedProducts.isEmpty
                ? null
                : "${selectedProducts.length} items added",
            onTap: _selectProduct,
          ),
          _buildSectionCard(
            title: "OTHER CHARGE",
            details: _otherCharges.isEmpty
                ? null
                : "${_otherCharges.length} charges added",
            onTap: _addOtherCharge,
          ),
          _buildSectionCard(
            title: "TERMS & CONDITIONS",
            details: selectedTerms.isEmpty
                ? null
                : "${selectedTerms.length} terms selected",
            onTap: _selectTerms,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- Helper Widgets (Pehle Jaisay) ---
  Widget _buildTopInfo() {
    /* ... Pehle Jaisa ... */
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Quotation Date", style: TextStyle(color: Colors.grey[600])),
              Text(DateFormat('dd/MM/yyyy').format(quotationDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("Quotation No", style: TextStyle(color: Colors.grey[600])),
              Text(quotationNo,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _otherInfoController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              labelText: "Other Info:",
              hintText: "e.g., Valid for 7 days",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required VoidCallback onTap, String? details}) {
    /* ... Pehle Jaisa ... */
    return GestureDetector(
        onTap: onTap,
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        if (details != null && details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(details,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 15)),
                        ]
                      ])),
                  const Icon(Icons.add_circle, color: Colors.black45, size: 28),
                ])));
  }

  Widget _buildBottomBar() {
    /* ... Pehle Jaisa ... */
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total TAX",
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                    Text("$currency${totalTax.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Amount Due",
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                    Text("$currency${totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _generateAndSaveQuotation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Generate",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
