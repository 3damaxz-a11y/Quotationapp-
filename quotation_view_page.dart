// lib/pages/quotation_view_page.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'quotation_page.dart'; // For editing

// Naye Imports
import 'package:business_manager_app/utils/business_helper.dart';
import 'package:business_manager_app/utils/pdf_templates.dart'; // Keep this for PDF generation

class QuotationViewPage extends StatefulWidget {
  final Map<String, dynamic> quotation;
  final int index;

  const QuotationViewPage({
    super.key,
    required this.quotation,
    required this.index,
  });

  @override
  State<QuotationViewPage> createState() => _QuotationViewPageState();
}

class _QuotationViewPageState extends State<QuotationViewPage> {
  late Map<String, dynamic> quotation;
  Map<String, String> businessInfo = {};
  File? signatureImage;
  File? logoImage;

  @override
  void initState() {
    super.initState();
    quotation = widget.quotation;
    _loadBusinessInfo();
  }

  // Business Info Load Function (Pehle Jaisa)
  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();
    File? tempLogoFile;
    File? tempSignatureFile;
    final logoPath = prefs.getString('logoImagePath');
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        tempLogoFile = file;
      } else {
        print("Logo file not found: $logoPath");
      }
    }
    final signaturePath = prefs.getString('signatureImagePath');
    if (signaturePath != null && signaturePath.isNotEmpty) {
      final file = File(signaturePath);
      if (await file.exists()) {
        tempSignatureFile = file;
      } else {
        print("Signature file not found: $signaturePath");
      }
    }
    if (mounted) {
      setState(() {
        businessInfo = {
          'name': prefs.getString('businessName') ?? '',
          'phone': prefs.getString('phone') ?? '',
          'email': prefs.getString('email') ?? '',
          'address':
              "${prefs.getString('address1') ?? ''} ${prefs.getString('address2') ?? ''} ${prefs.getString('address3') ?? ''}"
                  .trim(),
          'bankInfo': prefs.getString('bankInfo') ?? '',
        };
        logoImage = tempLogoFile;
        signatureImage = tempSignatureFile;
      });
    }
  }

  // --- PDF Generation (Using Templates - Keep this) ---
  Future<Uint8List> _generatePdfData() async {
    // (PDF ka code pehle jaisa hi hai)
    final pdf = pw.Document();
    final businessInfoData = await BusinessHelper.getBusinessInfo();
    final headerWidget = await buildPdfHeader(businessInfoData, "Quotation");
    final footerWidget = await buildPdfFooter(businessInfoData);
    final customer = quotation['customer'] ?? {};
    final products =
        List<Map<String, dynamic>>.from(quotation['products'] ?? []);
    final otherCharges =
        List<Map<String, dynamic>>.from(quotation['otherCharges'] ?? []);
    final terms = List<String>.from(quotation['terms'] ?? []);
    final currency = businessInfoData.currency;
    final totalTax = (quotation['totalTax'] ?? 0.0);
    final totalAmount = (quotation['totalAmount'] ?? 0.0);
    final otherInfo = quotation['otherInfo'] ?? '';
    final qDate = quotation['date'] ?? '-';
    final qNumber = quotation['quotationNumber'] ?? '-';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          pw.Row(/* Customer/Quote Details */),
          pw.SizedBox(height: 25),
          _buildPdfTableHelper(products, otherCharges, currency),
          pw.SizedBox(height: 20),
          pw.Row(/* Totals */),
          pw.SizedBox(height: 30),
          if (terms.isNotEmpty) ...[/* Terms */],
        ],
      ),
    );
    return pdf.save();
  }

  // PDF Table Helper (Keep this)
  pw.Widget _buildPdfTableHelper(List<Map<String, dynamic>> products,
      List<Map<String, dynamic>> charges, String currency) {
    // (Yeh function pehle jaisa hi hai)
    final headers = ['#', 'DESCRIPTION', 'QTY', 'PRICE', 'TOTAL'];
    int i = 1;
    final data = products.map((p) {
      double price = p['price'] ?? 0.0;
      int qty = p['quantity'] ?? 1;
      double total = price * qty;
      return [
        (i++).toString(),
        p['name'] ?? '',
        qty.toString(),
        "$currency ${price.toStringAsFixed(2)}",
        "$currency ${total.toStringAsFixed(2)}"
      ];
    }).toList();
    for (var o in charges) {
      data.add([
        '',
        o['label'],
        '1',
        "$currency ${(o['amount'] ?? 0.0).toStringAsFixed(2)}",
        "$currency ${(o['amount'] ?? 0.0).toStringAsFixed(2)}"
      ]);
    }
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerAlignment: pw.Alignment.center,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(30),
        3: const pw.FixedColumnWidth(65),
        4: const pw.FixedColumnWidth(65),
      },
    );
  }

  // --- Actions (Keep these) ---
  Future<void> _editQuotation() async {
    /* ... */
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationPage(
          existingQuotation: quotation,
          editIndex: widget.index,
        ),
      ),
    );
    if (result == true) {
      await _reloadData();
    }
  }

  Future<void> _sharePdf() async {
    /* ... */
    try {
      final pdfData = await _generatePdfData();
      final tempDir = await getTemporaryDirectory();
      final file =
          File("${tempDir.path}/quotation_${quotation['quotationNumber']}.pdf");
      await file.writeAsBytes(pdfData);
      await Share.shareXFiles([XFile(file.path)],
          text: "Quotation #${quotation['quotationNumber']}");
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing PDF: $e")),
        );
    }
  }

  Future<void> _deleteQuotation() async {
    /* ... */
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Quotation"),
            content: const Text("Are you sure?"),
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
    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      List<String> quotations = prefs.getStringList('quotations') ?? [];
      String qNumberToDelete = quotation['quotationNumber'] ?? '';
      int indexToDelete = quotations.indexWhere((qJson) =>
          (jsonDecode(qJson)['quotationNumber'] ?? '') == qNumberToDelete);
      if (indexToDelete != -1) {
        quotations.removeAt(indexToDelete);
        await prefs.setStringList('quotations', quotations);
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  Future<void> _reloadData() async {
    /* ... */
    final prefs = await SharedPreferences.getInstance();
    List<String> quotations = prefs.getStringList('quotations') ?? [];
    String currentQNumber = widget.quotation['quotationNumber'] ?? '';
    int currentIndex = quotations.indexWhere((qJson) =>
        (jsonDecode(qJson)['quotationNumber'] ?? '') == currentQNumber);
    if (currentIndex != -1 && currentIndex < quotations.length) {
      if (mounted) {
        setState(() {
          quotation = jsonDecode(quotations[currentIndex]);
        });
        await _loadBusinessInfo();
      }
    } else {
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _duplicateQuotation() {
    /* ... */ ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Duplicate Coming Soon")));
  }

  void _convertToInvoice() {
    /* ... */ ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Convert to Invoice Coming Soon")));
  }

  void _updateStatus() {
    /* ... */ ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update Status Coming Soon")));
  }

  // --- UI Build (Detailed Layout - Using ListView Directly) ---
  @override
  Widget build(BuildContext context) {
    final q = quotation;
    final customer = q['customer'] ?? {};
    final products = List<Map<String, dynamic>>.from(q['products'] ?? []);
    final otherCharges =
        List<Map<String, dynamic>>.from(q['otherCharges'] ?? []);
    final terms = List<String>.from(q['terms'] ?? []);
    final currency = q['currency'] ?? businessInfo['currency'] ?? 'Rs';
    final totalTax = (q['totalTax'] ?? 0.0);
    final totalAmount = (q['totalAmount'] ?? 0.0);
    final otherInfo = q['otherInfo'] ?? '';
    String formattedDate = q['date'] ?? '-';
    try {
      if (q['date'] != null) {
        formattedDate =
            DateFormat('dd/MM/yyyy').format(DateTime.parse(q['date']));
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text("Quotation Detail #${q['quotationNumber']}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: "Share",
            onPressed: _sharePdf,
          ),
        ],
      ),
      backgroundColor: Colors.grey[200], // Background paper color
      bottomNavigationBar: _buildBottomActionBar(),

      // ✅ Use ListView DIRECTLY for the body
      body: SafeArea(
        child: ListView(
          // Changed SingleChildScrollView to ListView
          padding: const EdgeInsets.all(16), // Padding around the paper
          children: [
            // White Paper Container - ListView ka direct child
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                // Content inside the paper
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (logoImage != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Image.file(logoImage!,
                            width: 80,
                            height: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image, size: 40)),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(businessInfo['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (businessInfo['phone']?.isNotEmpty ?? false)
                            Text(businessInfo['phone']!,
                                style: const TextStyle(fontSize: 11)),
                          if (businessInfo['email']?.isNotEmpty ?? false)
                            Text(businessInfo['email']!,
                                style: const TextStyle(fontSize: 11)),
                          if (businessInfo['address']?.isNotEmpty ?? false)
                            Text(businessInfo['address']!,
                                style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const Text("Quotation",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(thickness: 1, height: 20),

                  // --- Customer & Quote Info ---
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("To,",
                              style: TextStyle(color: Colors.grey)),
                          Text(customer['name'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (customer['company']?.isNotEmpty ?? false)
                            Text(customer['company']!),
                          if (customer['phone']?.isNotEmpty ?? false)
                            Text("Ph: ${customer['phone']!}"),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Quotation#: ${q['quotationNumber'] ?? '-'}"),
                          Text("Date: $formattedDate"),
                          if (otherInfo.isNotEmpty)
                            Text(otherInfo, textAlign: TextAlign.right),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text("Dear Sir/Mam,", style: TextStyle(fontSize: 12)),
                  const Text("Thank you...", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 15),

                  // --- Items Table ---
                  _buildItemTable(products, otherCharges, currency),
                  const SizedBox(height: 10),

                  // --- Totals ---
                  Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildTotalRow("Total Tax:",
                                "$currency ${totalTax.toStringAsFixed(2)}"),
                            const Divider(height: 8),
                            _buildTotalRow("Amount Due:",
                                "$currency ${totalAmount.toStringAsFixed(2)}",
                                isBold: true, fontSize: 16),
                          ],
                        ),
                      )),
                  const SizedBox(height: 15),

                  const Text("We hope you find our offer...",
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 20),

                  // --- Signature ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("For, ${businessInfo['name'] ?? ''}"),
                          const SizedBox(height: 10),
                          if (signatureImage != null)
                            Image.file(signatureImage!,
                                height: 35,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.broken_image, size: 20)),
                          SizedBox(height: signatureImage != null ? 5 : 15),
                          Container(height: 1, color: Colors.black),
                          const SizedBox(height: 2),
                          const Text("AUTHORIZED SIGNATURE",
                              style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Bank Details ---
                  if (businessInfo['bankInfo']?.isNotEmpty ?? false) ...[
                    const Text("Bank Details / Payment Instructions:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(businessInfo['bankInfo']!),
                    const SizedBox(height: 15),
                  ],

                  // --- Terms ---
                  if (terms.isNotEmpty) ...[
                    const Text("Terms & Conditions:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    ...terms
                        .map((term) => Text("• $term",
                            style: const TextStyle(fontSize: 11)))
                        .toList(),
                    const SizedBox(height: 15),
                  ],

                  // --- Footer ---
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Generated Via Business Manager App",
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text("Page 1 of 1", style: TextStyle(fontSize: 10)),
                    ],
                  )
                ],
              ),
            ) // End White Paper Container
          ],
        ),
      ),
    );
  }

  // Helper widget for the table inside the app UI
  Widget _buildItemTable(List<Map<String, dynamic>> products,
      List<Map<String, dynamic>> charges, String currency) {
    // (Yeh function pehle jaisa hi hai)
    List<DataRow> rows = [];
    int i = 1;
    for (var p in products) {
      double price = p['price'] ?? 0.0;
      int qty = p['quantity'] ?? 1;
      double total = price * qty;
      rows.add(DataRow(cells: [
        DataCell(Text((i++).toString())),
        DataCell(Text(p['name'] ?? '')),
        DataCell(Text(qty.toString())),
        DataCell(Text("$currency ${price.toStringAsFixed(2)}")),
        DataCell(Text("$currency ${total.toStringAsFixed(2)}")),
      ]));
    }
    for (var o in charges) {
      double amount = o['amount'] ?? 0.0;
      rows.add(DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text(o['label'] ?? '')),
        DataCell(Text('1')),
        DataCell(Text("$currency ${amount.toStringAsFixed(2)}")),
        DataCell(Text("$currency ${amount.toStringAsFixed(2)}")),
      ]));
    }
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: 15,
            headingRowHeight: 30,
            dataRowMinHeight: 30,
            dataRowMaxHeight: 40,
            headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
            dataTextStyle: const TextStyle(fontSize: 10, color: Colors.black87),
            border: TableBorder.all(color: Colors.black, width: 0.5),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('DESCRIPTION')),
              DataColumn(label: Text('QTY')),
              DataColumn(label: Text('PRICE')),
              DataColumn(label: Text('TOTAL')),
            ],
            rows: rows,
          ),
        ),
      );
    });
  }

  // Helper for Total Rows (Build method se bahar)
  Widget _buildTotalRow(String label, String value,
      {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 10),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // Helper widget for the bottom action bar (Pehle Jaisa)
  Widget _buildBottomActionBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
              Icons.copy_outlined, "Duplicate", _duplicateQuotation),
          _buildActionButton(Icons.edit_outlined, "Edit", _editQuotation),
          _buildActionButton(
              Icons.receipt_long_outlined, "Invoice", _convertToInvoice),
          _buildActionButton(Icons.share_outlined, "Share", _sharePdf),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteQuotation();
              } else if (value == 'status') {
                _updateStatus();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete')),
              ),
              const PopupMenuItem<String>(
                value: 'status',
                child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Status')),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_horiz_outlined, color: Colors.black54),
                  SizedBox(height: 4),
                  Text("More",
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for individual action buttons (Pehle Jaisa)
  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
