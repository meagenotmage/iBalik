import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../services/lost_item_service.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> with SingleTickerProviderStateMixin {
  final LostItemService _lostItemService = LostItemService();
  late TabController _tabController;
  
  int _totalPosts = 0;
  int _activePosts = 0;
  int _returnedPosts = 0;
  int _totalViews = 0;
  int _totalClaims = 0;
  
  String _selectedFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lost_items')
          .where('userId', isEqualTo: userId)
          .get();
      
      int totalViews = 0;
      int totalClaims = 0;
      int active = 0;
      int returned = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalViews += (data['views'] as num?)?.toInt() ?? 0;
        
        final status = data['status'] as String? ?? 'available';
        
        // Count claims based on claimRequests or claimedBy
        if (data['claimRequests'] is List) {
          totalClaims += (data['claimRequests'] as List).length;
        } else if (data['claimedBy'] != null) {
          totalClaims += 1;
        }
        
        if (status == 'available') {
          active++;
        } else if (status == 'returned') {
          returned++;
        }
      }
      
      if (mounted) {
        setState(() {
          _totalPosts = snapshot.docs.length;
          _activePosts = active;
          _returnedPosts = returned;
          _totalViews = totalViews;
          _totalClaims = totalClaims;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }
  
  Stream<QuerySnapshot> _getFilteredItems() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    
    var query = FirebaseFirestore.instance
        .collection('lost_items')
        .where('userId', isEqualTo: userId)
        .orderBy('datePosted', descending: true);
    
    if (_selectedFilter == 'Active') {
      query = query.where('status', isEqualTo: 'available');
    } else if (_selectedFilter == 'Returned') {
      query = query.where('status', isEqualTo: 'returned');
    }
    
    return query.snapshots();
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
          'My Posts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStats();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Row Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _totalPosts.toString(),
                            'Total Posts',
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _activePosts.toString(),
                            'Active',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _returnedPosts.toString(),
                            'Returned',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom Row Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCardWithIcon(
                            _totalViews.toString(),
                            'Total Views',
                            Icons.visibility,
                            Colors.grey[700]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCardWithIcon(
                            _totalClaims.toString(),
                            'Total Claims',
                            Icons.description_outlined,
                            Colors.grey[700]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Filter Tabs
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterTab('All', _totalPosts),
                    const SizedBox(width: 8),
                    _buildFilterTab('Active', _activePosts),
                    const SizedBox(width: 8),
                    _buildFilterTab('Returned', _returnedPosts),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Items List
              StreamBuilder<QuerySnapshot>(
                stream: _getFilteredItems(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading posts: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final items = snapshot.data?.docs ?? [];
                  
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'All' 
                                  ? 'No posts yet'
                                  : 'No $_selectedFilter posts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start posting found items to help others',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index].data() as Map<String, dynamic>;
                      return _buildItemCard(item, items[index].id);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCardWithIcon(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterTab(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildItemCard(Map<String, dynamic> item, String itemId) {
    final String title = item['itemName'] ?? item['name'] ?? item['title'] ?? 'Untitled';
    final String location = item['location'] ?? 'Unknown location';
    final String status = item['status'] ?? 'available';
    final int views = (item['views'] as num?)?.toInt() ?? 0;
    final List<dynamic> images = item['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0] : '';
    
    // Get claim count
    int claimCount = 0;
    if (item['claimRequests'] is List) {
      claimCount = (item['claimRequests'] as List).length;
    } else if (item['claimedBy'] != null) {
      claimCount = 1;
    }
    
    // Format date
    String dateStr = '';
    if (item['datePosted'] != null) {
      try {
        final date = (item['datePosted'] as Timestamp).toDate();
        dateStr = DateFormat('MMM d').format(date);
      } catch (e) {
        dateStr = 'Unknown';
      }
    }
    
    // Format returned date
    String? returnedDateStr;
    if (status == 'returned' && item['returnedAt'] != null) {
      try {
        final date = (item['returnedAt'] as Timestamp).toDate();
        returnedDateStr = DateFormat('MMM d').format(date);
      } catch (e) {
        returnedDateStr = null;
      }
    }
    
    Color statusColor = status == 'available' 
        ? Colors.blue 
        : status == 'returned' 
            ? Colors.green 
            : Colors.orange;
    
    String statusText = status == 'available' 
        ? 'active' 
        : status == 'returned' 
            ? 'returned' 
            : status;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to item details
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$views views',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$claimCount claims',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (returnedDateStr != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Returned on $returnedDateStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showFilterOptions() {
    // Additional filter options could be implemented here
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All Posts'),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'All';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.radio_button_checked, color: Colors.blue),
                title: const Text('Active Only'),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Active';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Returned Only'),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Returned';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
