import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EventEditScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventEditScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventEditScreen> createState() =>
      _EventEditScreenState();
}

class _EventEditScreenState
    extends State<EventEditScreen> {

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;

  File? selectedImage;

  String currentImageUrl = '';

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.eventData['title'] ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.eventData['description'] ?? '',
    );

    locationController = TextEditingController(
      text: widget.eventData['location'] ?? '',
    );

    currentImageUrl =
        widget.eventData['imageUrl'] ?? '';
  }

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
    if (selectedImage == null) {
      return currentImageUrl;
    }

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

    final data =
    jsonDecode(responseBody);

    return data['secure_url'] ?? '';
  }

  Future<void> updateEvent() async {
    try {
      String imageUrl =
      await uploadImageToCloudinary();

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'title':
        titleController.text.trim(),
        'description':
        descriptionController.text.trim(),
        'location':
        locationController.text.trim(),
        'imageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Event Updated Successfully',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Event',
        ),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                      12),
                  child: Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
                    : currentImageUrl
                    .isNotEmpty
                    ? ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                      12),
                  child: Image.network(
                    currentImageUrl,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.image,
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
              titleController,
              decoration:
              const InputDecoration(
                labelText: 'Title',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
              descriptionController,
              maxLines: 4,
              decoration:
              const InputDecoration(
                labelText:
                'Description',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateEvent,
                child: const Text(
                  'Update Event',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}