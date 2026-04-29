import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String _baseUrl = 'http://localhost/himsak_api';
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/admin_get_users.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = data['users'];
          });
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _updateStatus(String userId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin_update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'status': status,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
          _fetchUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${data['message']}')));
        }
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _deleteUser(String userId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
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

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin_delete_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
          _fetchUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${data['message']}')));
        }
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imageUrl,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Image not found'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(user['full_name']),
                    subtitle: Text('${user['email']}\nStatus: ${user['status']}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: () {
                            if (user['ic_image_url'] != null) {
                              _showImageDialog(user['ic_image_url']);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No IC image uploaded for this user.')),
                              );
                            }
                          },
                        ),
                        if (user['status'] == 'Pending Verification') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateStatus(user['id'].toString(), 'Approved'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.orange),
                            onPressed: () => _updateStatus(user['id'].toString(), 'Rejected'),
                          ),
                        ] else if (user['status'] == 'Rejected') ...[
                           IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateStatus(user['id'].toString(), 'Approved'),
                          ),
                        ] else if (user['status'] == 'Approved') ...[
                           IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.orange),
                            onPressed: () => _updateStatus(user['id'].toString(), 'Rejected'),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['id'].toString()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
