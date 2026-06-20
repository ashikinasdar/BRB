import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'event_participants_screen.dart';
import 'event_edit_screen.dart';

class EventAdminScreen extends StatefulWidget {
  const EventAdminScreen({super.key});

  @override
  State<EventAdminScreen> createState() =>
      _EventAdminScreenState();
}

class _EventAdminScreenState
    extends State<EventAdminScreen> {
  File? selectedImage;
  bool isSaving = false;
  final titleController =
  TextEditingController();

  final descriptionController =
  TextEditingController();

  final locationController =
  TextEditingController();

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<String> uploadImageToCloudinary() async {
    if (selectedImage == null) return '';

    const cloudName = 'dkofcgsa0';
    const uploadPreset = 'event_images';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] =
        uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedImage!.path,
      ),
    );

    final response =
    await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Cloudinary Error: $responseBody',
      );
    }

    final data =
    jsonDecode(responseBody);

    return data['secure_url'] ?? '';
  }

  Future<void> addEvent() async {

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {

      String imageUrl = '';

      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary();
      }

      await FirebaseFirestore.instance
          .collection('events')
          .add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      titleController.clear();
      descriptionController.clear();
      locationController.clear();

      setState(() {
        selectedImage = null;
      });

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Event added successfully',
            ),
          ),
        );
      }

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> deleteEvent(
      String docId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(docId)
        .delete();
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add Event',
        ),
        content:
        SingleChildScrollView(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 130,
                  width:
                  double.infinity,
                  decoration:
                  BoxDecoration(
                    border:
                    Border.all(),
                    borderRadius:
                    BorderRadius
                        .circular(
                        12),
                  ),
                  child:
                  selectedImage ==
                      null
                      ? const Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .add_a_photo,
                        size:
                        40,
                      ),
                      SizedBox(
                          height:
                          8),
                      Text(
                        "Select Image",
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                        12),
                    child:
                    Image.file(
                      selectedImage!,
                      fit: BoxFit
                          .cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  height: 12),
              TextField(
                controller:
                titleController,
                decoration:
                const InputDecoration(
                  labelText:
                  'Title',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                  height: 12),
              TextField(
                controller:
                descriptionController,
                maxLines: 3,
                decoration:
                const InputDecoration(
                  labelText:
                  'Description',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                  height: 12),
              TextField(
                controller:
                locationController,
                decoration:
                const InputDecoration(
                  labelText:
                  'Location',
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                  context);
            },
            child:
            const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
              await addEvent();
            },
            child: isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Events',
        ),
      ),
      body:
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore
            .instance
            .collection('events')
            .orderBy(
          'createdAt',
          descending: true,
        )
            .snapshots(),
        builder:
            (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No events available',
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final doc =
              docs[index];

              final data =
              doc.data()
              as Map<String,
                  dynamic>;

              return Card(
                margin:
                const EdgeInsets
                    .all(8),
                child: ListTile(
                  leading: data[
                  'imageUrl'] !=
                      null &&
                      data['imageUrl']
                          .toString()
                          .isNotEmpty
                      ? ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                        8),
                    child:
                    Image.network(
                      data[
                      'imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit
                          .cover,
                    ),
                  )
                      : const Icon(
                    Icons.event,
                    size: 40,
                  ),
                  title: Text(
                    data['title'] ??
                        '',
                  ),
                  subtitle: Text(
                    data['location'] ??
                        '',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventEditScreen(
                                eventId: doc.id,
                                eventData: data,
                              ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.people,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventParticipantsScreen(
                                    eventId: doc.id,
                                    eventTitle:
                                    data['title'] ?? '',
                                  ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Event'),
                              content: const Text(
                                'Are you sure you want to delete this event?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteEvent(doc.id);
                          }
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
      floatingActionButton:
      FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}