import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class DiscountsAdminScreen extends StatefulWidget {
  const DiscountsAdminScreen({super.key});

  @override
  State<DiscountsAdminScreen> createState() => _DiscountsAdminScreenState();
}

class _DiscountsAdminScreenState extends State<DiscountsAdminScreen> {
  final CollectionReference _restaurants = FirebaseFirestore.instance
      .collection('restaurants');
  final CollectionReference _discountClaims =
      FirebaseFirestore.instance.collection('discount_claims');

  // Controllers for CRUD forms
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  String _selectedCategory = 'Food';
  String _searchQuery = '';
  String _currentFilter = 'All'; // 'All', 'Food', 'Cafe', 'Services'
  String _viewType = 'Restaurants'; // 'Restaurants' or 'Claims'
  String _claimsSearchQuery = '';

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
              const SnackBar(
                content: Text(
                  'File is too large! Maximum size allowed is 800KB.',
                ),
              ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
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
                  child: Image.memory(_selectedFileBytes!, fit: BoxFit.cover),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'New poster selected',
                        style: TextStyle(color: Colors.green, fontSize: 11),
                      ),
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
          ] else if (_existingImageUrl != null &&
              _existingImageUrl!.isNotEmpty) ...[
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        )
                      : Image.memory(
                          base64Decode(_existingImageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Poster',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Existing image will be kept',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.08),
                    foregroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _pickImage(setDialogState),
                  child: const Text(
                    'Change',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                onPressed: () => _pickImage(setDialogState),
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: primaryColor,
                ),
                label: Text(
                  'Browse Poster File',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          docId == null
                              ? 'Add Partner Restaurant'
                              : 'Edit Restaurant',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _clearControllers();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Image Picker
                    _buildImagePickerWidget(setDialogState),
                    const SizedBox(height: 20),

                    // Name Field
                    _buildModernTextField(
                      controller: _nameController,
                      label: 'Restaurant/Vendor Name*',
                      icon: Icons.storefront,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Category & Offer Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryDropdown(
                            value: _selectedCategory,
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedCategory = value!;
                              });
                            },
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _offerController,
                            label: 'Discount Offer*',
                            icon: Icons.local_offer,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildModernTextField(
                      controller: _aboutController,
                      label: 'About / Description',
                      icon: Icons.description,
                      maxLines: 2,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Location & Hours Row
                    _buildModernTextField(
                      controller: _locationController,
                      label: 'Location / Address*',
                      icon: Icons.location_on,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    _buildModernTextField(
                      controller: _hoursController,
                      label: 'Operating Hours (e.g. 10AM - 6PM)',
                      icon: Icons.access_time,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Terms & Conditions
                    _buildModernTextField(
                      controller: _termsController,
                      label: 'Terms & Conditions (One per line)',
                      icon: Icons.notes,
                      maxLines: 3,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _clearControllers();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (_nameController.text.trim().isEmpty ||
                                  _offerController.text.trim().isEmpty ||
                                  _locationController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill in Name, Offer, and Location',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (_selectedFileBytes == null &&
                                  (_existingImageUrl == null ||
                                      _existingImageUrl!.isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a poster image',
                                    ),
                                  ),
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
                                  await _restaurants.add(data);
                                } else {
                                  await _restaurants.doc(docId).update(data);
                                }
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      docId == null
                                          ? 'Partner added successfully!'
                                          : 'Partner updated!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          icon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String value,
    required Function(String?) onChanged,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: const [
          DropdownMenuItem(value: 'Food', child: Text('Food')),
          DropdownMenuItem(value: 'Cafe', child: Text('Cafe')),
          DropdownMenuItem(value: 'Services', child: Text('Services')),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: 'Category',
          icon: Icon(Icons.category, color: primaryColor, size: 20),
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRestaurant(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text(
          'Are you sure you want to delete "$name" and its offers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error removing partner: $e')));
        }
      }
    }
  }

  void _showQRCodeDialog(String docId, String name) {
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=himsak_discount:$docId';

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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
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
                    child: Text(
                      'Failed to load QR code. Check internet connection.',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Print this QR code and place it at the counter for students to scan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.3,
              ),
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
                    const SnackBar(
                      content: Text('Could not open QR code link'),
                    ),
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header with search
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discounts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Log Out',
                      onPressed: () {
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Tabs (Restaurants / Claims)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewType = 'Restaurants'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _viewType == 'Restaurants'
                                ? primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Restaurants',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _viewType == 'Restaurants'
                              ? primaryColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewType = 'Claims'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _viewType == 'Claims'
                                ? primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Claims',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _viewType == 'Claims'
                              ? primaryColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conditional content based on view type
          if (_viewType == 'Restaurants') ...[
            // Search bar for restaurants
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: TextField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search restaurants...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children:
                    ['All', 'Food', 'Cafe', 'Services'].map((status) {
                  final isSelected = _currentFilter == status;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _currentFilter = status),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Restaurants List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _restaurants.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                        child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text('No partners registered yet.'),
                    );

                  var docs = snapshot.data!.docs;

                  if (_currentFilter != 'All') {
                    docs = docs
                        .where(
                          (doc) =>
                              (doc.data()
                                  as Map<String, dynamic>)['category'] ==
                              _currentFilter,
                        )
                        .toList();
                  }

                  if (_searchQuery.trim().isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data()
                          as Map<String, dynamic>;
                      final name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final location = (data['location'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(
                              _searchQuery.toLowerCase()) ||
                          location.contains(
                              _searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (docs.isEmpty)
                    return const Center(
                      child: Text(
                          'No partners match your criteria'),
                    );

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'N/A';
                      final category = data['category'] ?? 'N/A';
                      final offer = data['discountOffer'] ?? 'N/A';
                      final location = data['location'] ?? 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                'Offer: $offer',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        color:
                                            Colors.grey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.qr_code,
                                  color: Colors.orange,
                                ),
                                tooltip: 'View QR Code',
                                onPressed: () =>
                                    _showQRCodeDialog(
                                      doc.id,
                                      name,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit Vendor',
                                onPressed: () =>
                                    _showFormDialog(
                                      docId: doc.id,
                                      initialData: data,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Vendor',
                                onPressed: () =>
                                    _deleteRestaurant(
                                      doc.id,
                                      name,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ] else if (_viewType == 'Claims') ...[
            // Search bar for claims
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: TextField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search by name or restaurant...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _claimsSearchQuery = val),
              ),
            ),

            // Claims List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _discountClaims
                    .orderBy('claimedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                        child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text(
                        'No discount claims yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );

                  var claims = snapshot.data!.docs;

                  // Filter by search query
                  if (_claimsSearchQuery.trim().isNotEmpty) {
                    claims = claims.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final studentName = (data['studentName'] ??
                              data['userName'] ??
                          '')
                          .toString()
                          .toLowerCase();
                      final restaurantName = (data[
                              'restaurantName'] ??
                          '')
                          .toString()
                          .toLowerCase();
                      final searchLower =
                          _claimsSearchQuery
                              .toLowerCase();
                      return studentName
                              .contains(searchLower) ||
                          restaurantName
                              .contains(searchLower);
                    }).toList();
                  }

                  if (claims.isEmpty)
                    return const Center(
                      child: Text('No claims match your search'),
                    );

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    itemCount: claims.length,
                    itemBuilder: (context, index) {
                      final claim = claims[index];
                      final data =
                          claim.data() as Map<String, dynamic>;
                      final studentName =
                          data['studentName'] ?? data['userName'] ?? 'Unknown';
                      final studentId =
                          data['studentId'] ?? data['userId'] ?? 'N/A';
                      final restaurantName =
                          data['restaurantName'] ??
                              'Unknown Restaurant';
                      final claimedAt =
                          data['claimedAt'] as Timestamp?;
                      final claimDate = claimedAt != null
                          ? "${claimedAt.toDate().day}/${claimedAt.toDate().month}/${claimedAt.toDate().year} ${claimedAt.toDate().hour}:${claimedAt.toDate().minute.toString().padLeft(2, '0')}"
                          : 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color: Colors
                                                .black87,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 4),
                                        Text(
                                          'ID: $studentId',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: primaryColor
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius
                                              .circular(20),
                                    ),
                                    child: Text(
                                      'Claimed',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.store,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      restaurantName,
                                      style: const TextStyle(
                                        color:
                                            Colors.black87,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    claimDate,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Partner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
