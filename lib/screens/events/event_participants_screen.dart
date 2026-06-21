import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventParticipantsScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('event_registrations')
            .where(
          'eventId',
          isEqualTo: eventId,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final participants = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Text(
                  'Participants (${participants.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: participants.isEmpty
                    ? const Center(
                  child: Text(
                    'No participants yet',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final data = participants[index].data()
                    as Map<String, dynamic>;

                    final userName =
                        data['userName'] ?? 'Unknown User';

                    final userId =
                        data['userId'] ?? '';

                    final registeredAt =
                    data['registeredAt'];

                    String registrationDate = '';

                    if (registeredAt != null &&
                        registeredAt is Timestamp) {
                      final date =
                      registeredAt.toDate();

                      registrationDate =
                      '${date.day}/${date.month}/${date.year}';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                        title: Text(userName),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID: $userId',
                            ),
                            if (registrationDate.isNotEmpty)
                              Text(
                                'Registered: $registrationDate',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}