// lib/utils/pdf_templates.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'business_helper.dart'; // Humari BusinessInfo class ke liye

// ==================================
// == PDF Header Template Function ==
// ==================================
// Yeh function BusinessInfo leta hai aur ek PDF header widget wapas bhejta hai
Future<pw.Widget> buildPdfHeader(
    BusinessInfo info, String documentTitle) async {
  final Uint8List? logoBytes = await info.getLogoBytes();

  return pw.Column(children: [
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Business Info (Left Side)
        pw.Expanded(
          // Take available space
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min, // Take minimum vertical space
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes),
                    width: 70, height: 70), // Logo
              pw.SizedBox(height: logoBytes != null ? 10 : 0),
              pw.Text(
                info.name, // Business Name
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
              if (info.phone.isNotEmpty)
                pw.Text(info.phone,
                    style: const pw.TextStyle(fontSize: 9)), // Phone
              if (info.email.isNotEmpty)
                pw.Text(info.email,
                    style: const pw.TextStyle(fontSize: 9)), // Email
              if (info.fullAddress.isNotEmpty)
                pw.Text(info.fullAddress,
                    style: const pw.TextStyle(fontSize: 9)), // Address
              if (info.gstNumber.isNotEmpty)
                pw.Text("${info.gstLabel}: ${info.gstNumber}",
                    style: const pw.TextStyle(fontSize: 9)), // GST/VAT
            ],
          ),
        ),
        pw.SizedBox(width: 20), // Space between columns
        // Document Title (Right Side)
        pw.Text(
          documentTitle.toUpperCase(), // e.g., "QUOTATION", "INVOICE"
          style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800),
        ),
      ],
    ),
    pw.Divider(
        thickness: 1.5, height: 20, color: PdfColors.black), // Thick divider
  ]);
}

// ==================================
// == PDF Footer Template Function ==
// ==================================
// Yeh function BusinessInfo leta hai aur ek PDF footer widget wapas bhejta hai
Future<pw.Widget> buildPdfFooter(BusinessInfo info) async {
  final Uint8List? signatureBytes = await info.getSignatureBytes();

  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    // Signature (Right Aligned)
    pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
            width: 150, // Fixed width for signature area
            child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center, // Center items inside
                children: [
                  pw.Text("For, ${info.name}",
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 15),
                  if (signatureBytes != null)
                    pw.Image(pw.MemoryImage(signatureBytes),
                        height: 35), // Signature image
                  pw.SizedBox(
                      height:
                          signatureBytes != null ? 5 : 20), // Space adjustment
                  pw.Container(
                      height: 1, color: PdfColors.black), // Signature line
                  pw.SizedBox(height: 2),
                  pw.Text("AUTHORIZED SIGNATURE",
                      style: const pw.TextStyle(fontSize: 8)),
                ]))),
    pw.SizedBox(height: 20), // Space before bank details/terms

    // Bank Details (if available)
    if (info.bankInfo.isNotEmpty) ...[
      pw.Text("Bank Details / Payment Instructions:",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.Text(info.bankInfo, style: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 10),
    ],

    // Generic Footer Text
    pw.Divider(),
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text("Generated Via Business Manager App",
          style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
      pw.Text("Page {PAGE_NUM} of {TOTAL_PAGES}",
          style: const pw.TextStyle(fontSize: 8)), // Automatic page numbering
    ])
  ]);
}
