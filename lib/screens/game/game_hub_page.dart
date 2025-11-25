import 'package:flutter/material.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import 'challenges_page.dart';
import 'badges_page.dart';
import 'leaderboards_page.dart';
import '../posts/posts_page.dart';
import '../claims/claims_page.dart';
import '../home/profile_page.dart';

class GameHubPage extends StatefulWidget {
  const GameHubPage({super.key});

  @override
  State<GameHubPage> createState() => _GameHubPageState();
}

class _GameHubPageState extends State<GameHubPage> {
  int _selectedIndex = 2; // Game Hub tab is selected (center position)
  
  // User stats - TODO: Fetch from Firebase
  final int currentLevel = 3;
  final String levelTitle = 'Campus Hero';
  final int currentXP = 150;
  final int maxXP = 300;
  final int karma = 245;
  final int points = 850;
  
  // Badges - TODO: Fetch from Firebase
  final List<Map<String, dynamic>> badges = [
    {
      'name': 'First Finder',
      'description': 'Found your first item',
      'icon': Icons.search,
      'color': Color(0xFF6366F1),
      'earned': true,
    },
    {
      'name': 'Good Samaritan',
      'description': 'Helped return 3 items',
      'icon': Icons.volunteer_activism,
      'color': Color(0xFF10B981),
      'earned': true,
    },
    {
      'name': 'Campus Hero',
      'description': 'Reached 100 karma',
      'icon': Icons.military_tech,
      'color': Color(0xFF3B82F6),
      'earned': true,
    },
    {
      'name': 'Streak Master',
      'description': 'Return items 7 days in a row',
      'icon': Icons.local_fire_department,
      'color': Color(0xFF9CA3AF),
      'earned': false,
    },
  ];
  
  // Recent achievements
  final List<Map<String, dynamic>> recentAchievements = [
    {
      'name': 'Good Samaritan',
      'description': 'Helped return 3 items',
      'date': '1/14/2024',
      'icon': Icons.volunteer_activism,
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFD1FAE5),
    },
    {
      'name': 'Campus Hero',
      'description': 'Reached 100 karma',
      'date': '1/15/2024',
      'icon': Icons.military_tech,
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFDDD6FE),
    },
  ];
  
  // Active challenges
  final List<Map<String, dynamic>> activeChallenges = [
    {
      'name': 'Weekly Helper',
      'description': 'Help return 3 items this week',
      'type': 'weekly',
      'progress': 2,
      'total': 3,
      'timeLeft': '3 days left',
      'reward': '+15 karma',
      'bgColor': Color(0xFFDDD6FE),
    },
    {
      'name': 'Campus Explorer',
      'description': 'Find items in different buildings',
      'type': 'daily',
      'progress': 1,
      'total': 2,
      'timeLeft': '18 hours left',
      'reward': '+8 karma',
      'bgColor': Color(0xFFDDD6FE),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.lightText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Hub',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.lightText),
            ),
            Text(
              'Your campus hero journey',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Progress Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Profile Picture Placeholder
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.darkSurface,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.lightTextSecondary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level $currentLevel',
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: AppColors.lightText,
                                ),
                              ),
                              Text(
                                levelTitle,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Next Level',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${maxXP - currentXP} XP to go',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: currentXP / maxXP,
                          minHeight: 14,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentXP XP',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '$maxXP XP',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Challenges',
                    Icons.radio_button_checked,
                    AppColors.secondary,
                    AppColors.black,
                    () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const ChallengesPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildQuickActionButton(
                    'Leaderboard',
                    Icons.emoji_events,
                    AppColors.primary,
                    AppColors.white,
                    () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const LeaderboardsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Karma and Points Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    points.toString(),
                                    style: AppTextStyles.displaySmall.copyWith(
                                      color: AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Points',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Currency',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: AppColors.black,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    karma.toString(),
                                    style: AppTextStyles.displaySmall.copyWith(
                                      color: AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Karma',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Public Rep',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Badges Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 24,
                      color: AppColors.lightText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Badges (${badges.where((b) => b['earned']).length}/${badges.length})',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const BadgesPage()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Badges Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: badges.map((badge) => _buildBadgeItem(badge)).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Achievements Section
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 24,
                  color: AppColors.lightText,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Achievements',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Recent Achievements List
            ...recentAchievements.map((achievement) => 
              _buildAchievementCard(achievement)
            ),
            
            const SizedBox(height: 24),
            
            // Active Challenges Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      size: 24,
                      color: AppColors.lightText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Challenges',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ChallengesPage()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Active Challenges List
            ...activeChallenges.map((challenge) => 
              _buildChallengeCard(challenge)
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          boxShadow: AppShadows.nav,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to Home
      Navigator.pop(context);
    } else if (index == 1) {
      // Navigate to Posts
      Navigator.pop(context); // First go back to home
      Navigator.push(
        context,
        SmoothPageRoute(page: const PostsPage()),
      );
    } else if (index == 3) {
      // Navigate to Claims
      Navigator.pop(context); // First go back to home
      Navigator.push(
        context,
        SmoothPageRoute(page: const ClaimsPage()),
      );
    } else if (index == 4) {
      // Navigate to Profile
      Navigator.pop(context); // First go back to home
      Navigator.push(
        context,
        SmoothPageRoute(page: const ProfilePage()),
      );
    } else if (index != 2) {
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

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 32,
            ),
            const SizedBox(height: 8),
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

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final bool earned = badge['earned'];
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: earned ? AppColors.secondary : AppColors.darkBorder,
            shape: BoxShape.circle,
            border: earned ? Border.all(
              color: AppColors.secondary.withOpacity(0.5),
              width: 2,
            ) : null,
          ),
          child: Icon(
            badge['icon'],
            color: earned ? AppColors.black : AppColors.lightTextSecondary,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            badge['name'].split(' ')[0], // First word only
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: earned ? AppColors.lightText : AppColors.lightTextSecondary,
              fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement['icon'],
              color: AppColors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      achievement['name'],
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.lightText,
                      ),
                    ),
                    Text(
                      achievement['date'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final double progress = challenge['progress'] / challenge['total'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  challenge['name'],
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  challenge['type'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge['description'],
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progress',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.darkBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    challenge['timeLeft'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                challenge['reward'],
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${challenge['progress']} / ${challenge['total']}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
