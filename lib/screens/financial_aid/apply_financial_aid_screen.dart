import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class ApplyFinancialAidScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ApplyFinancialAidScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ApplyFinancialAidScreen> createState() => _ApplyFinancialAidScreenState();
}

class _ApplyFinancialAidScreenState extends State<ApplyFinancialAidScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFABText = true;
  String _selectedFilter = 'All';
  final Set<String> _expandedDocIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFABText) setState(() => _showFABText = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFABText) setState(() => _showFABText = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinancialAidFormScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context, String base64Doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.memory(
                  base64Decode(base64Doc),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Approved':
        color = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case 'Rejected':
        color = const Color(0xFFC62828);
        icon = Icons.cancel_rounded;
        break;
      case 'Pending':
      default:
        color = const Color(0xFFEF6C00);
        icon = Icons.watch_later_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats(List<QueryDocumentSnapshot> docs) {
    int total = docs.length;
    int pending = docs.where((d) => (d.data() as Map)['status'] == 'Pending').length;
    int approved = docs.where((d) => (d.data() as Map)['status'] == 'Approved').length;
    int rejected = docs.where((d) => (d.data() as Map)['status'] == 'Rejected').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total', total.toString(), const Color(0xFF8B2247))),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Pending', pending.toString(), const Color(0xFFEF6C00))),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Approved', approved.toString(), const Color(0xFF2E7D32))),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Rejected', rejected.toString(), const Color(0xFFC62828))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(bottom: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(Color primaryColor) {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Aid Applications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Facing a family, medical, or educational emergency? Submit an application for financial assistance here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _navigateToForm(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Apply for Financial Aid',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Financial Aid'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('financial_aid')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs.toList() ?? [];

          if (allDocs.isEmpty) {
            return _buildEmptyState(context);
          }

          allDocs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          // Filter documents
          final filteredDocs = allDocs.where((doc) {
            if (_selectedFilter == 'All') return true;
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildDashboardStats(allDocs),
                  _buildFilterChips(primaryColor),
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? Center(
                            child: Text(
                              'No $_selectedFilter applications found.',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final appData = filteredDocs[index].data() as Map<String, dynamic>;
                              final docId = filteredDocs[index].id;
                              final isExpanded = _expandedDocIds.contains(docId);

                              final reason = appData['reasonType'] ?? 'N/A';
                              final amount = (appData['amount'] as num?)?.toDouble() ?? 0.0;
                              final desc = appData['description'] ?? '';
                              final status = appData['status'] ?? 'Pending';
                              final adminReason = appData['adminReason'] ?? '';
                              final dateObj = appData['createdAt'] as Timestamp?;
                              final dateStr = dateObj != null
                                  ? "${dateObj.toDate().day}/${dateObj.toDate().month}/${dateObj.toDate().year}"
                                  : "N/A";
                              final documentBase64 = appData['documentBase64'] as String?;
                              final hasDocument = documentBase64 != null && documentBase64.isNotEmpty;

                              Color statusColor;
                              switch (status) {
                                case 'Approved':
                                  statusColor = const Color(0xFF2E7D32);
                                  break;
                                case 'Rejected':
                                  statusColor = const Color(0xFFC62828);
                                  break;
                                default:
                                  statusColor = const Color(0xFFEF6C00);
                                  break;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: isExpanded ? 4 : 1,
                                shadowColor: Colors.black.withOpacity(0.08),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedDocIds.remove(docId);
                                      } else {
                                        _expandedDocIds.add(docId);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border(
                                        left: BorderSide(
                                          color: statusColor,
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    reason,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Submitted on: $dateStr',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _buildStatusBadge(status),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'RM ${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              color: Colors.grey.shade600,
                                            ),
                                          ],
                                        ),
                                        AnimatedCrossFade(
                                          firstChild: const SizedBox.shrink(),
                                          secondChild: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Divider(height: 24),
                                              const Text(
                                                'Description',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                desc.isNotEmpty ? desc : 'No description provided.',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  height: 1.4,
                                                ),
                                              ),
                                              if (hasDocument) ...[
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Uploaded Document',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                GestureDetector(
                                                  onTap: () => _viewDocument(context, documentBase64),
                                                  child: Container(
                                                    height: 120,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.grey.shade300),
                                                      color: Colors.grey.shade50,
                                                    ),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        Image.memory(
                                                          base64Decode(documentBase64),
                                                          fit: BoxFit.cover,
                                                        ),
                                                        Container(
                                                          color: Colors.black.withOpacity(0.2),
                                                        ),
                                                        const Center(
                                                          child: CircleAvatar(
                                                            backgroundColor: Colors.white,
                                                            radius: 20,
                                                            child: Icon(Icons.zoom_in_rounded, color: Colors.black87),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (status == 'Rejected' && adminReason.toString().isNotEmpty) ...[
                                                const SizedBox(height: 16),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFEBEE),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFFFFCDD2)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Row(
                                                        children: [
                                                          Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 16),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Feedback from Admin:',
                                                            style: TextStyle(
                                                              color: Color(0xFFC62828),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        adminReason,
                                                        style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13, height: 1.3),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                          duration: const Duration(milliseconds: 200),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply for Aid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        isExtended: _showFABText,
      ),
    );
  }
}

class FinancialAidFormScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FinancialAidFormScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FinancialAidFormScreen> createState() => _FinancialAidFormScreenState();
}

class _FinancialAidFormScreenState extends State<FinancialAidFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String reasonType = 'Medical emergency';
  final amountController = TextEditingController();
  final descController = TextEditingController();

  Uint8List? fileBytes;
  String? fileName;
  bool isLoading = false;

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        Uint8List? bytes = result.files.single.bytes;
        if (bytes == null && result.files.single.path != null) {
          bytes = File(result.files.single.path!).readAsBytesSync();
        }

        if (bytes != null && bytes.length > 800000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File is too large! Please select an image under 800KB.')),
            );
          }
          return;
        }

        setState(() {
          fileBytes = bytes;
          fileName = result.files.single.name;
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

  Future<void> submit() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (fileBytes == null || fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final base64Doc = base64Encode(fileBytes!);

      await FirebaseFirestore.instance.collection('financial_aid').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'reasonType': reasonType,
        'amount': amount,
        'description': descController.text,
        'documentBase64': base64Doc,
        'documentName': fileName,
        'status': 'Pending',
        'adminReason': '',
        'displayOnDashboard': false,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore save timed out. Check your connection or Firebase rules.'),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildUploadBox(Color primaryColor) {
    return InkWell(
      onTap: pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: fileName != null ? primaryColor : Colors.grey.shade400,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          color: fileName != null ? primaryColor.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            if (fileBytes != null) ...[
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  fileBytes!,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      fileName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        fileBytes = null;
                        fileName = null;
                      });
                    },
                  ),
                ],
              ),
            ] else ...[
              Icon(Icons.cloud_upload_outlined, size: 40, color: primaryColor),
              const SizedBox(height: 10),
              Text(
                'Click to upload supporting documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "JPG or PNG images (max 800KB)",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Apply for Financial Aid'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // INFO BOX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD2E3FC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1967D2), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Financial aid requests are reviewed by administrators confidentially. Please provide genuine supporting documents.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1967D2),
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // FORM CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: reasonType,
                        items: const [
                          DropdownMenuItem(
                              value: 'Medical emergency',
                              child: Text('Medical emergency')),
                          DropdownMenuItem(
                              value: 'Family emergency',
                              child: Text('Family emergency')),
                          DropdownMenuItem(
                              value: 'Educational expenses',
                              child: Text('Educational expenses')),
                          DropdownMenuItem(
                              value: 'Transportation',
                              child: Text('Transportation')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() => reasonType = value!);
                        },
                        decoration: _buildInputDecoration('Reason for Aid', Icons.category_outlined, primaryColor),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Amount Requested (RM)', Icons.monetization_on_outlined, primaryColor),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter amount' : null,
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: descController,
                        decoration: _buildInputDecoration('Description', Icons.description_outlined, primaryColor),
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Supporting Document',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildUploadBox(primaryColor),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          onPressed: isLoading ? null : submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
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