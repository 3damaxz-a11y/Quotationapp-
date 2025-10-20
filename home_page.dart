// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_manager_app/utils/app_colors.dart';
import 'package:business_manager_app/widgets/dashboard_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ✅ Naya import

// Saari pages import
import 'business_info_page.dart';
import 'customer_page.dart';
import 'product_page.dart';
import 'terms_selection_page.dart'; // ✅ Pehle se updated hai
import 'quotation_page.dart';
import 'quotation_list_page.dart';
import 'invoice_page.dart';
import 'invoice_list.dart';
import 'purchase_order_page.dart';
import 'proforma_invoice_page.dart';
import 'delivery_note_page.dart';
import 'receipt_page.dart';
import 'settings_page.dart';
import 'contact_page.dart'; // ✅ Naya import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String businessName = "Your Business";

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('businessName');
    if (name != null && name.isNotEmpty) {
      setState(() {
        businessName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,

      // ✅ Naya AppBar (Screenshot jaisa)
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground, // Light background
        foregroundColor: Colors.black, // Black text/icons
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              businessName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.youtube, color: Colors.red),
            onPressed: () {
              // TODO: Add YouTube link
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _loadBusinessName(); // Refresh name when returning
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Manage",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            // ✅ Naya "Manage" Card Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildManageCard(
                  context,
                  label: "BUSINESS",
                  icon: Icons.business_rounded,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessInfoPage(),
                      ),
                    );
                    _loadBusinessName();
                  },
                ),
                _buildManageCard(
                  context,
                  label: "CUSTOMER",
                  icon: Icons.person_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerPage()),
                    );
                  },
                ),
                _buildManageCard(
                  context,
                  label: "PRODUCT",
                  icon: Icons.inventory_2_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductPage()),
                    );
                  },
                ),
                _buildManageCard(
                  context,
                  label: "TERMS",
                  icon: Icons.article_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsSelectionPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              "Discover",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            // ✅ Dashboard Grid Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                DashboardCard(
                  title: 'Make Quotation',
                  subtitle: 'Create a new quotation',
                  icon: Icons.description_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuotationPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Quotation List',
                  subtitle: 'Manage all quotations',
                  icon: Icons.list_alt_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuotationListPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Make Invoice',
                  subtitle: 'Create a new invoice',
                  icon: Icons.receipt_long_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoicePage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Invoice List',
                  subtitle: 'Manage all invoices',
                  icon: Icons.file_copy_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InvoiceListPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Purchase Order',
                  subtitle: 'Manage purchase orders',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PurchaseOrderPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Proforma Invoice',
                  subtitle: 'Manage proforma invoices',
                  icon: Icons.request_quote_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProformaInvoicePage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Delivery Note',
                  subtitle: 'Manage delivery notes',
                  icon: Icons.local_shipping_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DeliveryNotePage()),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Receipt',
                  subtitle: 'Manage receipts',
                  icon: Icons.receipt_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReceiptPage()),
                    );
                  },
                ),

                // ✅ NAYA CARD: Settings
                DashboardCard(
                  title: 'Settings',
                  subtitle: 'Manage app settings',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),

                // ✅ NAYA CARD: Contact Us
                DashboardCard(
                  title: 'Contact Us',
                  subtitle: 'Get support',
                  icon: Icons.support_agent_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Naya Helper Widget (Screenshot jaisa)
  Widget _buildManageCard(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 2,
        child: Container(
          // Card ki width ko control karne ke liye
          width: MediaQuery.of(context).size.width / 4 - 20,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 12, // Thora chota text
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
