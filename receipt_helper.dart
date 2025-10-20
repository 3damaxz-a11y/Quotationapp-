// lib/utils/receipt_helper.dart

import 'dart:convert';
// ✅ YEH LINE AB THEEK KAR DI GAYI HAI (colon ke sath)
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptHelper {
  static const String _receiptKey = 'receipts';

  // 🔹 Save receipt
  static Future<void> saveReceipt(Map<String, dynamic> receipt) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing receipts
    final String? existingData = prefs.getString(_receiptKey);
    List<Map<String, dynamic>> receipts = [];

    if (existingData != null) {
      receipts = List<Map<String, dynamic>>.from(json.decode(existingData));
    }

    // Add new receipt
    receipts.add(receipt);

    // Save back to SharedPreferences
    await prefs.setString(_receiptKey, json.encode(receipts));
  }

  // 🔹 Load all receipts
  static Future<List<Map<String, dynamic>>> getReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_receiptKey);

    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  // 🔹 Clear all receipts (optional for testing)
  static Future<void> clearReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_receiptKey);
  }
}
