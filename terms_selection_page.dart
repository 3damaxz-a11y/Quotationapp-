// lib/pages/terms_selection_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsSelectionPage extends StatefulWidget {
  // ✅ Naya variable ta ke quotation page se call kar sakain
  final bool selectionMode;

  const TermsSelectionPage({
    super.key,
    this.selectionMode = false, // Default value
  });

  @override
  State<TermsSelectionPage> createState() => _TermsSelectionPageState();
}

class _TermsSelectionPageState extends State<TermsSelectionPage> {
  List<String> termsList = [];
  List<bool> selectedTerms = [];
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    loadTerms();
  }

  Future<void> loadTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTerms = prefs.getStringList('terms_list') ?? [];
    setState(() {
      termsList = savedTerms;
      selectedTerms = List.generate(savedTerms.length, (index) => false);
    });
  }

  Future<void> addNewTerm() async {
    TextEditingController termController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Term"),
        content: TextField(
          controller: termController,
          decoration: const InputDecoration(
            labelText: "Enter term or condition",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (termController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                termsList.add(termController.text);
                await prefs.setStringList('terms_list', termsList);
                loadTerms();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      selectedTerms = List.generate(termsList.length, (_) => selectAll);
    });
  }

  void deleteSelectedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> newList = [];
    for (int i = 0; i < termsList.length; i++) {
      if (!selectedTerms[i]) {
        newList.add(termsList[i]);
      }
    }
    await prefs.setStringList('terms_list', newList);
    loadTerms();
  }

  // ✅ Naya function: Selected terms ko wapas bhejnay ke liye
  void _returnSelectedTerms() {
    if (!widget.selectionMode) {
      Navigator.pop(context);
      return;
    }

    List<String> finalSelectedList = [];
    for (int i = 0; i < termsList.length; i++) {
      if (selectedTerms[i]) {
        finalSelectedList.add(termsList[i]);
      }
    }
    // List ko wapas quotation page par bhejain
    Navigator.pop(context, finalSelectedList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Terms and Conditions"),
        actions: [
          // ✅ Delete button sirf selectionMode mein nahi dikhega
          if (!widget.selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed:
                  selectedTerms.contains(true) ? deleteSelectedTerms : null,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addNewTerm,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Quotation",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal,
            ),
          ),
          const Divider(thickness: 1),
          CheckboxListTile(
            title: const Text("Select All"),
            value: selectAll,
            onChanged: toggleSelectAll,
          ),
          const Divider(),
          Expanded(
            child: termsList.isEmpty
                ? const Center(
                    child: Text("You don't have any terms and conditions"),
                  )
                : ListView.builder(
                    itemCount: termsList.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(termsList[index]),
                        value: selectedTerms[index],
                        onChanged: (val) {
                          setState(() {
                            selectedTerms[index] = val ?? false;
                            selectAll = selectedTerms.every((e) => e);
                          });
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              // ✅ onPressed ab naya function call karega
              onPressed: _returnSelectedTerms,
              child: const Text(
                "DONE",
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
