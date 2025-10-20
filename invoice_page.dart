// lib/pages/invoice_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper imports
// import 'package:business_manager_app/utils/business_helper.dart'; // Ab BusinessHelper direct use hoga
import 'package:business_manager_app/utils/invoice_helper.dart';

// Page imports
import 'package:business_manager_app/pages/customer_page.dart';
import 'package:business_manager_app/pages/add_product_page.dart';
import 'package:business_manager_app/pages/add_to_quotation_page.dart';
import 'package:business_manager_app/pages/terms_selection_page.dart';

// PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ✅ Naye Template Imports
import 'package:business_manager_app/utils/business_helper.dart'; // BusinessInfo ke liye
import 'package:business_manager_app/utils/pdf_templates.dart'; // Templates ke liye

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  // Data (Pehle Jaisa)
  Map<String, dynamic>? selectedCustomer;
  List<Map<String, dynamic>> selectedProducts = [];
  List<Map<String, dynamic>> _otherCharges = [];
  List<String> selectedTerms = [];

  // Date (Pehle Jaisa)
  String invoiceNumber = "1001";
  DateTime invoiceDate = DateTime.now();
  DateTime? dueDate;

  // Totals (Pehle Jaisa)
  double totalAmount = 0.0;
  double totalTax = 0.0;
  double paidAmount = 0.0;
  String paymentMode = 'N/A';
  String currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // Load currency first
    _generateInvoiceNo();
  }

  // --- Functions (Load Currency, Generate No, Selectors, Add Product/Charge/Terms/PaidInfo, Calculate Totals, Save Invoice) ---
  // Yeh saare functions bilkul pehle jaisay hi hain, in mein koi tabdeeli nahi
  Future<void> _loadCurrency() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _generateInvoiceNo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastInvoiceNo') ?? 1000;
    setState(() {
      invoiceNumber = (lastNo + 1).toString();
    });
  }

  Future<void> _selectInvoiceDate() async {
    /* ... Pehle Jaisa ... */
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != invoiceDate) {
      setState(() => invoiceDate = picked);
    }
  }

  Future<void> _selectDueDate() async {
    /* ... Pehle Jaisa ... */
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => dueDate = picked);
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
                                AddToQuotationPage(product: p),
                          ),
                        );
                        if (updatedProduct != null) {
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
                      builder: (context) => const AddProductPage()),
                );
                if (newProduct != null) {
                  _addOrIncrementProduct(newProduct);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Add New Product"),
            ),
          ],
        ),
      ),
    );
  }

  void _addOrIncrementProduct(Map<String, dynamic> product) {
    /* ... Pehle Jaisa ... */
    final name = (product['name'] ?? '').toString();
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
      });
    } else {
      final newEntry = Map<String, dynamic>.from(product);
      newEntry['price'] = price;
      newEntry['tax'] = tax;
      newEntry['quantity'] = qty;
      setState(() {
        selectedProducts.add(newEntry);
      });
    }
    _calculateTotals();
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

  Future<void> _addPaidInfo() async {
    /* ... Pehle Jaisa ... */
    TextEditingController amountController = TextEditingController(
        text: paidAmount > 0 ? paidAmount.toString() : '');
    String mode = paymentMode == 'N/A' ? 'Cash' : paymentMode;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Paid Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                    labelText: "Amount Paid", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(
                    labelText: "Payment Mode", border: OutlineInputBorder()),
                items: ['Cash', 'Bank Transfer', 'Cheque', 'Online']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => mode = value);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    paidAmount = double.tryParse(amountController.text) ?? 0.0;
                    paymentMode = mode;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45)),
                child: const Text("Save Paid Info"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _saveInvoice() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    final invoice = {
      'invoiceNo': invoiceNumber,
      'invoiceDate': DateFormat('yyyy-MM-dd').format(invoiceDate),
      'dueDate':
          dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : null,
      'poNo': '-',
      'otherInfo': '',
      'customer': selectedCustomer?['name'] ?? 'N/A',
      'customerDetails': selectedCustomer,
      'items': selectedProducts,
      'otherCharges': _otherCharges,
      'terms': selectedTerms,
      'subtotal': totalAmount - totalTax,
      'tax': totalTax,
      'total': totalAmount,
      'paidAmount': paidAmount,
      'paymentMode': paymentMode,
      'currency': currency,
    };
    await InvoiceHelper.saveInvoice(invoice);
    await prefs.setInt('lastInvoiceNo', int.parse(invoiceNumber));
  }

  Future<void> _saveAndGenerateInvoice() async {
    /* ... Pehle Jaisa ... */
    if (selectedCustomer == null || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select customer and add products")),
      );
      return;
    }
    await _saveInvoice();
    await _generatePDF();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Invoice saved & PDF generated!")),
    );
    setState(() {
      invoiceNumber = (int.parse(invoiceNumber) + 1).toString();
      selectedCustomer = null;
      selectedProducts.clear();
      _otherCharges.clear();
      selectedTerms.clear();
      paidAmount = 0.0;
      paymentMode = 'N/A';
      dueDate = null;
      _calculateTotals();
    });
  }

  // --- PDF Generation (✅ UPDATED TO USE TEMPLATES) ---

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header & Footer
    final headerWidget = await buildPdfHeader(businessInfo, "Invoice");
    final footerWidget = await buildPdfFooter(businessInfo);

    // 3. Prepare Invoice Data
    final customer = selectedCustomer ?? {};
    final items = selectedProducts;
    final charges = _otherCharges;
    final terms = selectedTerms;
    final String invDate = DateFormat('dd/MM/yyyy').format(invoiceDate);
    final String? dueDt =
        dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : null;
    final double subtotal = totalAmount - totalTax;
    final double amountDue = totalAmount - paidAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          // Customer & Invoice Details
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    /* Customer */ crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("BILL TO:",
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
                    /* Invoice Details */ crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Invoice No: $invoiceNumber"),
                      pw.Text("Date: $invDate"),
                      if (dueDt != null) pw.Text("Due Date: $dueDt"),
                    ])
              ]),
          pw.SizedBox(height: 25),
          // Items Table
          _buildPdfTable(items, charges, currency), // Reuse Helper
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
                            "Subtotal: $currency ${subtotal.toStringAsFixed(2)}"),
                        pw.Text(
                            "Total Tax: $currency ${totalTax.toStringAsFixed(2)}"),
                        pw.Divider(height: 5),
                        pw.Text(
                            "Total Amount: $currency ${totalAmount.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        if (paidAmount > 0) ...[
                          pw.Text(
                              "Amount Paid: $currency ${paidAmount.toStringAsFixed(2)}"),
                          pw.Text(
                              "Amount Due: $currency ${amountDue.toStringAsFixed(2)}",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 18,
                                  color: PdfColors.red)),
                        ]
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
        title: const Text("Make Invoice"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildTopInfo(),
          const Divider(),
          _buildSectionCard(
            title: "BILL TO (CUSTOMER)",
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
          _buildSectionCard(
            title: "PAID INFO",
            details: paidAmount > 0
                ? "$currency$paidAmount Received"
                : "Add payment details",
            onTap: _addPaidInfo,
          ),
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
            GestureDetector(
              onTap: _selectInvoiceDate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Invoice Date",
                      style: TextStyle(color: Colors.grey[600])),
                  Text(DateFormat('dd/MM/yyyy').format(invoiceDate),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Invoice No", style: TextStyle(color: Colors.grey[600])),
                Text(invoiceNumber,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(
              onTap: _selectDueDate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Due Date", style: TextStyle(color: Colors.grey[600])),
                  Text(
                      dueDate == null
                          ? '-'
                          : DateFormat('dd/MM/yyyy').format(dueDate!),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("PO No", style: TextStyle(color: Colors.grey[600])),
                const Text("-",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          Text(
            "Other Info:",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    final double amountDue = totalAmount - paidAmount;
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
                    Text("$currency${amountDue.toStringAsFixed(2)}",
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
            onPressed: _saveAndGenerateInvoice,
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
