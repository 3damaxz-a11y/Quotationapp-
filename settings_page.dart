import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:business_manager_app/pages/Business_Info_Page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // 🔹 Section Title Widget
  Widget buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  // 🔹 Individual Setting Item Widget
  Widget buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          // ===== Account Section =====
          buildSectionTitle("Account"),

          buildSettingItem(
            icon: Icons.person,
            title: "Profile",
            onTap: () {},
          ),

          // ✅ Business Info Navigation
          buildSettingItem(
            icon: Icons.business,
            title: "Business Info",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessInfoPage(),
                ),
              );
            },
          ),

          buildSettingItem(
            icon: Icons.bookmark,
            title: "Subscription",
            onTap: () {},
          ),

          buildSettingItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () {},
          ),

          // ===== Document Settings =====
          buildSectionTitle("Document Settings"),

          buildSettingItem(
            icon: Icons.build,
            title: "Quotation Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.receipt_long,
            title: "Invoice Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.shopping_cart,
            title: "Purchase Order Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.request_quote,
            title: "Proforma Invoice Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.local_shipping,
            title: "Delivery Note Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.receipt,
            title: "Receipt Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.settings_applications,
            title: "Column Heading (TAX, HSN, Other Charges)",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.date_range,
            title: "Date & Currency Settings",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.bar_chart,
            title: "Download Reports & Statements",
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.insert_page_break,
            title: "Header Footer Template",
            onTap: () {},
          ),

          // ===== Support Section =====
          buildSectionTitle("Support"),

          buildSettingItem(
            icon: Icons.contact_mail,
            title: "Contact Us",
            onTap: () {},
          ),
          buildSettingItem(
            icon: FontAwesomeIcons.whatsapp,
            title: "Chat With Support Team",
            iconColor: Colors.green,
            onTap: () {},
          ),
          buildSettingItem(
            icon: Icons.star_rate,
            title: "Rate Us",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
