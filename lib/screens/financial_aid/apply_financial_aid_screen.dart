import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';

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

  Uint8List? fileBytes;
  String? fileName;
  bool isLoading = false;

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'], // Limit to images for Base64 viewing
      );

      if (result != null) {
        Uint8List? bytes = result.files.single.bytes;
        if (bytes == null && result.files.single.path != null) {
          bytes = File(result.files.single.path!).readAsBytesSync();
        }
        
        if (bytes != null && bytes.length > 800000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File is too large! Please select an image under 800KB.')),
            );
          }
          return;
        }

        setState(() {
          fileBytes = bytes;
          fileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

    // Removed uploadFile method as we are using base64 now

  Future<void> submit() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (fileBytes == null || fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final base64Doc = base64Encode(fileBytes!);

      await FirebaseFirestore.instance.collection('financial_aid').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'reasonType': reasonType,
        'amount': amount,
        'description': descController.text,
        'documentBase64': base64Doc,
        'documentName': fileName,
        'status': 'Pending',
        'adminReason': '',
        'displayOnDashboard': false,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore save timed out. Check your connection or Firebase rules.'),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your financial aid application has been submitted successfully and is pending review.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E1E3A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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

          // STATUS SECTION
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('financial_aid')
                .where('userId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (tA == null && tB == null) return 0;
                if (tA == null) return -1;
                if (tB == null) return 1;
                return tB.compareTo(tA);
              });
              
              final latestApp = docs.first.data() as Map<String, dynamic>;
              final status = latestApp['status'] ?? 'Pending';
              final adminReason = latestApp['adminReason'] ?? '';
              
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.access_time;
              if (status == 'Approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'Rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Status: $status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            if (status == 'Rejected' && adminReason.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Reason: $adminReason',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                              "JPG or PNG (max 800KB)",
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
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Application'),
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