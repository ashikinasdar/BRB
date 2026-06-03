import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class AnnouncementEditScreen extends StatefulWidget {
  final String? announcementId; // null => create

  const AnnouncementEditScreen({super.key, this.announcementId});

  @override
  State<AnnouncementEditScreen> createState() => _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState extends State<AnnouncementEditScreen> {
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
      FirebaseFirestore.instance.collection('announcements').doc(widget.announcementId).get().then((doc) {
        if (!doc.exists) return;
        final data = doc.data()! as Map<String, dynamic>;
        _titleCtl.text = data['title'] ?? '';
        _bodyCtl.text = data['body'] ?? '';
        _existingImageUrl = data['imageUrl'];
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;
    final data = {
      'title': _titleCtl.text.trim(),
      'body': _bodyCtl.text.trim(),
      'authorId': user?.uid,
      'authorName': user?.displayName ?? user?.email ?? 'Admin',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // If a new file was picked, encode it
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      if (_pickedFile!.bytes!.length > 800000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image must be under 800KB')));
        }
        setState(() => _saving = false);
        return;
      }
      data['imageUrl'] = base64Encode(_pickedFile!.bytes!);
    } else if (_existingImageUrl != null) {
      data['imageUrl'] = _existingImageUrl;
    }

    try {
      if (widget.announcementId == null) {
        await FirebaseFirestore.instance.collection('announcements').add(data);
      } else {
        await FirebaseFirestore.instance.collection('announcements').doc(widget.announcementId).update(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcementId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Announcement' : 'Create Announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                  if (result != null && result.files.isNotEmpty) {
                    setState(() => _pickedFile = result.files.first);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: _pickedFile != null
                      ? (_pickedFile!.bytes != null
                          ? Image.memory(_pickedFile!.bytes!, fit: BoxFit.cover)
                          : const Center(child: Text('Error loading picked image')))
                      : (_existingImageUrl != null
                          ? (_existingImageUrl!.startsWith('http')
                              ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                              : Image.memory(base64Decode(_existingImageUrl!), fit: BoxFit.cover))
                          : const Center(child: Text('Tap to add image'))),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _bodyCtl,
                  decoration: const InputDecoration(labelText: 'Body'),
                  maxLines: null,
                  expands: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter body' : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator() : const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
