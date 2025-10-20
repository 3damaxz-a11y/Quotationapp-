import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddCustomerPage extends StatefulWidget {
  final Map<String, dynamic>? existingCustomer;

  const AddCustomerPage({Key? key, this.existingCustomer}) : super(key: key);

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController shippingController = TextEditingController();
  final TextEditingController otherInfoController = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();
    // If editing existing customer, pre-fill all fields
    if (widget.existingCustomer != null) {
      nameController.text = widget.existingCustomer!['name'] ?? '';
      companyController.text = widget.existingCustomer!['company'] ?? '';
      emailController.text = widget.existingCustomer!['email'] ?? '';
      phoneController.text = widget.existingCustomer!['phone'] ?? '';
      address1Controller.text = widget.existingCustomer!['address1'] ?? '';
      address2Controller.text = widget.existingCustomer!['address2'] ?? '';
      shippingController.text = widget.existingCustomer!['shipping'] ?? '';
      otherInfoController.text = widget.existingCustomer!['otherInfo'] ?? '';
    }
  }

  Future<void> saveCustomer() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter customer name")),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedList = prefs.getStringList('customers') ?? [];

    List<Map<String, dynamic>> customers = storedList
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (e) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    Map<String, dynamic> customerData = {
      'name': nameController.text.trim(),
      'company': companyController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'address1': address1Controller.text.trim(),
      'address2': address2Controller.text.trim(),
      'shipping': shippingController.text.trim(),
      'otherInfo': otherInfoController.text.trim(),
    };

    // If editing, replace the old entry
    if (widget.existingCustomer != null) {
      int index = customers.indexWhere((c) =>
          c['name'] == widget.existingCustomer!['name'] &&
          c['phone'] == widget.existingCustomer!['phone']);
      if (index != -1) {
        customers[index] = customerData;
      }
    } else {
      // Adding new customer
      customers.add(customerData);
    }

    // Save updated list
    List<String> encoded =
        customers.map((e) => jsonEncode(e)).toList().cast<String>();
    await prefs.setStringList('customers', encoded);

    setState(() {
      saving = false;
    });

    Navigator.pop(context, customerData); // return to CustomerPage
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCustomer != null
            ? 'Edit Customer'
            : 'Add New Customer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTextField('Name', nameController),
            buildTextField('Company', companyController),
            buildTextField('Email', emailController,
                type: TextInputType.emailAddress),
            buildTextField('Phone', phoneController, type: TextInputType.phone),
            buildTextField('Address Line 1', address1Controller),
            buildTextField('Address Line 2', address2Controller),
            buildTextField('Shipping Address', shippingController),
            buildTextField('Other Info', otherInfoController),
            const SizedBox(height: 20),
            saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: saveCustomer,
                    icon: const Icon(Icons.save),
                    label: Text(widget.existingCustomer != null
                        ? 'Update Customer'
                        : 'Save Customer'),
                  ),
          ],
        ),
      ),
    );
  }
}
