import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MAIN STUDENT LIST OF DISCOUNTS ---
class DiscountsListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const DiscountsListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DiscountsListScreen> createState() => _DiscountsListScreenState();
}

class _DiscountsListScreenState extends State<DiscountsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _checkAndSeedDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Pre-populate the Firestore database with the 6 mock restaurants if empty
  Future<void> _checkAndSeedDatabase() async {
    setState(() => _isSeeding = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('restaurants').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final collection = FirebaseFirestore.instance.collection('restaurants');

        final mockData = [
          {
            'name': 'Restoran Tok Beng',
            'category': 'Food',
            'discountOffer': '20% OFF for Kelantan students',
            'about': 'Known for the best Kelantanese dishes and traditional culinary delights. Enjoy authentic flavors prepared fresh daily.',
            'location': 'Near Campus, Skudai',
            'operatingHours': '8:00 AM - 10:00 PM',
            'terms': [
              'Valid for HIMSAK members only',
              'Must present a valid student ID card',
              'Valid for dine-in and takeaway',
              'Not valid with other ongoing promotions'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=400&q=80',
          },
          {
            'name': 'Cafe Wau Bulan',
            'category': 'Cafe',
            'discountOffer': '10% OFF all beverages',
            'about': 'A cozy, relaxing coffee shop celebrating East Coast culture. Perfect place to study or catch up with friends.',
            'location': 'UTM Campus',
            'operatingHours': '10:00 AM - 11:00 PM',
            'terms': [
              'Valid for HIMSAK members only',
              'Applies to beverage items only',
              'Minimum purchase of RM5',
              'Valid until 31 December 2026'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
          },
          {
            'name': 'Nasi Kerabu Kak Yah',
            'category': 'Food',
            'discountOffer': '15% OFF any meal',
            'about': 'Homestyle Nasi Kerabu with various lauk options (Ayam Goreng, Daging Bakar, Solok Lada). Made fresh daily with traditional Kelantanese recipes.',
            'location': 'Taman Universiti',
            'operatingHours': '10:00 AM - 6:00 PM',
            'terms': [
              'Valid for HIMSAK members only',
              'Minimum purchase RM10',
              'Not valid on public holidays',
              'Valid until 30 September 2026'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=400&q=80',
          },
          {
            'name': 'Kedai Kopi Lama',
            'category': 'Cafe',
            'discountOffer': 'Buy 1 Free 1 coffee',
            'about': 'Serving traditional charcoal-grilled toast and rich local Kopi. Experience the nostalgic taste of Kelantanese coffee culture.',
            'location': 'Kolej 9',
            'operatingHours': '7:30 AM - 12:00 PM',
            'terms': [
              'Valid for HIMSAK members only',
              'Free item must be of equal or lesser value',
              'Dine-in only',
              'Valid on weekdays only'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1507133750040-4a8f57021571?auto=format&fit=crop&w=400&q=80',
          },
          {
            'name': 'Laundry Express',
            'category': 'Services',
            'discountOffer': 'RM5 OFF min. RM20',
            'about': 'Fast, clean, and reliable self-service laundry facilities. Clean your garments in record time with eco-friendly cleaning detergents.',
            'location': 'Kolej 10',
            'operatingHours': '24 Hours',
            'terms': [
              'Valid for HIMSAK members only',
              'Applicable to washing machines 14kg and above',
              'Requires QR claim verification at the counter token purchase'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?auto=format&fit=crop&w=400&q=80',
          },
          {
            'name': 'Ayam Percik Terengganu',
            'category': 'Food',
            'discountOffer': 'Free drink with set meal',
            'about': 'Serving juicy, wood-fired chicken glazed in a rich, flavorful spiced coconut milk sauce. Made fresh daily.',
            'location': 'Skudai',
            'operatingHours': '4:30 PM - 11:30 PM',
            'terms': [
              'Valid for HIMSAK members only',
              'Requires purchase of any Set Meal',
              'Valid for dine-in only'
            ],
            'imageUrl': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=400&q=80',
          }
        ];

        for (var data in mockData) {
          final docRef = collection.doc();
          batch.set(docRef, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Seeding error: $e');
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Kelantan Deals'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Claim History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClaimHistoryScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: _isSeeding
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelantan Deals',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Exclusive discounts for HIMSAK members',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search restaurants...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              filled: true,
                              fillColor: const Color(0xFFF1F3F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Filter Tabs
                          _buildFilterChips(primaryColor),
                        ],
                      ),
                    ),

                    // Restaurant List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No partners registered yet.'),
                            );
                          }

                          final allRestaurants = snapshot.data!.docs.toList();

                          // Filter by search & category
                          final filteredList = allRestaurants.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '').toString().toLowerCase();
                            final cat = data['category'] ?? '';

                            final matchesCategory = _selectedCategory == 'All' || cat == _selectedCategory;
                            final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());

                            return matchesCategory && matchesSearch;
                          }).toList();

                          if (filteredList.isEmpty) {
                            return const Center(
                              child: Text('No matching restaurants found.'),
                            );
                          }

                          final screenWidth = MediaQuery.of(context).size.width;
                          final crossCount = screenWidth > 600 ? 2 : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              childAspectRatio: screenWidth > 600 ? 1.4 : 1.25,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final restaurant = filteredList[index];
                              final data = restaurant.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'N/A';
                              final discount = data['discountOffer'] ?? 'N/A';
                              final location = data['location'] ?? 'N/A';
                              final imageUrl = data['imageUrl'] ?? '';

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 2,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DiscountDetailScreen(
                                          restaurantId: restaurant.id,
                                          restaurantData: data,
                                          userId: widget.userId,
                                          userName: widget.userName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      Expanded(
                                        flex: 6,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return _buildImageErrorWidget();
                                                    },
                                                  )
                                                : _buildImageErrorWidget(),
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  data['category'] ?? 'Vendor',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Text Details
                                      Expanded(
                                        flex: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      discount,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            location,
                                                            style: const TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withOpacity(0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  size: 18,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
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
                ),
              ),
            ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 4),
            Text(
              'Error loading image',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color primaryColor) {
    final categories = ['All', 'Food', 'Cafe', 'Services'];
    return Row(
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: primaryColor,
            backgroundColor: const Color(0xFFF1F3F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = cat);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

// --- STUDENT VIEW DETAILS SCREEN ---
class DiscountDetailScreen extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> restaurantData;
  final String userId;
  final String userName;

  const DiscountDetailScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantData,
    required this.userId,
    required this.userName,
  });

  @override
  State<DiscountDetailScreen> createState() => _DiscountDetailScreenState();
}

