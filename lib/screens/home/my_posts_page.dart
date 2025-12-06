import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../services/lost_item_service.dart';
import '../../services/game_service.dart';

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
      
      int active = 0;
      int returned = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'available';
        
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
    final List<dynamic> images = item['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0] : '';
    
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _confirmDeletePost(itemId, title);
                            },
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
  
  void _confirmDeletePost(String itemId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Delete Post?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$title"?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. All associated claims and data will be permanently deleted.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(itemId, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePost(String itemId, String title) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting post...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Get item data before deletion to check rewards earned
      final itemDoc = await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(itemId)
          .get();
      
      final itemData = itemDoc.data();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Check if user earned rewards from this post and reverse them
      if (itemData != null && currentUserId != null) {
        final userId = itemData['userId'];
        
        // Only reverse if current user is the poster
        if (userId == currentUserId) {
          final gameService = GameService();
          
          // Determine which type of reward was given
          final availability = itemData['availability'];
          int totalPoints;
          int totalKarma;
          int totalXP;
          List<String> decrementFields = ['itemsPosted'];
          
          if (availability == 'Drop off location') {
            // User chose drop-off: only gets drop-off rewards (8 pts, 6 karma, 15 XP)
            totalPoints = 8;
            totalKarma = 6;
            totalXP = 15;
          } else {
            // User chose "Keep with me": only gets item post rewards (5 pts, 10 karma, 5 XP)
            totalPoints = 5;
            totalKarma = 10;
            totalXP = 5;
          }
          
          // Add return rewards if item was returned/claimed
          final status = itemData['status'];
          if (status == 'returned' || status == 'claimed') {
            totalPoints += 20;
            totalKarma += 15;
            totalXP += 25;
            decrementFields.add('itemsReturned');
          }
          
          // Make a single call to reverse all rewards at once
          await gameService.reverseRewards(
            points: totalPoints,
            karma: totalKarma,
            xp: totalXP,
            decrementFields: decrementFields,
          );
        }
      }
      
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(itemId)
          .delete();
      
      // Also delete any associated claims
      final claimsSnapshot = await FirebaseFirestore.instance
          .collection('claims')
          .where('itemId', isEqualTo: itemId)
          .get();
      
      for (var doc in claimsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Reload stats
        await _loadStats();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post "$title" deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error deleting post: $e');
    }
  }
  

}
