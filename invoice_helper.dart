import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceHelper {
  static const String _invoiceKey = 'invoices';

  // 🔹 Save invoice
  static Future<void> saveInvoice(Map<String, dynamic> invoice) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing invoices
    final String? existingData = prefs.getString(_invoiceKey);
    List<Map<String, dynamic>> invoices = [];

    if (existingData != null) {
      invoices = List<Map<String, dynamic>>.from(json.decode(existingData));
    }

    // Add new invoice
    invoices.add(invoice);

    // Save back to SharedPreferences
    await prefs.setString(_invoiceKey, json.encode(invoices));
  }

  // 🔹 Load all invoices
  static Future<List<Map<String, dynamic>>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_invoiceKey);

    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  // 🔹 Clear all invoices (optional for testing)
  static Future<void> clearInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_invoiceKey);
  }
}
