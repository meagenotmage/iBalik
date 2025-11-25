import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
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
    return items.where((item) {
      bool matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      bool matchesLocation = _selectedLocation == 'All Locations' || item['location'] == _selectedLocation;
      bool matchesSearch = _searchController.text.isEmpty || 
          item['itemName'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item['description'].toLowerCase().contains(_searchController.text.toLowerCase());
      
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

  void _showFilterBottomSheet() {
    // Create local copies of the state variables
    String localCategory = _selectedCategory;
    String localLocation = _selectedLocation;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: StatefulBuilder(
                  builder: (context, setModalState) => SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                'Found Items',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 56),
                            child: Text(
                              '8 items',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Category Section
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildFilterChip('All', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                              _buildFilterChip('Electronics', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                              _buildFilterChip('Personal Items', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                              _buildFilterChip('Bags', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                              _buildFilterChip('Documents', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                              _buildFilterChip('Accessories', localCategory, (value) {
                                setModalState(() => localCategory = value);
                                setState(() => _selectedCategory = value);
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Location Section
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildFilterChip('All Locations', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Library', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Cafeteria', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Engineering Building', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Main Parking', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Main Building', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                              _buildFilterChip('Gym', localLocation, (value) {
                                setModalState(() => localLocation = value);
                                setState(() => _selectedLocation = value);
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
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
          color: isSelected ? const Color(0xFF4318FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4318FF) : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Found Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.black87),
                        onPressed: _showFilterBottomSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _lostItemService.getLostItems(status: 'available'),
                    builder: (context, snapshot) {
                      int itemCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Text(
                          '$itemCount items',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items, descriptions, locations...',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    // Log the detailed error and show it in the UI for debugging
                    print('Firestore error while loading lost_items: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                  
                  // Convert Firestore documents to list
                  List<Map<String, dynamic>> items = snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    data['docId'] = doc.id;
                    return data;
                  }).toList();
                  // DEBUG: Print all fetched items
                  print('Fetched items from Firestore:');
                  for (var item in items) {
                    print(item);
                  }
                  // Apply filters
                  final filteredItems = _getFilteredItems(items);
                  
                  if (filteredItems.isEmpty) {
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
                            'No items match your filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const ClampingScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            SmoothPageRoute(page: const PostFoundItemPage()),
          );
        },
        backgroundColor: const Color(0xFF4318FF),
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
                _buildNavItem(Icons.search, 'Posts', 1),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, color: Colors.grey[400], size: 32);
                        },
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
