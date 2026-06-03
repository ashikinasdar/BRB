import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  void _navigateToForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinancialAidFormScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context, String base64Doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.memory(
                  base64Decode(base64Doc),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'Rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.highlight_off;
        break;
      case 'Pending':
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Financial Aid History'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('financial_aid')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // extra bottom padding for FAB
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final appData = docs[index].data() as Map<String, dynamic>;
              final reason = appData['reasonType'] ?? 'N/A';
              final amount = (appData['amount'] as num?)?.toDouble() ?? 0.0;
              final desc = appData['description'] ?? '';
              final status = appData['status'] ?? 'Pending';
              final adminReason = appData['adminReason'] ?? '';
              final dateObj = appData['createdAt'] as Timestamp?;
              final dateStr = dateObj != null
                  ? "${dateObj.toDate().day}/${dateObj.toDate().month}/${dateObj.toDate().year}"
                  : "N/A";
              final documentBase64 = appData['documentBase64'] as String?;
              final hasDocument = documentBase64 != null && documentBase64.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (desc.isNotEmpty) ...[
                        Text(
                          desc,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Submitted on: $dateStr',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (hasDocument)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _viewDocument(context, documentBase64),
                              icon: const Icon(Icons.image_outlined, size: 16),
                              label: const Text('View Doc', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      if (status == 'Rejected' && adminReason.toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Feedback from Admin:',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                adminReason,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on_outlined,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Aid Applications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Facing a family, medical, or educational emergency? Submit an application for financial assistance here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _navigateToForm(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Apply for Financial Aid',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialAidFormScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FinancialAidFormScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FinancialAidFormScreen> createState() => _FinancialAidFormScreenState();
}

class _FinancialAidFormScreenState extends State<FinancialAidFormScreen> {
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
        allowedExtensions: ['jpg', 'png', 'jpeg'],
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Apply for Financial Aid'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // HEADER SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Financial Aid Request",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Submit your application details below",
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

                    DropdownButtonFormField<String>(
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
                          value == null || value.isEmpty ? 'Enter amount' : null,
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
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file, size: 30, color: primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              fileName ?? 'Click to upload documents',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: fileName != null ? FontWeight.bold : FontWeight.normal),
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
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            : const Text(
                                'Submit Application',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
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