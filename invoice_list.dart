// lib/pages/invoice_list.dart

import 'dart:convert'; // ✅ Naya import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Naya import
import 'package:business_manager_app/utils/invoice_helper.dart';
import 'package:business_manager_app/pages/invoice_view_page.dart';
import 'package:business_manager_app/pages/invoice_page.dart'; // ✅ Naya import

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Map<String, dynamic>> allInvoices = [];
  List<Map<String, dynamic>> filteredInvoices = []; // ✅ Search ke liye
  final TextEditingController _searchController =
      TextEditingController(); // ✅ Search ke liye
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();

    // ✅ Search controller ko sunnay ke liye
    _searchController.addListener(() {
      _filterInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Search ka logic
  void _filterInvoices() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredInvoices = List.from(allInvoices);
      });
    } else {
      setState(() {
        filteredInvoices = allInvoices.where((inv) {
          final number = inv['invoiceNo']?.toString().toLowerCase() ?? '';
          final customer = inv['customer']?.toString().toLowerCase() ?? '';
          return number.contains(query) || customer.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await InvoiceHelper.getInvoices();
    setState(() {
      allInvoices = data.reversed.toList(); // Latest invoice first
      filteredInvoices = List.from(allInvoices);
      _isLoading = false;
    });
  }

  // ✅ Delete ka naya logic
  Future<void> _deleteInvoice(int indexInFilteredList) async {
    // Pehle confirm karain
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Invoice"),
            content:
                const Text("Are you sure you want to delete this invoice?"),
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

    // Find the item to delete
    Map<String, dynamic> itemToDelete = filteredInvoices[indexInFilteredList];
    String itemNumber = itemToDelete['invoiceNo'] ?? '';

    // Load all invoices, remove the one, and save back
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString('invoices');
    if (existingData == null) return;

    List<Map<String, dynamic>> invoices =
        List<Map<String, dynamic>>.from(json.decode(existingData));

    invoices.removeWhere((inv) {
      return (inv['invoiceNo'] ?? '') == itemNumber;
    });

    // Save back
    await prefs.setString('invoices', json.encode(invoices));

    // Refresh data
    await _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // ✅ Naya background
      appBar: AppBar(
        title: const Text("Invoice List"),
        backgroundColor: Colors.black, // ✅ Naya color
        foregroundColor: Colors.white, // ✅ Naya color
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Invoice # or Customer Name',
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
                  child: filteredInvoices.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? "No Invoices Found"
                                : "No results found.",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final inv = filteredInvoices[index];
                            final customer = inv['customer'] ?? 'Unknown';
                            final total =
                                inv['total']?.toStringAsFixed(2) ?? '0.00';
                            final date = inv['invoiceDate'] ?? '';
                            final currency = inv['currency'] ?? 'Rs';

                            // ✅ Naya Card Design
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
                                title: Text("Invoice #${inv['invoiceNo']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle:
                                    Text("Customer: $customer\nDate: $date"),
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
                                    // ✅ Delete Button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      onPressed: () => _deleteInvoice(index),
                                    )
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InvoiceViewPage(invoice: inv),
                                    ),
                                  ).then((_) => _loadInvoices());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      // ✅ Naya Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoicePage()),
          ).then((_) => _loadInvoices());
        },
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD INVOICE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