class _DiscountDetailScreenState extends State<DiscountDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final data = widget.restaurantData;
    final name = data['name'] ?? 'N/A';
    final offer = data['discountOffer'] ?? 'N/A';
    final about = data['about'] ?? 'No description available.';
    final location = data['location'] ?? 'N/A';
    final operatingHours = data['operatingHours'] ?? 'N/A';
    final termsList = data['terms'] != null ? List<String>.from(data['terms']) : <String>[];
    final imageUrl = data['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              // Beautiful Header Image
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
                        )
                      : Container(color: Colors.grey.shade300),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Discount Offer Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  offer,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Details Card (About, Location, Hours)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                about,
                                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(Icons.location_on, 'Location', location, primaryColor),
                              const SizedBox(height: 16),
                              _buildDetailItem(Icons.access_time_filled, 'Operating Hours', operatingHours, primaryColor),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Terms & Conditions Card
                        if (termsList.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Terms & Conditions',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                ...termsList.map((term) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('•  ', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                          Expanded(
                                            child: Text(
                                              term,
                                              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Instruction Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To claim this discount',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontSize: 13),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Visit the restaurant and scan the QR code displayed at the counter',
                                      style: TextStyle(color: Color(0xFF5D4037), fontSize: 12, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Scan QR Code Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRScannerSimulationScreen(
                                    restaurantId: widget.restaurantId,
                                    restaurantName: name,
                                    discountOffer: offer,
                                    userId: widget.userId,
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                            label: const Text(
                              'Scan QR Code',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- FUTURISTIC QR CODE SCANNER SIMULATOR ---
class QRScannerSimulationScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String discountOffer;
  final String userId;
  final String userName;

  const QRScannerSimulationScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.discountOffer,
    required this.userId,
    required this.userName,
  });

  @override
  State<QRScannerSimulationScreen> createState() => _QRScannerSimulationScreenState();
}

class _QRScannerSimulationScreenState extends State<QRScannerSimulationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isScanning = false;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSuccessfulScan(String scannedData) async {
    // Validate QR code data. Matches format: himsak_discount:<docId>
    final expectedData = 'himsak_discount:${widget.restaurantId}';
    
    if (scannedData != expectedData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid QR code! Please scan the matching restaurant QR code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isScanning = true);
    
    try {
      // Save claim in Firestore
      final ref = await FirebaseFirestore.instance.collection('discount_claims').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'restaurantId': widget.restaurantId,
        'restaurantName': widget.restaurantName,
        'discountOffer': widget.discountOffer,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show beautiful success popup
      final claimId = ref.id.substring(0, 8).toUpperCase();
      _showSuccessDialog(claimId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming discount: $e')),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showSuccessDialog(String claimId) {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti success header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discount Claimed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Present this screen to the counter to redeem your discount.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRowItem('Vendor', widget.restaurantName),
                    _buildRowItem('Offer', widget.discountOffer),
                    _buildRowItem('Claimed By', widget.userName),
                    _buildRowItem('Claimed On', dateStr),
                    const Divider(height: 20),
                    _buildRowItem('Reference ID', '#$claimId', isBoldValue: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Pop dialog and pop scanner screen back to details page
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Scanner screen
                  },
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
                color: isBoldValue ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'HIMSAK Scanner',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Align the restaurant QR code within the frame',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                      const SizedBox(height: 40),

                      // Futuristic Viewfinder Box
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 260,
                            width: 260,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          
                          // Glowing corners
                          Positioned(
                            top: 0, left: 0,
                            child: _buildCornerWidget(top: true, left: true),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: _buildCornerWidget(top: true, left: false),
                          ),
                          Positioned(
                            bottom: 0, left: 0,
                            child: _buildCornerWidget(top: false, left: true),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: _buildCornerWidget(top: false, left: false),
                          ),

                          // Pulsing animated Laser Line
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, child) {
                              return Positioned(
                                top: 12 + (_laserController.value * 236),
                                child: Container(
                                  width: 236,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.white10),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // TEST SIMULATION DRAWER
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.developer_mode, color: Colors.blueAccent, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Developer Test Console',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Running in emulator mode. Click below to simulate scanning the QR code physically at this restaurant.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  // Simulate correct QR scan
                                  final mockQRData = 'himsak_discount:${widget.restaurantId}';
                                  _handleSuccessfulScan(mockQRData);
                                },
                                icon: const Icon(Icons.sensors, color: Colors.white, size: 18),
                                label: const Text('Simulate Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Manual Input Fallback
                            const Text('OR ENTER QR CODE DATA MANUALLY', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _manualCodeController,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. himsak_discount:docId',
                                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: Colors.black,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onPressed: () {
                                    _handleSuccessfulScan(_manualCodeController.text.trim());
                                  },
                                  child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCornerWidget({required bool top, required bool left}) {
    const length = 24.0;
    const thickness = 4.0;
    const radius = Radius.circular(16);

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? radius : Radius.zero,
          topRight: top && !left ? radius : Radius.zero,
          bottomLeft: !top && left ? radius : Radius.zero,
          bottomRight: !top && !left ? radius : Radius.zero,
        ),
      ),
    );
  }
}

// --- STUDENT DISCOUNT CLAIMS HISTORY ---
class ClaimHistoryScreen extends StatelessWidget {
  final String userId;

  const ClaimHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Claim History'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('discount_claims')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No claims found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You haven\'t claimed any discounts yet. Scan partner QR codes to save!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final tA = (a.data() as Map)['claimedAt'] as Timestamp?;
                final tB = (b.data() as Map)['claimedAt'] as Timestamp?;
                if (tA == null && tB == null) return 0;
                if (tA == null) return 1;
                if (tB == null) return -1;
                return tB.compareTo(tA);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final claim = docs[index].data() as Map<String, dynamic>;
                  final name = claim['restaurantName'] ?? 'N/A';
                  final offer = claim['discountOffer'] ?? 'N/A';
                  final dateObj = claim['claimedAt'] as Timestamp?;
                  final dateStr = dateObj != null
                      ? "${dateObj.toDate().day}/${dateObj.toDate().month}/${dateObj.toDate().year} at ${dateObj.toDate().hour.toString().padLeft(2, '0')}:${dateObj.toDate().minute.toString().padLeft(2, '0')}"
                      : "N/A";
                  final refId = docs[index].id.substring(0, 8).toUpperCase();

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(offer, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Claimed on: $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Reference ID: #$refId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Claimed',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
