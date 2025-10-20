// lib/pages/customer_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_customer_page.dart';

class CustomerPage extends StatefulWidget {
  final bool selectMode;
  const CustomerPage({Key? key, this.selectMode = false}) : super(key: key);

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  List<Map<String, dynamic>> allCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = []; // Search ke liye
  bool loading = true;
  final TextEditingController _searchController =
      TextEditingController(); // Search ke liye

  @override
  void initState() {
    super.initState();
    loadCustomers();

    // Search controller ko sunnay ke liye
    _searchController.addListener(() {
      filterCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search ka logic
  void filterCustomers() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredCustomers = List.from(allCustomers);
      });
    } else {
      setState(() {
        filteredCustomers = allCustomers.where((c) {
          final name = c['name']?.toString().toLowerCase() ?? '';
          final company = c['company']?.toString().toLowerCase() ?? '';
          return name.contains(query) || company.contains(query);
        }).toList();
      });
    }
  }

  Future<void> loadCustomers() async {
    try {
      setState(() => loading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> storedList = prefs.getStringList('customers') ?? [];

      allCustomers = storedList
          .map((e) {
            try {
              return jsonDecode(e) as Map<String, dynamic>;
            } catch (error) {
              return <String, dynamic>{};
            }
          })
          .where((e) => e.isNotEmpty)
          .toList();

      // Shuru mein, dono list barabar hongi
      filteredCustomers = List.from(allCustomers);

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        allCustomers = [];
        filteredCustomers = [];
        loading = false;
      });
    }
  }

  Future<void> saveCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encoded =
        allCustomers.map((e) => jsonEncode(e)).toList().cast<String>();
    await prefs.setStringList('customers', encoded);
  }

  Future<void> openAddCustomer(
      {Map<String, dynamic>? existing, int? index}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(
          existingCustomer: existing,
        ),
      ),
    );

    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        if (index != null) {
          // Edit mode
          // Pehle original list (allCustomers) mein find kar ke update karain
          String customerName = existing?['name'] ?? '';
          int originalIndex =
              allCustomers.indexWhere((c) => c['name'] == customerName);
          if (originalIndex != -1) {
            allCustomers[originalIndex] = res;
          }
        } else {
          // Add mode
          allCustomers.add(res);
        }
      });
      await saveCustomers();
      // Dono lists ko refresh karain
      filterCustomers();
    }
  }

  // Delete function (Abhi istemal nahi ho raha, lekin rakha hai)
  void deleteCustomer(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Customer"),
        content: const Text("Are you sure you want to delete this customer?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm) {
      setState(() {
        // Find and remove from original list
        Map<String, dynamic> customerToRemove = filteredCustomers[index];
        allCustomers.removeWhere((c) => c['name'] == customerToRemove['name']);
        // Filter list ko refresh karain
        filterCustomers();
      });
      await saveCustomers();
    }
  }

  // Customer Card ka naya design (Screenshot jaisa)
  Widget customerCard(Map<String, dynamic> c, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          c['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        // Subtitle mein Phone number
        subtitle: Text(
          c['phone'] ?? '', // Company ke bajaye phone
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: widget.selectMode
            ? const Icon(Icons.arrow_forward_ios, size: 14)
            : IconButton(
                // Sirf Edit button
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () => openAddCustomer(existing: c, index: index),
              ),
        onTap: () {
          if (widget.selectMode) {
            Navigator.pop(context, c);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background color change

      // ✅ APPBAR UPDATE KAR DI GAYI HAI
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Select Customer' : 'Customer List'),
        backgroundColor: Colors.black, // ✅ Tabdeeli
        foregroundColor: Colors.white, // ✅ Tabdeeli
        elevation: 1,
        // ✅ Back button khud aa jayega (leading icon)
        // ✅ Hamburger Icon (Screenshot jaisa)
        actions: widget.selectMode
            ? null
            : [IconButton(onPressed: () {}, icon: const Icon(Icons.menu))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name OR Company Name',
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

                // Customer List
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No customers added yet'
                                : 'No customers found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, idx) {
                            return customerCard(filteredCustomers[idx], idx);
                          },
                        ),
                ),
              ],
            ),
      // Naya Floating Action Button (Screenshot jaisa)
      floatingActionButton: widget.selectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openAddCustomer(),
              backgroundColor: Colors.pink[600],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("ADD CUSTOMER",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }
}
