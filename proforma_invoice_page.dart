// lib/pages/proforma_invoice_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Page Imports
import 'package:business_manager_app/pages/customer_page.dart';
import 'package:business_manager_app/pages/add_product_page.dart';
import 'package:business_manager_app/pages/add_to_quotation_page.dart';
import 'package:business_manager_app/pages/terms_selection_page.dart';
import 'package:business_manager_app/utils/proforma_invoice_helper.dart';

// PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ✅ Naye Template Imports
import 'package:business_manager_app/utils/business_helper.dart'; // BusinessInfo ke liye
import 'package:business_manager_app/utils/pdf_templates.dart'; // Templates ke liye

class ProformaInvoicePage extends StatefulWidget {
  const ProformaInvoicePage({super.key});

  @override
  State<ProformaInvoicePage> createState() => _ProformaInvoicePageState();
}

class _ProformaInvoicePageState extends State<ProformaInvoicePage> {
  // Data (Pehle Jaisa)
  Map<String, dynamic>? selectedCustomer;
  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> _otherCharges = [];
  List<String> selectedTerms = [];
  final TextEditingController _otherInfoController = TextEditingController();

  // Info & Totals (Pehle Jaisay)
  String proformaNo = "PI-1001";
  DateTime proformaDate = DateTime.now();
  double totalAmount = 0.0;
  double totalTax = 0.0;
  String currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _generateProformaNo();
  }

  @override
  void dispose() {
    _otherInfoController.dispose();
    super.dispose();
  }

  // --- Functions (Load Currency, Generate No, Selectors, Add Product/Charge/Terms, Calculate Totals, Save Proforma [old version]) ---
  // Yeh functions pehle jaisay hi hain
  Future<void> _loadCurrency() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _generateProformaNo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastProformaNo') ?? 1000;
    if (mounted) {
      setState(() {
        proformaNo = "PI-${lastNo + 1}";
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(children: [
          const Text("Select Product",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                                          AddToQuotationPage(product: p)));
                              if (updatedProduct != null)
                                _addOrIncrementProduct(updatedProduct);
                              Navigator.pop(context);
                            }));
                  })),
          ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final np = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddProductPage()));
                if (np != null) _addOrIncrementProduct(np);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add New Product")),
        ]),
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
        final e = selectedProducts[existingIndex];
        e['quantity'] = (e['quantity'] ?? 1) + qty;
        e['price'] = price;
        e['tax'] = tax;
        _calculateTotals();
      });
    } else {
      final ne = Map<String, dynamic>.from(product);
      ne['price'] = price;
      ne['tax'] = tax;
      ne['quantity'] = qty;
      setState(() {
        selectedProducts.add(ne);
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
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24),
            child: StatefulBuilder(
                builder: (context, setModalState) =>
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text("Other Charge Info"),
                      TextField(
                          controller: TextEditingController(text: label),
                          onChanged: (v) => label = v),
                      TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (v) => amount = v),
                      Row(children: [
                        const Text("Taxable?"),
                        Checkbox(
                            value: isTaxable,
                            onChanged: (val) =>
                                setModalState(() => isTaxable = val ?? false))
                      ]),
                      ElevatedButton(
                          onPressed: () {
                            if (amount.isNotEmpty) {
                              setState(() {
                                _otherCharges.add({
                                  'label': label,
                                  'amount': double.tryParse(amount) ?? 0.0,
                                  'isTaxable': isTaxable
                                });
                                _calculateTotals();
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Save")),
                      const SizedBox(height: 20)
                    ]))));
  }

  Future<void> _selectTerms() async {
    /* ... Pehle Jaisa ... */
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const TermsSelectionPage()));
    if (result != null && result is List<String>) {
      setState(() => selectedTerms = result);
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
      if (o['isTaxable'] == true) tax += (o['amount'] ?? 0) * 0.18;
    }
    setState(() {
      totalTax = tax;
      totalAmount = total + tax;
    });
  }

  Future<void> _saveProforma() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    final newPI = {
      'proformaNo': proformaNo,
      'date': DateFormat('yyyy-MM-dd').format(proformaDate),
      'customerName': selectedCustomer?['name'] ?? 'N/A',
      'customerDetails': selectedCustomer,
      'items': selectedProducts,
      'otherCharges': _otherCharges,
      'terms': selectedTerms,
      'otherInfo': _otherInfoController.text,
      'subtotal': totalAmount - totalTax,
      'tax': totalTax,
      'total': totalAmount,
      'currency': currency,
    };
    await ProformaInvoiceHelper.saveProformaInvoice(newPI);
    await prefs.setInt('lastProformaNo', int.parse(proformaNo.split('-')[1]));
  }

  Future<void> _saveAndGenerateProforma() async {
    /* ... Pehle Jaisa ... */
    if (selectedCustomer == null || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select customer and add products")));
      return;
    }
    await _saveProforma();
    await _generatePdf();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("✅ Proforma Invoice saved & PDF generated!")),
    );
    setState(() {
      proformaNo = "PI-${int.parse(proformaNo.split('-')[1]) + 1}";
      selectedCustomer = null;
      selectedProducts.clear();
      _otherCharges.clear();
      selectedTerms.clear();
      _otherInfoController.clear();
      _calculateTotals();
    });
  }

  // --- PDF Generation (✅ UPDATED TO USE TEMPLATES) ---

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header & Footer
    final headerWidget =
        await buildPdfHeader(businessInfo, "Proforma Invoice"); // Title change
    final footerWidget = await buildPdfFooter(businessInfo);

    // 3. Prepare Proforma Data
    final customer = selectedCustomer ?? {};
    final items = selectedProducts;
    final charges = _otherCharges;
    final terms = selectedTerms;
    final otherInfo = _otherInfoController.text;
    final pdfCurrency = businessInfo.currency;
    final String piDate = DateFormat('dd/MM/yyyy').format(proformaDate);
    final double subtotal = totalAmount - totalTax;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          // Customer & Proforma Details
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
                    /* Proforma Details */ crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Proforma No: $proformaNo"),
                      pw.Text("Date: $piDate"),
                      if (otherInfo.isNotEmpty) pw.Text("Info: $otherInfo"),
                    ])
              ]),
          pw.SizedBox(height: 25),
          // Items Table
          _buildPdfTable(items, charges, pdfCurrency), // Reuse Helper
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
                            "Total Tax: $pdfCurrency ${totalTax.toStringAsFixed(2)}"),
                        pw.Divider(height: 5),
                        pw.Text(
                            "Total Amount: $pdfCurrency ${totalAmount.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ]))),
          pw.SizedBox(height: 30),
          // Terms
          if (terms.isNotEmpty) ...[
            pw.Text("Terms & Conditions:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: terms.map((term) => pw.Text("• $term")).toList()),
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
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(30),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(70),
      },
    );
  }

  // --- UI Build (Pehle Jaisa) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Proforma Invoice"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
      ), // Style updated
      backgroundColor: Colors.white, // Style updated
      bottomNavigationBar: _buildBottomBar(), // Style updated
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildTopInfo(), const Divider(), // Style updated
          _buildSectionCard(
            title: "TO (CUSTOMER)",
            details: selectedCustomer?['name'],
            onTap: _selectCustomer,
          ), // Style updated
          _buildSectionCard(
            title: "PRODUCTS",
            details: selectedProducts.isEmpty
                ? null
                : "${selectedProducts.length} items added",
            onTap: _selectProduct,
          ), // Style updated
          _buildSectionCard(
            title: "OTHER CHARGE",
            details: _otherCharges.isEmpty
                ? null
                : "${_otherCharges.length} charges added",
            onTap: _addOtherCharge,
          ), // Style updated
          _buildSectionCard(
            title: "TERMS & CONDITIONS",
            details: selectedTerms.isEmpty
                ? null
                : "${selectedTerms.length} terms selected",
            onTap: _selectTerms,
          ), // Style updated
        ],
      ),
    );
  }

  // --- Helper Widgets (Pehle Jaisay) ---
  Widget _buildTopInfo() {
    /* ... Pehle Jaisa (Quotation Jaisa) ... */
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Proforma Date", style: TextStyle(color: Colors.grey[600])),
              Text(DateFormat('dd/MM/yyyy').format(proformaDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("Proforma No", style: TextStyle(color: Colors.grey[600])),
              Text(proformaNo,
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
                  hintText: "e.g., Validity",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none))),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required VoidCallback onTap, String? details}) {
    /* ... Pehle Jaisa (Quotation Jaisa) ... */
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
    /* ... Pehle Jaisa (Quotation Jaisa) ... */
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
            onPressed: _saveAndGenerateProforma,
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
