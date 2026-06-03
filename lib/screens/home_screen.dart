import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../screens/financial_aid/apply_financial_aid_screen.dart';
import 'announcements/announcements_list_screen.dart';
import 'announcements/announcement_detail_screen.dart';
import 'discounts/discounts_list_screen.dart';
import 'profile_screen.dart';

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
      backgroundColor: const Color(0xFFF8F9FA), // Ensure ultra-light background
      body: _getBody(context, primaryColor),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0, primaryColor),
              _buildNavItem(Icons.local_offer_outlined, Icons.local_offer, 'Deals', 1, primaryColor),
              _buildNavItem(Icons.handshake_outlined, Icons.handshake, 'Aid', 2, primaryColor),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, String label, int index, Color primaryColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(isSelected ? selectedIcon : unselectedIcon, color: isSelected ? Colors.white : Colors.grey, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _getBody(BuildContext context, Color primaryColor) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(context, primaryColor);
      case 1:
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return const Center(child: Text("Not logged in"));
        return DiscountsListScreen(userId: user.uid, userName: user.displayName ?? "Student");
      case 2:
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return const Center(child: Text("Not logged in"));
        return ApplyFinancialAidScreen(userId: user.uid, userName: user.displayName ?? "Student");
      case 3:
        return const ProfileScreen();
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildDashboard(BuildContext context, Color primaryColor) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Student';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hello,', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('$userName!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsListScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                shape: BoxShape.circle, 
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                              ),
                              child: const Icon(Icons.notifications_none, color: Colors.black87, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: primaryColor.withOpacity(0.15),
                            child: Icon(Icons.person, color: primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.black45, size: 22),
                        SizedBox(width: 12),
                        Text('Search for deals or updates...', style: TextStyle(color: Colors.black45, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Action Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryIcon(context, Icons.monetization_on, 'Aid', primaryColor, () => setState(() => _currentIndex = 2)),
                      _buildCategoryIcon(context, Icons.local_offer, 'Discounts', primaryColor, () => setState(() => _currentIndex = 1)),
                      _buildCategoryIcon(context, Icons.announcement, 'News', primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsListScreen()))),
                      _buildCategoryIcon(context, Icons.person, 'Profile', primaryColor, () => setState(() => _currentIndex = 3)),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Featured Highlight Card (Upcoming Appointment style)
                  const Text('Upcoming Highlight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.star, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('HIMSAK Annual Meeting', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('General Assembly (Online)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_today, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Sat, 12 Oct 2024', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                              Spacer(),
                              Icon(Icons.access_time, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('10:00 - 12:00 PM', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsListScreen())),
                        child: const Text('See All', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Recent Announcements Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).limit(3).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No updates yet", style: TextStyle(color: Colors.grey)))));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      final title = data['title'] ?? '(no title)';
                      final body = data['body'] ?? '';
                      final imageUrl = data['imageUrl'];
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementDetailScreen(announcementId: id))),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: imageUrl.startsWith('http') ? Image.network(imageUrl, fit: BoxFit.cover) : Image.memory(base64Decode(imageUrl), fit: BoxFit.cover),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                                      child: Icon(Icons.announcement, color: primaryColor, size: 30),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Text(body, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

}
