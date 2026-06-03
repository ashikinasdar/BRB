import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FinancialAidAdminScreen extends StatelessWidget {
  const FinancialAidAdminScreen({super.key});

  void updateStatus(String id, String status, String reason) async {
    await FirebaseFirestore.instance
        .collection('financial_aid')
        .doc(id)
        .update({
      'status': status,
      'adminReason': reason,
    });
  }

  void toggleDisplay(String id, bool value) async {
    await FirebaseFirestore.instance
        .collection('financial_aid')
        .doc(id)
        .update({
      'displayOnDashboard': value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Aid Admin')),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('financial_aid')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No applications'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'Pending';
              
              Color statusColor = Colors.orange;
              if (status == 'Approved') statusColor = Colors.green;
              if (status == 'Rejected') statusColor = Colors.red;

              final dateObj = data['createdAt'] as Timestamp?;
              final dateStr = dateObj != null 
                  ? "${dateObj.toDate().day}/${dateObj.toDate().month}/${dateObj.toDate().year}" 
                  : "N/A";

              final TextEditingController reasonController = TextEditingController();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['userName'] ?? 'Unknown Student',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'UID: ${data['userId'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildAdminDetailRow('Reason Type', data['reasonType'] ?? 'N/A'),
                      _buildAdminDetailRow('Amount', 'RM ${data['amount'] ?? 0}'),
                      _buildAdminDetailRow('Description', data['description'] ?? 'N/A'),
                      _buildAdminDetailRow('Submitted On', dateStr),
                      if (status == 'Rejected' && (data['adminReason'] ?? '').toString().isNotEmpty)
                        _buildAdminDetailRow('Admin Reason', data['adminReason'], isError: true),
                      
                      const SizedBox(height: 12),
                      if (data['documentBase64'] != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Stack(
                                    children: [
                                      Image.memory(
                                        base64Decode(data['documentBase64']),
                                        fit: BoxFit.contain,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.black),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('View Uploaded Document'),
                          ),
                        ),
                      
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              (data['displayOnDashboard'] ?? false) ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            tooltip: 'Toggle Dashboard Visibility',
                            onPressed: () => toggleDisplay(docs[index].id, !(data['displayOnDashboard'] ?? false)),
                          ),
                          const Spacer(),
                          if (status == 'Pending') ...[
                            TextButton.icon(
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    bool showError = false;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: const Text('Reject Application'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: reasonController,
                                                decoration: InputDecoration(
                                                  hintText: 'Enter rejection reason',
                                                  errorText: showError ? 'Reason cannot be empty' : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (reasonController.text.trim().isEmpty) {
                                                  setState(() => showError = true);
                                                } else {
                                                  updateStatus(docs[index].id, 'Rejected', reasonController.text.trim());
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: const Text('Submit', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      }
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => updateStatus(docs[index].id, 'Approved', ''),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}