import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';import '../posts/posts_page.dart';
import '../game/game_hub_page.dart';
import '../game/leaderboards_page.dart';
import '../game/challenges_page.dart';
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

  // No more mock recent items. Will fetch from Firestore.
  // final List<Map<String, dynamic>> recentItems = [];

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
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Unified Profile Section
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.medium,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // User Profile Section
                    Row(
                      children: [
                        // Profile Picture with Verification Badge
                        Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 3,
                                ),
                                boxShadow: AppShadows.medium,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Color(0xFF4CAF50),
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$department • $year',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                course,
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Edit Button
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: Navigate to edit profile
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.white,
                                  size: AppIconSize.md,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Primary Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.star_rounded,
                            value: karma.toString(),
                            label: 'Karma',
                            subtitle: 'Community Score',
                            color: AppColors.secondary,
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.bolt_rounded,
                            value: points.toString(),
                            label: 'Points',
                            subtitle: 'Exchange Points',
                            color: AppColors.primary,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Secondary Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.emoji_events_rounded,
                            value: '#$rank',
                            label: 'Rank',
                            color: AppColors.mediumGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.autorenew_rounded,
                            value: returned.toString(),
                            label: 'Returned',
                            color: AppColors.mediumGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.local_fire_department_rounded,
                            value: streak.toString(),
                            label: 'Streak',
                            color: AppColors.mediumGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            icon: Icons.star_border_rounded,
                            value: 'Lv $level',
                            label: 'Level',
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bio Section
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.lightGray.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: AppIconSize.md,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.lightGray.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTab('Overview', 0)),
                  Expanded(child: _buildTab('Badges', 1)),
                  Expanded(child: _buildTab('Activity', 2)),
                  Expanded(child: _buildTab('Settings', 3)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            
            // Tab Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildTabContent(),
            ),
            
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      // Bottom Navigation Bar (Standard App Navigation)
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
                _buildNavItem(Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String value,
    required String label,
    String? subtitle,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isPrimary ? AppSpacing.md : AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isPrimary ? AppIconSize.lg : AppIconSize.md,
          ),
          SizedBox(height: isPrimary ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isPrimary ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isPrimary ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isPrimary && subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isSelected ? Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ) : null,
          boxShadow: isSelected ? AppShadows.soft : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            letterSpacing: 0.2,
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
    return Column(
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
                    colors: [AppColors.black, AppColors.black],
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
                    colors: [AppColors.black, AppColors.black],
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
                    colors: [AppColors.black, AppColors.black],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const LeaderboardsPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Challenges',
                  Icons.track_changes,
                  const LinearGradient(
                    colors: [AppColors.black, AppColors.black],
                  ),
                  () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ChallengesPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Items Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
          const SizedBox(height: 8),
        ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              color: label == 'Game Hub' || label == 'Challenges' 
                ? AppColors.secondary 
                : AppColors.primary, 
              size: 28
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
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

    return Padding(
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
            )),
          ],
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
        color: bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
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
    return Padding(
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
                activeThumbColor: const Color(0xFF10B981),
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const PostsPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const GameHubPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const ClaimsPage()));
        break;
      case 4:
        // Already on profile page
        break;
    }

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}
