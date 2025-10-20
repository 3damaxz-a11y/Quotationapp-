// lib/pages/quotation_list_page.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Page Imports
import 'quotation_view_page.dart';
import 'quotation_page.dart';

// ✅ Naye Imports
import 'package:business_manager_app/utils/business_helper.dart';
import 'package:business_manager_app/utils/pdf_templates.dart';

class QuotationListPage extends StatefulWidget {
  const QuotationListPage({super.key});

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  List<Map<String, dynamic>> allQuotations = [];
  List<Map<String, dynamic>> filteredQuotations = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
    _searchController.addListener(() {
      _filterQuotations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Functions (Load, Filter, Delete) ---
  // Yeh functions pehle jaisay hi hain
  void _filterQuotations() {
    /* ... Pehle Jaisa ... */
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredQuotations = List.from(allQuotations);
      });
    } else {
      setState(() {
        filteredQuotations = allQuotations.where((q) {
          final number = q['quotationNumber']?.toString().toLowerCase() ?? '';
          final customer = q['customerName']?.toString().toLowerCase() ?? '';
          return number.contains(query) || customer.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadQuotations() async {
    /* ... Pehle Jaisa ... */
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('quotations');
    if (stored != null) {
      allQuotations =
          stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      allQuotations.sort((a, b) =>
          (b['quotationNumber'] ?? '0').compareTo(a['quotationNumber'] ?? '0'));
      filteredQuotations = List.from(allQuotations);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteQuotation(int indexInFilteredList) async {
    /* ... Pehle Jaisa ... */
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('quotations') ?? [];
    Map<String, dynamic> itemToDelete = filteredQuotations[indexInFilteredList];
    String itemNumber = itemToDelete['quotationNumber'] ?? '';
    stored.removeWhere((e) {
      final decoded = jsonDecode(e) as Map<String, dynamic>;
      return (decoded['quotationNumber'] ?? '') == itemNumber;
    });
    await prefs.setStringList('quotations', stored);
    await _loadQuotations();
  }

  // --- PDF Generation (✅ UPDATED TO USE TEMPLATES) ---
  Future<void> _generatePDF(Map<String, dynamic> quotation) async {
    final pdf = pw.Document();

    // 1. Load Business Info
    final businessInfo = await BusinessHelper.getBusinessInfo();

    // 2. Build Header
    final headerWidget = await buildPdfHeader(businessInfo, "Quotation");

    // 3. Build Footer
    final footerWidget = await buildPdfFooter(businessInfo);

    // 4. Prepare data specific to THIS quotation from the list
    final customer = quotation['customer'] ?? {};
    final products =
        List<Map<String, dynamic>>.from(quotation['products'] ?? []);
    final otherCharges =
        List<Map<String, dynamic>>.from(quotation['otherCharges'] ?? []);
    final terms = List<String>.from(quotation['terms'] ?? []);
    final otherInfo = quotation['otherInfo'] ?? '';
    final String qDate = quotation['date'] ??
        '-'; // Already formatted as yyyy-MM-dd, convert if needed
    final String qNumber = quotation['quotationNumber'] ?? '-';
    final currency = businessInfo.currency; // Use currency from BusinessInfo
    final totalTax = (quotation['totalTax'] ?? 0.0);
    final totalAmount = (quotation['totalAmount'] ?? 0.0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => headerWidget,
        footer: (context) => footerWidget,
        build: (context) => [
          // Customer Info and Quotation Details
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    /* Customer Info */ crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TO (CUSTOMER):"),
                      pw.Text(customer['name'] ?? '',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      if (customer['company']?.isNotEmpty ?? false)
                        pw.Text(customer['company']!),
                      if (customer['phone']?.isNotEmpty ?? false)
                        pw.Text("Ph: ${customer['phone']!}"),
                    ]),
                pw.Column(
                    /* Quotation Details */ crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Quotation No: $qNumber"),
                      pw.Text("Date: $qDate"),
                      if (otherInfo.isNotEmpty) pw.Text("Info: $otherInfo"),
                    ])
              ]),
          pw.SizedBox(height: 25),
          // Products Table
          _buildPdfTable(
              products, otherCharges, currency), // Reuse table helper
          pw.SizedBox(height: 20),
          // Totals
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("Total Tax: $currency ${totalTax.toStringAsFixed(2)}"),
              pw.Divider(height: 5),
              pw.Text("Amount Due: $currency ${totalAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ])
          ]),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Quotation List"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Quotation # or Customer Name',
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
                  child: filteredQuotations.isEmpty
                      ? Center(
                          child: Text(
                          _searchController.text.isEmpty
                              ? "No quotations found."
                              : "No results found.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredQuotations.length,
                          itemBuilder: (context, index) {
                            final q = filteredQuotations[index];
                            final currency = q['currency'] ?? 'Rs';
                            final total =
                                (q['totalAmount'] ?? 0.0).toStringAsFixed(2);
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                title: Text(
                                  "Quotation #${q['quotationNumber'] ?? ''}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Customer: ${q['customerName'] ?? 'N/A'}\nDate: ${q['date'] ?? 'N/A'}",
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "$currency $total",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontSize: 15),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'pdf') {
                                          _generatePDF(q);
                                        } else if (value == 'delete') {
                                          _deleteQuotation(index);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'pdf',
                                          child: Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf,
                                                  color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Generate PDF'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Colors.grey),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuotationViewPage(
                                        quotation: q,
                                        index: index,
                                      ),
                                    ),
                                  ).then((_) => _loadQuotations());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuotationPage()),
          ).then((_) => _loadQuotations());
        },
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD QUOTATION",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
