// lib/pages/signature_pad_page.dart

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

class SignaturePadPage extends StatefulWidget {
  const SignaturePadPage({super.key});

  @override
  _SignaturePadPageState createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  // Controller jo signature ko control karega
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Signature ko save kar ke picHlay page par wapas bhejain
  Future<void> _saveSignature() async {
    if (_controller.isNotEmpty) {
      final Uint8List? data = await _controller.toPngBytes();
      if (data != null) {
        Navigator.pop(context, data); // Image data wapas bhejain
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw a signature first")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw Signature"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Clear Button
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: "Clear",
            onPressed: () {
              setState(() => _controller.clear());
            },
          ),
          // Save Button
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Save",
            onPressed: _saveSignature,
          ),
        ],
      ),
      // Signature Pad
      body: Signature(
        controller: _controller,
        backgroundColor: Colors.white,
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }
}
