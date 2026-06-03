import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class DiscountsAdminScreen extends StatefulWidget {
  const DiscountsAdminScreen({super.key});

  @override
  State<DiscountsAdminScreen> createState() => _DiscountsAdminScreenState();
}

class _DiscountsAdminScreenState extends State<DiscountsAdminScreen> {
  final CollectionReference _restaurants = FirebaseFirestore.instance.collection('restaurants');

  // Controllers for CRUD forms
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  
  String _selectedCategory = 'Food';

  // Image picking states
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _existingImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _offerController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _nameController.clear();
    _offerController.clear();
    _aboutController.clear();
    _locationController.clear();
    _hoursController.clear();
    _termsController.clear();
    _selectedCategory = 'Food';
    _selectedFileBytes = null;
    _selectedFileName = null;
    _existingImageUrl = null;
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;

        if (bytes != null && bytes.length > 800000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File is too large! Maximum size allowed is 800KB.')),
            );
          }
          return;
        }

        setDialogState(() {
          _selectedFileBytes = bytes;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Widget _buildImagePickerWidget(StateSetter setDialogState) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Poster Image (Max 800KB)*',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          if (_selectedFileBytes != null) ...[
            Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    _selectedFileBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? 'Selected File',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text('New poster selected', style: TextStyle(color: Colors.green, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setDialogState(() {
                      _selectedFileBytes = null;
                      _selectedFileName = null;
                    });
                  },
                ),
              ],
            ),
          ] else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _existingImageUrl!.startsWith('http')
                      ? Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        )
                      : Image.memory(
                          base64Decode(_existingImageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Poster',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text('Existing image will be kept', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.08),
                    foregroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _pickImage(setDialogState),
                  child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setDialogState(() {
                      _existingImageUrl = null;
                    });
                  },
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 80,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                onPressed: () => _pickImage(setDialogState),
                icon: Icon(Icons.add_photo_alternate_outlined, color: primaryColor),
                label: Text(
                  'Browse Poster File',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFormDialog({String? docId, Map<String, dynamic>? initialData}) {
    if (initialData != null) {
      _nameController.text = initialData['name'] ?? '';
      _offerController.text = initialData['discountOffer'] ?? '';
      _aboutController.text = initialData['about'] ?? '';
      _locationController.text = initialData['location'] ?? '';
      _hoursController.text = initialData['operatingHours'] ?? '';
      _selectedCategory = initialData['category'] ?? 'Food';
      _existingImageUrl = initialData['imageUrl'] ?? '';
      _selectedFileBytes = null;
      _selectedFileName = null;
      
      final terms = initialData['terms'] as List<dynamic>?;
      if (terms != null) {
        _termsController.text = terms.join('\n');
      } else {
        _termsController.clear();
      }
    } else {
      _clearControllers();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? 'Add Partner Restaurant' : 'Edit Restaurant'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Restaurant/Vendor Name*'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(value: 'Cafe', child: Text('Cafe')),
                          DropdownMenuItem(value: 'Services', child: Text('Services')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCategory = value!;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _offerController,
                        decoration: const InputDecoration(labelText: 'Discount Offer Details (e.g. 15% OFF)*'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _aboutController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'About / Description'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Location / Address*'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hoursController,
                        decoration: const InputDecoration(labelText: 'Operating Hours (e.g. 10AM - 6PM)'),
                      ),
                      const SizedBox(height: 12),
                      
                      // Custom image picker widget instead of URL text field
                      _buildImagePickerWidget(setDialogState),
                      
                      const SizedBox(height: 12),
                      TextField(
                        controller: _termsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Terms & Conditions (One per line)',
                          hintText: 'Valid for HIMSAK members only\nMin purchase RM10',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearControllers();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty ||
                        _offerController.text.trim().isEmpty ||
                        _locationController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in Name, Offer, and Location')),
                      );
                      return;
                    }

                    if (_selectedFileBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a poster image')),
                      );
                      return;
                    }

                    final name = _nameController.text.trim();
                    final offer = _offerController.text.trim();
                    final about = _aboutController.text.trim();
                    final location = _locationController.text.trim();
                    final hours = _hoursController.text.trim();
                    final category = _selectedCategory;
                    
                    final terms = _termsController.text
                        .split('\n')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    // Convert new image to base64 if picked
                    String posterData = '';
                    if (_selectedFileBytes != null) {
                      posterData = base64Encode(_selectedFileBytes!);
                    } else {
                      posterData = _existingImageUrl ?? '';
                    }

                    final Map<String, dynamic> data = {
                      'name': name,
                      'discountOffer': offer,
                      'about': about,
                      'location': location,
                      'operatingHours': hours,
                      'imageUrl': posterData,
                      'category': category,
                      'terms': terms,
                    };

                    try {
                      if (docId == null) {
                        // Create
                        await _restaurants.add({
                          ...data,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vendor registered successfully!')),
                          );
                        }
                      } else {
                        // Update
                        await _restaurants.doc(docId).update(data);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vendor updated successfully!')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving vendor: $e')),
                        );
                      }
                    } finally {
                      _clearControllers();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRestaurant(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Are you sure you want to delete "$name" and its offers?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _restaurants.doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partner removed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing partner: $e')),
          );
        }
      }
    }
  }

  void _showQRCodeDialog(String docId, String name) {
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=himsak_discount:$docId';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text(
              'Restaurant QR Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Text('Failed to load QR code. Check internet connection.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Print this QR code and place it at the counter for students to scan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('Open to Print'),
            onPressed: () async {
              final uri = Uri.parse(qrUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open QR code link')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Discounts / Partners'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _restaurants.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No partners registered yet.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'N/A';
                  final category = data['category'] ?? 'N/A';
                  final offer = data['discountOffer'] ?? 'N/A';
                  final location = data['location'] ?? 'N/A';

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('Offer: $offer', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code, color: Colors.orange),
                            tooltip: 'View QR Code',
                            onPressed: () => _showQRCodeDialog(doc.id, name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit Vendor',
                            onPressed: () => _showFormDialog(docId: doc.id, initialData: data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Vendor',
                            onPressed: () => _deleteRestaurant(doc.id, name),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
