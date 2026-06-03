import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../screens/admin/financial_aid_admin_screen.dart';
import '../screens/admin/announcements_admin_screen.dart';

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final user = userDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(user['fullName'] ?? 'N/A'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? 'N/A'),
                      Text('Status: ${user['status'] ?? 'Unknown'}'),
                      Text('Role: ${user['role'] ?? 'user'}'),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View IC Image
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.blue),
                        onPressed: () => _showImageDialog(context, user['icImage']),
                      ),
                      // Approve/Reject Buttons
                      if (user['status'] == 'Pending Verification' || user['status'] == 'Rejected')
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateStatus(context, userDoc.id, 'Approved'),
                        ),
                      if (user['status'] == 'Pending Verification' || user['status'] == 'Approved')
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.orange),
                          onPressed: () => _updateStatus(context, userDoc.id, 'Rejected'),
                        ),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(context, userDoc.id, user['fullName']),
                      ),
                    ],
                  ),
                ),
              );
            },
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