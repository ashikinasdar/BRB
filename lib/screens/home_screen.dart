import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../screens/financial_aid/apply_financial_aid_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'announcements/announcements_list_screen.dart';
import 'announcements/announcement_detail_screen.dart';
import 'discounts/discounts_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;



  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;



    return Scaffold(
      body: _getBody(context, primaryColor),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), activeIcon: Icon(Icons.local_offer), label: 'Discounts'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), activeIcon: Icon(Icons.handshake), label: 'Aid'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _getBody(BuildContext context, Color primaryColor) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(context, primaryColor);
      case 1:
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const Center(child: Text("Not logged in"));
        }
        return DiscountsListScreen(
          userId: user.uid,
          userName: user.displayName ?? "Student",
        );
      case 2:
        final user = FirebaseAuth.instance.currentUser;


        if (user == null) {
          return const Center(child: Text("Not logged in"));
        }

        return ApplyFinancialAidScreen(
          userId: user.uid,
          userName: user.displayName ?? "Student",
        );
      case 3:
        return _buildProfile(context, primaryColor);
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildDashboard(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        // Header Background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('HIMSAK', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Kelantanese UTM Student Club', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsListScreen())),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text("No announcements yet", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  final title = data['title'] ?? '(no title)';
                  final body = data['body'] ?? '';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final imageUrl = data['imageUrl'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnouncementDetailScreen(announcementId: id),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: imageUrl.startsWith('http')
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : Image.memory(base64Decode(imageUrl), fit: BoxFit.cover),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ]
                              ],
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
      ],
    );
  }

  Widget _buildProfile(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Profile Section Coming Soon", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.logout),
            label: const Text("Log Out"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }


}
