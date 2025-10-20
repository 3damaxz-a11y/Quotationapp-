// lib/pages/Business_Info_Page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_manager_app/pages/signature_pad_page.dart';

class BusinessInfoPage extends StatefulWidget {
  const BusinessInfoPage({super.key});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  File? logoImage;
  File? signatureImage;

  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController contactNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController address3Controller = TextEditingController();
  final TextEditingController otherInfoController = TextEditingController();
  final TextEditingController gstLabelController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();
  final TextEditingController businessCategoryController =
      TextEditingController(text: "none");
  final TextEditingController bankInfoController = TextEditingController(
      text:
          "Account Name : ######\nAccount Number : ######\nBank Name : ######");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessData();
    });
  }

  // ✅ UPDATED: Ab yeh function image paths ko bhi load karega
  Future<void> _loadBusinessData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      businessNameController.text = prefs.getString('businessName') ?? '';
      contactNameController.text = prefs.getString('contactName') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      address1Controller.text = prefs.getString('address1') ?? '';
      address2Controller.text = prefs.getString('address2') ?? '';
      address3Controller.text = prefs.getString('address3') ?? '';
      otherInfoController.text = prefs.getString('otherInfo') ?? '';
      gstLabelController.text = prefs.getString('gstLabel') ?? '';
      gstNumberController.text = prefs.getString('gstNumber') ?? '';
      businessCategoryController.text =
          prefs.getString('businessCategory') ?? 'none';
      bankInfoController.text =
          prefs.getString('bankInfo') ?? bankInfoController.text;

      // ✅ Naya Code: Load image paths
      final logoPath = prefs.getString('logoImagePath');
      if (logoPath != null) {
        logoImage = File(logoPath);
      }
      final signaturePath = prefs.getString('signatureImagePath');
      if (signaturePath != null) {
        signatureImage = File(signaturePath);
      }
    });
  }

  // ✅ UPDATED: Ab yeh function image paths ko bhi save karega
  Future<void> _saveBusinessData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', businessNameController.text);
    await prefs.setString('contactName', contactNameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('phone', phoneController.text);
    await prefs.setString('address1', address1Controller.text);
    await prefs.setString('address2', address2Controller.text);
    await prefs.setString('address3', address3Controller.text);
    await prefs.setString('otherInfo', otherInfoController.text);
    await prefs.setString('gstLabel', gstLabelController.text);
    await prefs.setString('gstNumber', gstNumberController.text);
    await prefs.setString('businessCategory', businessCategoryController.text);
    await prefs.setString('bankInfo', bankInfoController.text);

    // ✅ Naya Code: Save image paths
    if (logoImage != null) {
      await prefs.setString('logoImagePath', logoImage!.path);
    }
    if (signatureImage != null) {
      await prefs.setString('signatureImagePath', signatureImage!.path);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Business Info Updated Successfully')),
    );
  }

  // Modal dikhanay wala function
  Future<void> _showImageSourceModal(bool isLogo) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!isLogo)
              ListTile(
                leading: const Icon(Icons.draw),
                title: const Text('Signature Pad'),
                onTap: () => Navigator.pop(context, null),
              ),
          ],
        ),
      ),
    );

    // `source` null hoga agar "Signature Pad" select kiya
    if (source == null) {
      if (!isLogo) {
        _getSignature(isLogo); // Signature Pad kholain
      }
    } else {
      _getImage(source, isLogo); // Camera ya Gallery kholain
    }
  }

  // ✅ UPDATED: Camera/Gallery ki file ko app ki directory mein copy karega
  Future<void> _getImage(ImageSource source, bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      // File ko app ki permanent directory mein copy karain
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.png';
      final File localFile =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        if (isLogo) {
          logoImage = localFile; // Nayi permanent file save karain
        } else {
          signatureImage = localFile; // Nayi permanent file save karain
        }
      });
    }
  }

  // ✅ UPDATED: Signature ko app ki directory mein save karega
  Future<void> _getSignature(bool isLogo) async {
    final Uint8List? signatureBytes = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignaturePadPage()),
    );

    if (signatureBytes != null) {
      // Temporary ke bajaye permanent directory istemal karain
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File('${appDir.path}/$fileName').create();
      await file.writeAsBytes(signatureBytes);

      setState(() {
        if (isLogo) {
          logoImage = file;
        } else {
          signatureImage = file;
        }
      });
    }
  }

  // --- Baqi UI Code (Pehle Jaisa) ---

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _imagePickerBox(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          image: image != null
              ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const Icon(Icons.edit, color: Colors.white),
                  ],
                ),
              )
            : const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.edit, color: Colors.white),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Update Business Info"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _imagePickerBox(
                    "ADD LOGO", logoImage, () => _showImageSourceModal(true)),
                const SizedBox(width: 20),
                _imagePickerBox("ADD SIGNATURE", signatureImage,
                    () => _showImageSourceModal(false)),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField("Business Name", businessNameController),
            _buildTextField("Contact Name", contactNameController),
            _buildTextField("Email", emailController),
            _buildTextField("Phone Number", phoneController),
            _buildTextField("Address 1", address1Controller),
            _buildTextField("Address 2", address2Controller),
            _buildTextField("Address 3", address3Controller),
            _buildTextField("Other Info", otherInfoController),
            _buildTextField("GSTIN/PAN/VAT/Business Label", gstLabelController),
            _buildTextField(
                "GSTIN/PAN/VAT/Business Number", gstNumberController),
            _buildTextField("Business Category", businessCategoryController),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Payment Instructions - Bank Details",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField("Bank Info", bankInfoController, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBusinessData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "Update",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
