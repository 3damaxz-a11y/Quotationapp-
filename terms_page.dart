import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.indigo,
      ),
      body: const Center(
        child: Text(
          'Terms & Conditions Page Coming Soon...',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
