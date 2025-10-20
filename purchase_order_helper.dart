// lib/utils/purchase_order_helper.dart

import 'dart:convert'; // ✅ YEH LINE ADD KI GAYI HAI (JSON errors ke liye)
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseOrderHelper {
  static const String _poKey = 'purchase_orders';

  // 🔹 Save PO
  static Future<void> savePO(Map<String, dynamic> po) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_poKey);
    List<Map<String, dynamic>> pos = [];
    if (existingData != null) {
      pos = List<Map<String, dynamic>>.from(json.decode(existingData));
    }
    pos.add(po);
    await prefs.setString(_poKey, json.encode(pos));
  }

  // 🔹 Load all POs
  static Future<List<Map<String, dynamic>>> getPOs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_poKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }
}
