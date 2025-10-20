// lib/pages/receipt_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ YEH LINE ERROR KO THEEK KAREGI
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_manager_app/utils/receipt_helper.dart'; // Helper import
import 'package:business_manager_app/pages/customer_page.dart'; // Customer page import

// PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Template Imports
import 'package:business_manager_app/utils/business_helper.dart'; // BusinessInfo ke liye
import 'package:business_manager_app/utils/pdf_templates.dart'; // Templates ke liye

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  // Data and Controllers (Pehle Jaisay)
  final _formKey = GlobalKey<FormState>();
  String receiptNumber = "1001";
  DateTime paymentDate = DateTime.now();
  Map<String, dynamic>? selectedCustomer;
  String paymentMode = 'Cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _generateReceiptNo();
  }

  // --- Functions (Load Currency, Generate No, Selectors, Save Receipt [old version]) ---
  // Yeh functions pehle jaisay hi hain
  Future<void> _loadCurrency() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _generateReceiptNo() async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    int lastNo = prefs.getInt('lastReceiptNo') ?? 1000;
    if (mounted) {
      setState(() {
        receiptNumber = (lastNo + 1).toString();
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

  Future<void> _selectDate(BuildContext context) async {
    /* ... Pehle Jaisa ... */
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != paymentDate) {
      setState(() {
        paymentDate = picked;
      });
    }
  }

  // UPDATED: Ab yeh function PDF bhi generate karega
  Future<void> _saveReceiptAndGeneratePdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer")),
      );
      return;
    }

    final newReceipt = {
      'receiptNo': receiptNumber,
      'date': DateFormat('yyyy-MM-dd').format(paymentDate),
      'customerName': selectedCustomer?['name'] ?? 'N/A',
      'customerDetails': selectedCustomer,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'paymentMode': paymentMode,
      'notes': _notesController.text,
      'currency': currency,
    };

    // 1. Save using helper
    await ReceiptHelper.saveReceipt(newReceipt);

    // 2. Save new receipt number
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastReceiptNo', int.parse(receiptNumber));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Receipt saved! Generating PDF...")),
    );

    // 3. NAYA STEP: PDF banayen aur dikhayen
    await _generateAndShowPdf(newReceipt);

    // 4. Form reset karain
    setState(() {
      receiptNumber = (int.parse(receiptNumber) + 1).toString();
      selectedCustomer = null;
      _amountController.clear();
      _notesController.clear();
      paymentMode = 'Cash';
      paymentDate = DateTime.now();
    });
  }

  // --- PDF Generation (UPDATED TO USE TEMPLATES) ---
  Future<void> _generateAndShowPdf(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header & Footer
    final headerWidget = await buildPdfHeader(businessInfo, "Payment Receipt");
    // final footerWidget = await buildPdfFooter(businessInfo); // Optional

    // 3. Prepare Receipt Data
    final amount = (receipt['amount'] as double).toStringAsFixed(2);
    final pdfCurrency = businessInfo.currency;
    final notes = receipt['notes'] ?? '';
    final customerName = receipt['customerName'] ?? 'N/A';
    // ✅ Yahan DateFormat ab kaam karega
    final paymentDateFormatted = DateFormat('dd/MM/yyyy').format(paymentDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 4. Use Header Template
              headerWidget,
              pw.SizedBox(height: 30),

              // 5. Receipt Specific Content
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Receipt No: #${receipt['receiptNo']}"),
                    pw.Text("Date: $paymentDateFormatted"),
                  ]),
              pw.SizedBox(height: 20),
              _buildPdfRow("Received From:", customerName),
              _buildPdfRow("Payment Mode:", receipt['paymentMode']),
              if (notes.isNotEmpty) _buildPdfRow("Notes:", notes),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Total Amount
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Text(
                    "Amount Received: $pdfCurrency $amount",
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Spacer(), // Push footer (if any) or bottom content down

              // 6. Optional: Use Footer Template
              // footerWidget,
            ],
          );
        },
      ),
    );

    // PDF ko screen par dikhayen
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // PDF Row Helper (Pehle Jaisa)
  pw.Widget _buildPdfRow(String label, String value) {
    /* ... Pehle Jaisa ... */
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Build (Pehle Jaisa) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Receipt'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                /* Receipt No & Date */ mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Receipt No: #$receiptNumber",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd/MM/yyyy').format(paymentDate)),
                    onPressed: () => _selectDate(context),
                  ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedCustomer != null
                            ? "Customer: ${selectedCustomer!['name']}"
                            : "Received From (Customer)",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.person_add),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                /* Amount */ controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Amount Received * ($currency)",
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                /* Payment Mode */ value: paymentMode,
                decoration: const InputDecoration(
                  labelText: "Payment Mode",
                  prefixIcon: Icon(Icons.payment),
                ),
                items: ['Cash', 'Bank Transfer', 'Cheque', 'Online']
                    .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => paymentMode = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                /* Notes */ controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Notes (Optional)",
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              Center(
                /* Save Button */ child: ElevatedButton.icon(
                  onPressed: _saveReceiptAndGeneratePdf,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Receipt & Generate PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
