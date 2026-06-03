import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    if (user == null) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        final bytes = result.files.single.bytes!;
        
        if (bytes.length > 800 * 1024) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image is too large. Max 800KB.')));
          setState(() => _isLoading = false);
          return;
        }

        final base64Image = base64Encode(bytes);
        
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'profileImageBase64': base64Image,
        }, SetOptions(merge: true));

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editBio(String currentBio) async {
    if (user == null) return;
    final controller = TextEditingController(text: currentBio);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Bio'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write something about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), 
            child: const Text('Save')
          ),
        ],
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'bio': result.trim(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Not logged in"));

    final primaryColor = Theme.of(context).colorScheme.primary;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['fullName'] ?? user!.displayName ?? 'Student';
        final email = data['email'] ?? user!.email ?? 'No Email';
        final bio = data['bio'] ?? 'Hello! I am a student. Welcome to my profile!';
        final role = data['role'] ?? 'user';
        final base64Image = data['profileImageBase64'];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: base64Image != null ? MemoryImage(base64Decode(base64Image)) : null,
                      child: base64Image == null ? Icon(Icons.person, size: 60, color: primaryColor) : null,
                    ),
                    if (_isLoading)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: role == 'admin' ? Colors.red.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: role == 'admin' ? Colors.red : primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('About Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () => _editBio(bio),
                              tooltip: 'Edit Bio',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(bio, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.history, color: Colors.orange),
                        ),
                        title: const Text('Activity History', style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.settings, color: Colors.blue),
                        ),
                        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.logout, color: Colors.red),
                        ),
                        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                        onTap: () {
                          context.read<AuthProvider>().logout();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30), // Padding at the bottom
              ],
            ),
          ),
        );
      },
    );
  }
}
