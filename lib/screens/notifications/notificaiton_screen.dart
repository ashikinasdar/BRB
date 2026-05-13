import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('financial_aid')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return ListTile(
                title: Text('Application: ${data['status']}'),
                subtitle: Text(
                  data['status'] == 'Rejected'
                      ? 'Reason: ${data['adminReason']}'
                      : 'Your application is ${data['status']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}