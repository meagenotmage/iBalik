import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/page_transitions.dart';
import '../game/game_hub_page.dart';
import '../game/leaderboards_page.dart';
import '../game/challenges_page.dart';
import '../posts/posts_page.dart';
import '../claims/claims_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTabIndex = 0;
  int _selectedIndex = 4; // Profile tab is selected

  // User data - TODO: Fetch from Firebase
  String userName = 'username';
  String department = 'CICT';
  String course = 'BS Information Technology';
  String year = '3rd Year';
  String bio =
      'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!';

  // Stats
  int karma = 90;
  int points = 245;
  int rank = 8;
  int returned = 12;
  int streak = 5;
  int level = 3;

  // Recent items
  final List<Map<String, dynamic>> recentItems = [
    {
      'name': 'Black iPhone 13',
      'location': 'Library',
      'status': 'Active',
      'image': Icons.phone_iphone,
    },
    {
      'name': 'Blue Umbrella',
      'location': 'Cafeteria',
      'status': 'Returned',
      'image': Icons.umbrella,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            // Try username first, then fall back to full name, then email, then default
            final username = data?['username'] as String?;
            final fullName = data?['name'] as String?;
            userName =
                username ??
                fullName ??
                user.displayName ??
                user.email?.split('@')[0] ??
                'User Name';

            department = data?['department'] ?? 'CICT';
            course = data?['course'] ?? 'BS Computer Science';
            year = data?['year'] ?? '3rd Year';
            bio =
                data?['bio'] ??
                'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!';
            karma = data?['karma'] ?? 90;
            points = data?['points'] ?? 245;
            rank = data?['rank'] ?? 8;
            returned = data?['returned'] ?? 12;
            streak = data?['streak'] ?? 5;
            level = data?['level'] ?? 3;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Profile Header
                SliverAppBar(
                  expandedHeight: 580,
                  floating: false,
                  pinned: false,
                  backgroundColor: const Color(0xFF6366F1),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            children: [
                              // Profile Picture with Verification Badge
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(17),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Color(0xFFFFC107),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // User Name
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Department and Year
                              Text(
                                '$department • $year',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Course
                              Text(
                                course,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Edit Profile Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to edit profile
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Karma and Points Row
                              Row(
                                children: [
                                  // Karma Card
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4318FF,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Color(0xFFFFC107),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Karma',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            karma.toString(),
                                            style: const TextStyle(
                                              color: Color(0xFFFFC107),
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Community Score',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Points Card
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4318FF,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.bolt,
                                                color: Color(0xFF60A5FA),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Points',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            points.toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF60A5FA),
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                'Tap to exchange',
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white60,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Stats Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatBox(
                                    Icons.emoji_events,
                                    '#$rank',
                                    'Rank',
                                  ),
                                  _buildStatBox(
                                    Icons.autorenew,
                                    returned.toString(),
                                    'Returned',
                                  ),
                                  _buildStatBox(
                                    Icons.local_fire_department,
                                    streak.toString(),
                                    'Streak',
                                  ),
                                  _buildStatBox(
                                    Icons.star,
                                    'Lv $level',
                                    'Level',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content Section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Bio Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          bio,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Navigation
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(child: _buildTab('Overview', 0)),
                            Expanded(child: _buildTab('Badges', 1)),
                            Expanded(child: _buildTab('Activity', 2)),
                            Expanded(child: _buildTab('Settings', 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Content
                      _buildTabContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Bar
          Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.search, 'Posts', 1),
                    _buildNavItem(Icons.description_outlined, 'Claims', 2),
                    _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 3),
                    _buildNavItem(Icons.person_outline, 'Profile', 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF4318FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildOverviewTab();
    } else if (_selectedTabIndex == 1) {
      return _buildBadgesTab();
    } else if (_selectedTabIndex == 2) {
      return _buildActivityTab();
    } else {
      return _buildSettingsTab();
    }
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Grid
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Game Hub',
                  Icons.emoji_events,
                  const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const GameHubPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'My Posts',
                  Icons.inventory_2,
                  const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const PostsPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Leaderboard',
                  Icons.people,
                  const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const LeaderboardsPage()),
                    );
                  },
                  textColor: Colors.black87,
                  withBorder: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Challenges',
                  Icons.track_changes,
                  const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ChallengesPage()),
                    );
                  },
                  textColor: Colors.black87,
                  withBorder: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Items Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: View all items
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Items List
          ...recentItems.map((item) => _buildRecentItemCard(item)).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap, {
    Color textColor = Colors.white,
    bool withBorder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: withBorder
              ? Border.all(color: Colors.grey[300]!, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItemCard(Map<String, dynamic> item) {
    final isActive = item['status'] == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['image'], size: 28, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item['location'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    // Sample badge data - TODO: Fetch from Firebase
    final earnedBadges = [
      {
        'icon': Icons.search,
        'name': 'First Find',
        'description': 'Posted your first found item',
        'color': Colors.white,
        'bgColor': Colors.grey[100],
      },
      {
        'icon': Icons.volunteer_activism,
        'name': 'Helper',
        'description': 'Helped 5 people find their items',
        'color': Colors.white,
        'bgColor': Colors.grey[100],
      },
      {
        'icon': Icons.bolt,
        'name': 'Speed Returner',
        'description': 'Returned item within 24 hours',
        'color': Color(0xFF8B5CF6),
        'bgColor': Color(0xFFF3E8FF),
      },
      {
        'icon': Icons.star,
        'name': 'Community Star',
        'description': 'Reached top 10 on leaderboard',
        'color': Colors.white,
        'bgColor': Colors.grey[100],
      },
    ];

    final lockedBadges = [
      {
        'icon': Icons.emoji_events,
        'name': 'Perfect Week',
        'description': 'Found 7 items in one week',
      },
      {
        'icon': Icons.auto_awesome,
        'name': 'Karma Master',
        'description': 'Reached 100 karma points',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Earned Badges Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Earned (${earnedBadges.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Earned Badges Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: earnedBadges.length,
              itemBuilder: (context, index) {
                final badge = earnedBadges[index];
                return _buildBadgeCard(
                  icon: badge['icon'] as IconData,
                  name: badge['name'] as String,
                  description: badge['description'] as String,
                  color: badge['color'] as Color,
                  bgColor: badge['bgColor'] as Color,
                  isLocked: false,
                );
              },
            ),
            const SizedBox(height: 32),

            // Locked Badges Section
            Text(
              'Locked (${lockedBadges.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Locked Badges Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: lockedBadges.length,
              itemBuilder: (context, index) {
                final badge = lockedBadges[index];
                return _buildBadgeCard(
                  icon: badge['icon'] as IconData,
                  name: badge['name'] as String,
                  description: badge['description'] as String,
                  color: Colors.grey[400]!,
                  bgColor: Colors.grey[100]!,
                  isLocked: true,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard({
    required IconData icon,
    required String name,
    required String description,
    required Color color,
    required Color bgColor,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked ? Colors.grey[300]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isLocked ? Colors.grey[400] : color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey[500] : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    // Sample activity data - TODO: Fetch from Firebase
    final activities = [
      {
        'type': 'returned',
        'icon': Icons.check_circle,
        'iconColor': Color(0xFF10B981),
        'bgColor': Color(0xFFD1FAE5),
        'title': 'Item Successfully Returned',
        'description': 'Blue Umbrella was claimed and returned',
        'time': '2 days ago',
      },
      {
        'type': 'posted',
        'icon': Icons.add_box,
        'iconColor': Color(0xFF6366F1),
        'bgColor': Color(0xFFE0E7FF),
        'title': 'New Item Posted',
        'description': 'Posted Black iPhone 13 found in Library',
        'time': '5 days ago',
      },
      {
        'type': 'achievement',
        'icon': Icons.emoji_events,
        'iconColor': Color(0xFFF59E0B),
        'bgColor': Color(0xFFFEF3C7),
        'title': 'Achievement Unlocked',
        'description': 'Earned "Community Star" badge',
        'time': '1 week ago',
      },
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Activity Timeline Items
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityCard(
                icon: activity['icon'] as IconData,
                iconColor: activity['iconColor'] as Color,
                bgColor: activity['bgColor'] as Color,
                title: activity['title'] as String,
                description: activity['description'] as String,
                time: activity['time'] as String,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
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
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              title: 'Push Notifications',
              subtitle: 'Get notified about claims and updates',
              hasSwitch: true,
              switchValue: true,
              onSwitchChanged: (value) {
                // TODO: Handle push notification toggle
              },
            ),
            
            _buildSettingItem(
              title: 'Email Notifications',
              subtitle: 'Receive emails for important updates',
              hasSwitch: true,
              switchValue: true,
              onSwitchChanged: (value) {
                // TODO: Handle email notification toggle
              },
            ),
            
            _buildSettingItem(
              title: 'Claim Notifications',
              subtitle: 'When someone claims your items',
              hasSwitch: true,
              switchValue: true,
              onSwitchChanged: (value) {
                // TODO: Handle claim notification toggle
              },
            ),
            
            const SizedBox(height: 32),
            
            // Privacy Section
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              title: 'Public Profile',
              subtitle: 'Allow others to view your profile',
              hasSwitch: true,
              switchValue: true,
              onSwitchChanged: (value) {
                // TODO: Handle public profile toggle
              },
            ),
            
            _buildSettingItem(
              title: 'Show Statistics',
              subtitle: 'Display your stats on leaderboards',
              hasSwitch: true,
              switchValue: true,
              onSwitchChanged: (value) {
                // TODO: Handle statistics toggle
              },
            ),
            
            const SizedBox(height: 32),
            
            // Account Section
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              title: 'Export My Data',
              hasArrow: true,
              onTap: () {
                // TODO: Navigate to export data
              },
            ),
            
            _buildSettingItem(
              title: 'Help & Support',
              hasArrow: true,
              onTap: () {
                // TODO: Navigate to help & support
              },
            ),
            
            const SizedBox(height: 16),
            
            // Sign Out Button
            InkWell(
              onTap: () async {
                // Show confirmation dialog
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // Sign out from Firebase
                    await FirebaseAuth.instance.signOut();
                    
                    // Navigate to login page and remove all previous routes
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    // Show error message if sign out fails
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    bool hasArrow = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: hasArrow ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: const Color(0xFF10B981),
              ),
            if (hasArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to Home
      Navigator.pop(context);
    } else if (index == 1) {
      // Navigate to Posts
      Navigator.pop(context); // First go back to home
      Navigator.push(context, SmoothPageRoute(page: const PostsPage()));
    } else if (index == 2) {
      // Navigate to Claims
      Navigator.pop(context); // First go back to home
      Navigator.push(context, SmoothPageRoute(page: const ClaimsPage()));
    } else if (index == 3) {
      // Navigate to Game Hub
      Navigator.pop(context); // First go back to home
      Navigator.push(context, SmoothPageRoute(page: const GameHubPage()));
    } else if (index != 4) {
      // For other tabs, just update the selected state
      setState(() {
        _selectedIndex = index;
      });
    }
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
