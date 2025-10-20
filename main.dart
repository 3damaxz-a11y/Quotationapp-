import 'package:flutter/material.dart';
import 'package:business_manager_app/utils/app_theme.dart';
import 'package:business_manager_app/utils/app_colors.dart';

// Import all pages
import 'pages/home_page.dart';
import 'pages/quotation_page.dart';
import 'pages/quotation_list_page.dart';
import 'pages/invoice_page.dart';
import 'pages/invoice_list.dart';
import 'pages/customer_page.dart';
import 'pages/product_page.dart';
import 'pages/add_product_page.dart';
import 'pages/proforma_invoice_page.dart';
import 'pages/purchase_order_page.dart';
import 'pages/delivery_note_page.dart';
import 'pages/receipt_page.dart';
import 'pages/contact_page.dart';
import 'pages/terms_page.dart';
import 'pages/settings_page.dart';
import 'pages/business_page.dart';
import 'pages/business_info_page.dart'; // ✅ lowercase fix

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BusinessManagerApp());
}

class BusinessManagerApp extends StatelessWidget {
  const BusinessManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Manager App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // ✅ Global Theme Applied
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/quotation': (context) => const QuotationPage(),
        '/quotationList': (context) => const QuotationListPage(),
        '/invoice': (context) => const InvoicePage(),
        '/invoiceList': (context) => const InvoiceListPage(),
        '/customer': (context) => const CustomerPage(),
        '/product': (context) => const ProductPage(),
        '/addProduct': (context) => const AddProductPage(),
        '/proformaInvoice': (context) => const ProformaInvoicePage(),
        '/purchaseOrder': (context) => const PurchaseOrderPage(),
        '/deliveryNote': (context) => const DeliveryNotePage(),
        '/receipt': (context) => const ReceiptPage(),
        '/contact': (context) => const ContactPage(),
        '/terms': (context) => const TermsPage(),
        '/settings': (context) => const SettingsPage(),
        '/business': (context) => const BusinessPage(),
        '/businessInfo': (context) => const BusinessInfoPage(),
      },
    );
  }
}
