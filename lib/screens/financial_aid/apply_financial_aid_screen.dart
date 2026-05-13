import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ApplyFinancialAidScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ApplyFinancialAidScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ApplyFinancialAidScreen> createState() => _ApplyFinancialAidScreenState();
}

class _ApplyFinancialAidScreenState extends State<ApplyFinancialAidScreen> {
  final _formKey = GlobalKey<FormState>();

  String reasonType = 'Medical emergency';
  final amountController = TextEditingController();
  final descController = TextEditingController();

  File? file;
  String? fileName;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  Future<String> uploadFile(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('financial_aid/${DateTime.now().millisecondsSinceEpoch}.pdf');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> submit() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    try {
      if (!_formKey.currentState!.validate()) return;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a document')),
        );
        return;
      }

      final docUrl = await uploadFile(file!);

      await FirebaseFirestore.instance.collection('financial_aid').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'reasonType': reasonType,
        'amount': amount,
        'description': descController.text,
        'documentUrl': docUrl,
        'status': 'Pending',
        'adminReason': '',
        'displayOnDashboard': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted')),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Apply Financial Aid'),
        backgroundColor: const Color(0xFF8E1E3A),
        elevation: 0,
      ),
      body: ListView(
        children: [

          // HEADER SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E1E3A), Color(0xFFB03052)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Financial Aid",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Submit your application",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // FORM CARD
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    // INFO BOX
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Financial aid is available for emergency situations. All applications are reviewed confidentially.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField(
                      value: reasonType,
                      items: const [
                        DropdownMenuItem(
                            value: 'Medical emergency',
                            child: Text('Medical emergency')),
                        DropdownMenuItem(
                            value: 'Family emergency',
                            child: Text('Family emergency')),
                        DropdownMenuItem(
                            value: 'Educational expenses',
                            child: Text('Educational expenses')),
                        DropdownMenuItem(
                            value: 'Transportation',
                            child: Text('Transportation')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => reasonType = value!);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Reason for Aid',
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Requested (RM)',
                        hintText: 'e.g., 500',
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter amount' : null,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Briefly explain your situation...',
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // UPLOAD BOX
                    InkWell(
                      onTap: pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.upload_file, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              fileName ?? 'Click to upload documents',
                              textAlign: TextAlign.center,
                            ),
                            const Text(
                              "PDF, JPG, or PNG (max 5MB)",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E1E3A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: submit,
                        child: const Text('Submit Application'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}