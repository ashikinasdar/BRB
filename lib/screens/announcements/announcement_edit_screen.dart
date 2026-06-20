import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AnnouncementEditScreen extends StatefulWidget {
  final String? announcementId;

  const AnnouncementEditScreen({
    super.key,
    this.announcementId,
  });

  @override
  State<AnnouncementEditScreen> createState() =>
      _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState
    extends State<AnnouncementEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtl = TextEditingController();
  final _bodyCtl = TextEditingController();

  PlatformFile? _pickedFile;

  String? _existingImageUrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.announcementId != null) {
      _loadAnnouncement();
    }
  }

  Future<void> _loadAnnouncement() async {
    final doc = await FirebaseFirestore.instance
        .collection('announcements')
        .doc(widget.announcementId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    _titleCtl.text = data['title'] ?? '';
    _bodyCtl.text = data['body'] ?? '';
    _existingImageUrl = data['imageUrl'];

    setState(() {});
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  Future<String> uploadImageToCloudinary() async {
    if (_pickedFile == null) return '';

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

    if (_pickedFile!.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _pickedFile!.path!,
        ),
      );
    }

    final response =
    await request.send();

    final responseBody =
    await response.stream.bytesToString();

    final data =
    jsonDecode(responseBody);

    return data['secure_url'] ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? imageUrl =
          _existingImageUrl;

      if (_pickedFile != null) {
        imageUrl =
        await uploadImageToCloudinary();
      }

      final user =
          FirebaseAuth.instance.currentUser;

      final data = {
        'title':
        _titleCtl.text.trim(),
        'body':
        _bodyCtl.text.trim(),
        'imageUrl': imageUrl,
        'authorId': user?.uid,
        'authorName':
        user?.displayName ??
            user?.email ??
            'Admin',
        'createdAt':
        FieldValue.serverTimestamp(),
      };

      if (widget.announcementId ==
          null) {
        await FirebaseFirestore.instance
            .collection(
            'announcements')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection(
            'announcements')
            .doc(widget.announcementId)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.announcementId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Announcement'
              : 'Create Announcement',
        ),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final result =
                  await FilePicker
                      .platform
                      .pickFiles(
                    type:
                    FileType.image,
                    withData: true,
                  );

                  if (result != null &&
                      result.files
                          .isNotEmpty) {
                    setState(() {
                      _pickedFile =
                          result
                              .files
                              .first;
                    });
                  }
                },
                child: Container(
                  width:
                  double.infinity,
                  height: 180,
                  decoration:
                  BoxDecoration(
                    border: Border.all(
                      color: Colors
                          .grey
                          .shade300,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                        12),
                  ),
                  child: _pickedFile !=
                      null
                      ? (_pickedFile!
                      .bytes !=
                      null
                      ? Image.memory(
                    _pickedFile!
                        .bytes!,
                    fit: BoxFit
                        .cover,
                  )
                      : (_pickedFile!
                      .path !=
                      null
                      ? Image.file(
                    io.File(
                      _pickedFile!
                          .path!,
                    ),
                    fit: BoxFit
                        .cover,
                  )
                      : const SizedBox()))
                      : (_existingImageUrl !=
                      null &&
                      _existingImageUrl!
                          .isNotEmpty
                      ? Image.network(
                    _existingImageUrl!,
                    fit: BoxFit
                        .cover,
                  )
                      : const Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .add_photo_alternate,
                          size:
                          50,
                        ),
                        SizedBox(
                            height:
                            8),
                        Text(
                          'Tap to add image',
                        ),
                      ],
                    ),
                  )),
                ),
              ),

              const SizedBox(
                  height: 16),

              TextFormField(
                controller:
                _titleCtl,
                decoration:
                const InputDecoration(
                  labelText:
                  'Title',
                  border:
                  OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null ||
                      v.trim()
                          .isEmpty) {
                    return 'Enter title';
                  }
                  return null;
                },
              ),

              const SizedBox(
                  height: 16),

              Expanded(
                child: TextFormField(
                  controller:
                  _bodyCtl,
                  maxLines: null,
                  expands: true,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Body',
                    border:
                    OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null ||
                        v.trim()
                            .isEmpty) {
                      return 'Enter body';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(
                  height: 16),

              SizedBox(
                width:
                double.infinity,
                child:
                ElevatedButton(
                  onPressed:
                  _saving
                      ? null
                      : _save,
                  child: _saving
                      ? const SizedBox(
                    height:
                    20,
                    width:
                    20,
                    child:
                    CircularProgressIndicator(),
                  )
                      : const Text(
                    'Save',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}