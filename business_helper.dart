// lib/utils/business_helper.dart

import 'dart:io'; // ✅ File ke liye
import 'dart:typed_data'; // ✅ Uint8List ke liye
import 'package:shared_preferences/shared_preferences.dart';

class BusinessInfo {
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String address3;
  final String gstLabel;
  final String gstNumber;
  final String bankInfo;
  final String logoPath; // ✅ Naya
  final String signaturePath; // ✅ Naya
  final String currency; // ✅ Currency bhi add kar di

  // ✅ Computed property for full address
  String get fullAddress => "$address1 $address2 $address3".trim();

  // Constructor
  BusinessInfo({
    this.name = '',
    this.contactName = '',
    this.email = '',
    this.phone = '',
    this.address1 = '',
    this.address2 = '',
    this.address3 = '',
    this.gstLabel = '',
    this.gstNumber = '',
    this.bankInfo = '',
    this.logoPath = '',
    this.signaturePath = '',
    this.currency = 'Rs', // Default currency
  });

  // ✅ Helper function to load logo bytes
  Future<Uint8List?> getLogoBytes() async {
    if (logoPath.isEmpty) return null;
    try {
      final file = File(logoPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print("Error reading logo bytes: $e");
    }
    return null;
  }

  // ✅ Helper function to load signature bytes
  Future<Uint8List?> getSignatureBytes() async {
    if (signaturePath.isEmpty) return null;
    try {
      final file = File(signaturePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print("Error reading signature bytes: $e");
    }
    return null;
  }
}

class BusinessHelper {
  // ✅ Updated function to return a BusinessInfo object
  static Future<BusinessInfo> getBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessInfo(
      name: prefs.getString('businessName') ?? '',
      contactName: prefs.getString('contactName') ?? '',
      email: prefs.getString('email') ?? '',
      phone: prefs.getString('phone') ?? '',
      address1: prefs.getString('address1') ?? '',
      address2: prefs.getString('address2') ?? '',
      address3: prefs.getString('address3') ?? '',
      gstLabel: prefs.getString('gstLabel') ?? '',
      gstNumber: prefs.getString('gstNumber') ?? '',
      bankInfo: prefs.getString('bankInfo') ?? '',
      logoPath: prefs.getString('logoImagePath') ?? '', // Load logo path
      signaturePath:
          prefs.getString('signatureImagePath') ?? '', // Load signature path
      currency: prefs.getString('currency') ?? 'Rs', // Load currency
    );
  }
}
