import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsListScreen extends StatelessWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No announcements yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              final title = data['title'] ?? '(no title)';
              final body = data['body'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                child: ListTile(
                  leading: data['imageUrl'] != null 
                    ? SizedBox(
                        width: 64, 
                        height: 64, 
                        child: data['imageUrl'].startsWith('http')
                            ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                            : Image.memory(base64Decode(data['imageUrl']), fit: BoxFit.cover)
                      ) 
                    : null,
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: createdAt == null ? null : Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AnnouncementDetailScreen(announcementId: id),
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
