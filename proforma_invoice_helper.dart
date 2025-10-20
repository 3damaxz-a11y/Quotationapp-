// lib/utils/proforma_invoice_helper.dart

import 'dart:convert'; // ✅ YEH LINE AB THEEK KAR DI GAYI HAI (dot ke bajaye colon)
import 'package:shared_preferences/shared_preferences.dart';

class ProformaInvoiceHelper {
  static const String _piKey = 'proforma_invoices';

  // 🔹 Save Proforma Invoice
  static Future<void> saveProformaInvoice(Map<String, dynamic> pi) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_piKey);
    List<Map<String, dynamic>> pis = [];
    if (existingData != null) {
      pis = List<Map<String, dynamic>>.from(json.decode(existingData));
    }
    pis.add(pi);
    await prefs.setString(_piKey, json.encode(pis));
  }

  // 🔹 Load all Proforma Invoices
  static Future<List<Map<String, dynamic>>> getProformaInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_piKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }
}
