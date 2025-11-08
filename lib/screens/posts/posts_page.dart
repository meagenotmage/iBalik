import 'package:flutter/material.dart';
import '../../utils/page_transitions.dart';
import 'item_details_page.dart';
import 'post_found_item_page.dart';
import '../claims/claims_page.dart';
import '../game/game_hub_page.dart';
import '../home/profile_page.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  int _selectedIndex = 1; // Posts tab is selected
  final TextEditingController _searchController = TextEditingController();
  
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

  final List<Map<String, dynamic>> _foundItems = [
    {
      'id': 1,
      'name': 'Black iPhone 13',
      'description': 'Found near the computer section, has a cracked screen protector.',
      'location': 'Library',
      'time': '2h ago',
      'foundBy': 'John Cruz',
      'image': Icons.phone_iphone,
    },
    {
      'id': 2,
      'name': 'Blue Umbrella',
      'description': 'Navy blue umbrella with wooden handle, left at table 5. Still in good',
      'location': 'Cafeteria',
      'time': '4h ago',
      'foundBy': 'Maria Santos',
      'image': Icons.umbrella,
    },
    {
      'id': 3,
      'name': 'Red Backpack',
      'description': 'Medium-sized red backpack with laptop compartment, found in',
      'location': 'Engineering Building',
      'time': '6h ago',
      'foundBy': 'Alex Rivera',
      'image': Icons.backpack,
    },
    {
      'id': 4,
      'name': 'White Earphones',
      'description': 'Apple AirPods in white case, found on bench near parking area. Both',
      'location': 'Main Parking',
      'time': '1d ago',
      'foundBy': 'Lisa Garcia',
      'image': Icons.headphones,
    },
    {
      'id': 5,
      'name': 'Brown Wallet',
      'description': 'Leather wallet with ID cards still inside, found in restroom. Owner',
      'location': 'Main Building',
      'time': '2d ago',
      'foundBy': 'Mike Torres',
      'image': Icons.account_balance_wallet,
    },
    {
      'id': 6,
      'name': 'Green Water Bottle',
      'description': 'Stainless steel water bottle with university sticker. Appears to be',
      'location': 'Gym',
      'time': '3d ago',
      'foundBy': 'Anna Lopez',
      'image': Icons.water_drop,
    },
    {
      'id': 7,
      'name': 'Black Laptop Charger',
      'description': 'Dell laptop charger with original cable. Found plugged in at the',
      'location': 'Computer Lab',
      'time': '5h ago',
      'foundBy': 'Sarah Kim',
      'image': Icons.power,
    },
    {
      'id': 8,
      'name': 'Blue Notebook',
      'description': 'Spiral notebook with math notes and formulas. Has the owner\'s',
      'location': 'Mathematics Building',
      'time': '1d ago',
      'foundBy': 'Carlos Mendez',
      'image': Icons.book,
    },
  ];

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context); // Go back to home
    } else if (index == 2) {
      // Navigate to Claims page
      Navigator.push(
        context,
        SmoothPageRoute(page: const ClaimsPage()),
      );
    } else if (index == 3) {
      // Navigate to Game Hub page
      Navigator.push(
        context,
        SmoothPageRoute(page: const GameHubPage()),
      );
    } else if (index == 4) {
      // Navigate to Profile page
      Navigator.push(
        context,
        SmoothPageRoute(page: const ProfilePage()),
      );
    } else if (index != 1) {
      // If it's not Posts, Home, Claims, or Game Hub, just update the selected state
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Filter items based on selected category and location
  List<Map<String, dynamic>> _getFilteredItems() {
    return _foundItems.where((item) {
      bool matchesCategory = _selectedCategory == 'All' || _getItemCategory(item) == _selectedCategory;
      bool matchesLocation = _selectedLocation == 'All Locations' || item['location'] == _selectedLocation;
      bool matchesSearch = _searchController.text.isEmpty || 
          item['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item['description'].toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesCategory && matchesLocation && matchesSearch;
    }).toList();
  }

  // Get category for an item based on its icon
  String _getItemCategory(Map<String, dynamic> item) {
    IconData icon = item['image'];
    if (icon == Icons.phone_iphone || icon == Icons.headphones || icon == Icons.power) {
      return 'Electronics';
    } else if (icon == Icons.backpack) {
      return 'Bags';
    } else if (icon == Icons.book) {
      return 'Documents';
    } else if (icon == Icons.account_balance_wallet) {
      return 'Personal Items';
    } else if (icon == Icons.umbrella || icon == Icons.water_drop) {
      return 'Accessories';
    }
    return 'Personal Items';
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
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text(
                      '${_foundItems.length} items',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
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
              child: Builder(
                builder: (context) {
                  final filteredItems = _getFilteredItems();
                  
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
                            'No items found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0),
                _buildNavItem(Icons.search, 'Posts', 1),
                _buildNavItem(Icons.description_outlined, 'Claims', 2),
                _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 3),
                _buildNavItem(Icons.person_outline, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
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
              child: Icon(item['image'], color: Colors.grey[600], size: 32),
            ),
            const SizedBox(width: 16),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'],
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
                      Text(
                        item['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        item['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Found by ${item['foundBy']}',
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
            color: isSelected ? const Color(0xFF4318FF) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF4318FF) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
