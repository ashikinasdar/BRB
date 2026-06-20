import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../screens/financial_aid/apply_financial_aid_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'announcements/announcements_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'events/event_detail_screen.dart';
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
        return const Center(child: Text("Discounts Coming Soon", style: TextStyle(color: Colors.grey)));
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 60,
            left: 24,
            right: 24,
            bottom: 40,
          ),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'HIMSAK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelantanese UTM Student Club',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const AnnouncementsListScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                const Text(
                  "Upcoming Events",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .orderBy(
                    'createdAt',
                    descending: true,
                  )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    final events =
                        snapshot.data!.docs;

                    if (events.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding:
                          EdgeInsets.all(16),
                          child: Text(
                            "No events available",
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: events.map((doc) {
                        final event =
                        doc.data()
                        as Map<String,
                            dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(
                                  eventId: doc.id,
                                  event: event,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                ClipRRect(
                                  borderRadius:
                                  const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: event['imageUrl'] != null &&
                                      event['imageUrl']
                                          .toString()
                                          .isNotEmpty
                                      ? Image.network(
                                    event['imageUrl'],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.event,
                                        size: 70,
                                      ),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding:
                                  const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        event['title'] ?? '',
                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              event['location'] ?? '',
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore
                                            .instance
                                            .collection(
                                            'event_registrations')
                                            .where(
                                          'eventId',
                                          isEqualTo: doc.id,
                                        )
                                            .snapshots(),
                                        builder:
                                            (context, snapshot) {

                                          final count =
                                              snapshot.data?.docs.length ??
                                                  0;

                                          return Text(
                                            "👥 $count Joined",
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Latest Announcements",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(
                      'announcements')
                      .orderBy(
                    'createdAt',
                    descending: true,
                  )
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    final announcements =
                        snapshot.data!.docs;

                    if (announcements
                        .isEmpty) {
                      return const Card(
                        child: Padding(
                          padding:
                          EdgeInsets.all(16),
                          child: Text(
                            "No announcements available",
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: announcements
                          .map((doc) {
                        final announcement =
                        doc.data()
                        as Map<String,
                            dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.campaign,
                              color: Colors.orange,
                            ),
                            title: Text(
                              announcement['title'] ?? '',
                            ),
                            subtitle: Text(
                              announcement['body'] ?? '',
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
