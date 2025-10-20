// lib/utils/delivery_note_helper.dart

import 'dart:convert'; // ✅ THEEK KAR DIYA (colon ke sath)
import 'package:shared_preferences/shared_preferences.dart'; // ✅ THEEK KAR DIYA (colon ke sath)

class DeliveryNoteHelper {
  static const String _dnKey = 'delivery_notes';

  // 🔹 Save Delivery Note
  static Future<void> saveDeliveryNote(Map<String, dynamic> dn) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_dnKey);
    List<Map<String, dynamic>> dns = [];
    if (existingData != null) {
      dns = List<Map<String, dynamic>>.from(json.decode(existingData));
    }
    dns.add(dn);
    await prefs.setString(_dnKey, json.encode(dns));
  }

  // 🔹 Load all Delivery Notes
  static Future<List<Map<String, dynamic>>> getDeliveryNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_dnKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }
}
