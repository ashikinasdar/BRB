import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> event;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() =>
      _EventDetailScreenState();
}

class _EventDetailScreenState
    extends State<EventDetailScreen> {

  Future<bool> hasJoined() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final snapshot =
    await FirebaseFirestore.instance
        .collection(
        'event_registrations')
        .where(
      'eventId',
      isEqualTo: widget.eventId,
    )
        .where(
      'userId',
      isEqualTo: user.uid,
    )
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> joinEvent() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final alreadyJoined =
    await hasJoined();

    if (alreadyJoined) return;

    await FirebaseFirestore.instance
        .collection(
        'event_registrations')
        .add({
      'eventId': widget.eventId,
      'userId': user.uid,
      'userName':
      user.displayName ?? 'Student',
      'registeredAt':
      Timestamp.now(),
    });

    setState(() {});
  }

  Future<void> leaveEvent() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final snapshot =
    await FirebaseFirestore.instance
        .collection(
        'event_registrations')
        .where(
      'eventId',
      isEqualTo: widget.eventId,
    )
        .where(
      'userId',
      isEqualTo: user.uid,
    )
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title:
        Text(event['title'] ?? ''),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            SizedBox(
              height: 220,
              width: double.infinity,
              child: event['imageUrl'] !=
                  null &&
                  event['imageUrl']
                      .toString()
                      .isNotEmpty
                  ? Image.network(
                event['imageUrl'],
                fit: BoxFit.cover,
              )
                  : Container(
                color:
                Colors.grey.shade300,
                child: const Icon(
                  Icons.event,
                  size: 100,
                ),
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [

                  Text(
                    event['title'] ?? '',
                    style:
                    const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child: Text(
                          event['location'] ??
                              '',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 20),

                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                      height: 8),

                  Text(
                    event['description'] ??
                        '',
                  ),

                  const SizedBox(
                      height: 24),

                  StreamBuilder<
                      QuerySnapshot>(
                    stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                        'event_registrations')
                        .where(
                      'eventId',
                      isEqualTo:
                      widget
                          .eventId,
                    )
                        .snapshots(),
                    builder:
                        (context,
                        snapshot) {

                      final count =
                          snapshot
                              .data
                              ?.docs
                              .length ??
                              0;

                      return Text(
                        "$count Students Joined",
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                      height: 20),

                  FutureBuilder<bool>(
                    future:
                    hasJoined(),
                    builder:
                        (context,
                        snapshot) {

                      final joined =
                          snapshot
                              .data ??
                              false;

                      return SizedBox(
                        width:
                        double.infinity,
                        child:
                        ElevatedButton(
                          onPressed:
                              () async {

                            if (joined) {
                              await leaveEvent();
                            } else {
                              await joinEvent();
                            }

                            setState(() {});
                          },
                          child: Text(
                            joined
                                ? "Leave Event"
                                : "Join Event",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}