import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';

/// Launched from [ProfileScreen] when the user taps "Edit Profile".
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  // Holds a newly picked image (base64) before save
  String? _pendingImageBase64;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName);
    _phoneCtrl = TextEditingController(text: widget.profile.phoneNumber);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final provider = context.read<ProfileProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;
      if (bytes.length > 800 * 1024) {
        _showSnack('Image is too large. Maximum size is 800 KB.', isError: true);
        return;
      }

      // Upload immediately and refresh profile in provider
      final success = await provider.uploadProfileImage(bytes);
      if (success && mounted) {
        setState(() {
          _pendingImageBase64 = base64Encode(bytes);
        });
        _showSnack('Profile picture updated!');
      } else if (provider.errorMessage != null && mounted) {
        _showSnack(provider.errorMessage!, isError: true);
      }
    } catch (e) {
      _showSnack('Could not pick image: $e', isError: true);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();

    final success = await provider.saveProfile(
      fullName: _nameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      newProfileImageBase64: _pendingImageBase64,
    );

    if (!mounted) return;
    if (success) {
      _showSnack('Profile updated successfully!');
      Navigator.pop(context, true); // signal refresh to caller
    } else if (provider.errorMessage != null) {
      _showSnack(provider.errorMessage!, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          // Show current image: pending pick takes priority, then provider, then original
          final imageBase64 = _pendingImageBase64
              ?? provider.profile?.profileImageBase64
              ?? widget.profile.profileImageBase64;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Avatar ─────────────────────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            backgroundImage: imageBase64 != null
                                ? MemoryImage(base64Decode(imageBase64))
                                : null,
                            child: imageBase64 == null
                                ? Icon(Icons.person, size: 60, color: primaryColor)
                                : null,
                          ),
                        ),
                        if (provider.isImageUploading)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black38,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        GestureDetector(
                          onTap: provider.isBusy ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the camera icon to change photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 36),

                  // ── Email (read-only) ──────────────────────────────────
                  _InfoField(
                    label: 'Email Address',
                    value: widget.profile.email,
                    icon: Icons.email_outlined,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 20),

                  // ── Full Name ──────────────────────────────────────────
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    primaryColor: primaryColor,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Full name is required.';
                      if (v.trim().length < 3) return 'Minimum 3 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Phone ──────────────────────────────────────────────
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    primaryColor: primaryColor,
                    keyboardType: TextInputType.phone,
                    hint: 'e.g. 0123456789',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number is required.';
                      final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
                      final regex = RegExp(r'^(\+?60|0)1[0-9]{7,9}$');
                      if (!regex.hasMatch(cleaned)) return 'Enter a valid Malaysian phone number.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // ── Save Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isBusy ? null : _save,
                      icon: provider.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(provider.isSaving ? 'Saving…' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Read-only field shown for non-editable values like email.
class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primaryColor;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Can\'t edit', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
