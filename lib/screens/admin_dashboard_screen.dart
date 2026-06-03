import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../screens/admin/financial_aid_admin_screen.dart';
import '../screens/admin/announcements_admin_screen.dart';
import '../screens/admin/discounts_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _AdminUsersBody(),
    const FinancialAidAdminScreen(),
    const _AdminAnnouncementsBody(),
    const DiscountsAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.monetization_on),
            label: 'Financial Aid',
          ),
          NavigationDestination(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer),
            label: 'Discounts',
          ),
        ],
      ),
    );
  }
}

class _AdminAnnouncementsBody extends StatelessWidget {
  const _AdminAnnouncementsBody();

  @override
  Widget build(BuildContext context) {
    return const AnnouncementsAdminScreen();
  }
}

class _AdminUsersBody extends StatelessWidget {
  const _AdminUsersBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final userDoc = snapshot.data!.docs[index];
                  final user = userDoc.data() as Map<String, dynamic>;
                  final status = user['status'] ?? 'Unknown';
                  final primaryColor = Theme.of(context).colorScheme.primary;
                  
                  Color statusColor = Colors.orange;
                  if (status == 'Approved') statusColor = Colors.green;
                  if (status == 'Rejected') statusColor = Colors.red;

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(user['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(user['email'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.security, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Role: ${user['role'] ?? 'user'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: primaryColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.blue),
                            tooltip: 'View IC',
                            onPressed: () => _showImageDialog(context, user['icImage']),
                          ),
                          if (status == 'Pending Verification' || status == 'Rejected')
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () => _updateStatus(context, userDoc.id, 'Approved'),
                            ),
                          if (status == 'Pending Verification' || status == 'Approved')
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.orange),
                              tooltip: 'Reject',
                              onPressed: () => _updateStatus(context, userDoc.id, 'Rejected'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete User',
                            onPressed: () => _deleteUser(context, userDoc.id, user['fullName'] ?? 'User'),
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
    );
  }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No IC image available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text('Failed to load image')),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String userId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': status,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId, String fullName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete $fullName?'),
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

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }
}