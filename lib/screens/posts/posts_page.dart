import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_widgets.dart';
import 'item_details_page.dart';
import 'post_found_item_page.dart';
import '../claims/claims_page.dart';
import '../game/game_hub_page.dart';
import '../home/profile_page.dart';
import '../../services/lost_item_service.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  int _selectedIndex = 1; // Posts tab is selected
  final TextEditingController _searchController = TextEditingController();
  final LostItemService _lostItemService = LostItemService();
  
  // Filter states
  String _selectedCategory = 'All';
  String _selectedLocation = 'All Locations';
  
  // Available filter options
  final List<String> _categories = [
    'All',
    'Electronics',
    'Personal Items',
    'Bags',
    'Documents',
    'Accessories',
    'Clothes',
    'Shoes',
    'Others',
  ];

  final List<String> _locations = [
    'All Locations',
    'Library',
    'CO-OP',
    'College of ICT',
    'College of Nursing',
    'College of Law',
    'Research Building',
    'Binhi',
    'Medicine Gym',
    'Rizal Hall',
    'Admin Building',
    'Mini Forest',
    'Jubilee Park',
    'Quezon Hall',
    'Grandstand',
    'College of Communications',
    'Audio Visual Hall',
    'Cultural Center',
    'Foreign Languages Building',
    'College of Education',
    'College of Business and Management',
    'College of PESCAR',
    'CTE Building',
    'Elementary CO-OP',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Rebuild when search text changes
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to Home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      // Navigate to Game Hub
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const GameHubPage()),
      );
    } else if (index == 3) {
      // Navigate to Claims
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const ClaimsPage()),
      );
    } else if (index == 4) {
      // Navigate to Profile
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const ProfilePage()),
      );
    } else if (index != 1) {
      // For other tabs, just update the selected state
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Filter items based on selected category and location
  List<Map<String, dynamic>> _getFilteredItems(List<Map<String, dynamic>> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final itemName = (item['itemName'] ?? '').toString().toLowerCase();
      final description = (item['description'] ?? '').toString().toLowerCase();
      final location = (item['location'] ?? '').toString().toLowerCase();

      bool matchesCategory = _selectedCategory == 'All' || (item['category'] ?? '') == _selectedCategory;
      bool matchesLocation = _selectedLocation == 'All Locations' || (item['location'] ?? '') == _selectedLocation;

      bool matchesSearch = query.isEmpty ||
          itemName.contains(query) ||
          description.contains(query) ||
          location.contains(query);

      return matchesCategory && matchesLocation && matchesSearch;
    }).toList();
  }

  // Get relative time from timestamp
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Check if current user is the founder of the item
  bool _isCurrentUserFounder(Map<String, dynamic> item) {
    // You'll need to implement this based on your authentication system
    // For now, using a placeholder - replace with your actual user ID logic
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; // Replace with actual current user ID
    final itemUserId = item['userId'] ?? '';
    
    return currentUserId == itemUserId;
  }

  void _showFilterBottomSheet() {
  // Create local copies of the state variables
  String localCategory = _selectedCategory;
  String localLocation = _selectedLocation;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Section
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var cat in _categories) _buildFilterChip(cat, localCategory, (value) {
                            setState(() {
                              localCategory = value;
                              _selectedCategory = value;
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Location Section
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var loc in _locations) _buildFilterChip(loc, localLocation, (value) {
                            setState(() {
                              localLocation = value;
                              _selectedLocation = value;
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
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
}

  Widget _buildFilterChip(String label, String selectedValue, Function(String) onTap) {
    final isSelected = selectedValue == label;
    return InkWell(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post a found item!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> filteredItems) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const ClampingScrollPhysics(),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Found Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: AppShadows.soft,
            ),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _lostItemService.getLostItems(status: 'available'),
                  builder: (context, snapshot) {
                    int itemCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      '$itemCount items',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items, descriptions, locations...',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.standard),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _lostItemService.getLostItems(status: 'available', limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerWidgets.itemList(count: 5);
                }
                
                if (snapshot.hasError) {
                  print('Firestore error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                
                // Convert and filter items
                List<Map<String, dynamic>> items = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  data['docId'] = doc.id;
                  
                  // Debug: Check status of each item
                  print('Item: ${data['itemName']}, Status: ${data['status']}');
                  
                  return data;
                }).toList();
                
                // Additional filtering to ensure only available items are shown
                final availableItems = items.where((item) {
                  final status = item['status']?.toString().toLowerCase();
                  return status == 'available' || status == null; // Include null for backward compatibility
                }).toList();
                
                final filteredItems = _getFilteredItems(availableItems);
                
                return _buildItemsList(filteredItems);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            SmoothPageRoute(page: const PostFoundItemPage()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          boxShadow: AppShadows.nav,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0),
                _buildNavItem(Icons.article_outlined, 'Posts', 1),
                _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 2),
                _buildNavItem(Icons.description_outlined, 'Claims', 3),
                _buildNavItem(Icons.person_outline, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final images = item['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : null;
    final datePosted = item['datePosted'] != null 
        ? (item['datePosted'] as Timestamp).toDate() 
        : DateTime.now();
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(page: ItemDetailsPage(item: item)),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          boxShadow: AppShadows.standard,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.standard),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ShimmerWidgets.imagePlaceholder(
                          width: 70,
                          height: 70,
                          borderRadius: BorderRadius.circular(AppRadius.standard),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      ),
                    )
                  : Icon(Icons.image, color: Colors.grey[400], size: 32),
            ),
            const SizedBox(width: 16),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemName'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item['location'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _getRelativeTime(datePosted),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Found by ${item['userName'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}