import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').doc(announcementId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Announcement not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final title = data['title'] ?? '(no title)';
          final body = data['body'] ?? '';
          final author = data['authorName'] ?? 'Admin';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final imageUrl = data['imageUrl'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null) ...[
                  SizedBox(height: 200, width: double.infinity, child: Image.network(imageUrl, fit: BoxFit.cover)),
                  const SizedBox(height: 12),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('By $author', style: const TextStyle(color: Colors.grey)),
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text('${createdAt.day}/${createdAt.month}/${createdAt.year}', style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 16),
                Expanded(child: SingleChildScrollView(child: Text(body, style: const TextStyle(fontSize: 16)))),
              ],
            ),
          );
        },
      ),
    );
  }
}
