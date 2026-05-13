import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              final data = docs[index].data();

              final TextEditingController reasonController =
              TextEditingController();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['userName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${data['reasonType']}'),
                      Text('Amount: RM ${data['amount']}'),
                      Text('Status: ${data['status']}'),

                      if (data['status'] == 'Rejected')
                        Text('Admin Reason: ${data['adminReason']}',
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),

                  trailing: Column(
                    children: [

                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          updateStatus(
                            docs[index].id,
                            'Approved',
                            '',
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {

                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reject Reason'),
                              content: TextField(
                                controller: reasonController,
                                decoration: const InputDecoration(
                                    hintText: 'Enter reason'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    updateStatus(
                                      docs[index].id,
                                      'Rejected',
                                      reasonController.text,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.dashboard),
                        onPressed: () {
                          toggleDisplay(
                            docs[index].id,
                            !(data['displayOnDashboard'] ?? false),
                          );
                        },
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
}