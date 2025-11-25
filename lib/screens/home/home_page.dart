import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../auth/login_page.dart';
import '../notifications/notifications_page.dart';
import '../posts/posts_page.dart';
import '../posts/item_details_page.dart';
import '../posts/post_found_item_page.dart';
import '../claims/claims_page.dart';
import '../game/game_hub_page.dart';
import '../game/leaderboards_page.dart';
import '../game/challenges_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Try to get username from Firestore first
      final username = await _authService.getUserUsername(user.uid);
      
      if (username != null && username.isNotEmpty) {
        setState(() {
          _userName = username;
        });
      } else {
        // Fallback to display name or email
        String fullName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        String firstName = fullName.split(' ')[0];
        setState(() {
          _userName = firstName;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 18) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> _handleSignOut() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.signOut();
              if (!mounted) return;
              navigator.pop();
              navigator.pushReplacement(
                SmoothReplacementPageRoute(page: const LoginPage()),
              );
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    // Navigate to Posts page when Posts nav item is tapped
    if (index == 1) {
      Navigator.push(
        context,
        SmoothPageRoute(page: const PostsPage()),
      );
    } else if (index == 2) {
      // Navigate to Game Hub page (now in center)
      Navigator.push(
        context,
        SmoothPageRoute(page: const GameHubPage()),
      );
    } else if (index == 3) {
      // Navigate to Claims page
      Navigator.push(
        context,
        SmoothPageRoute(page: const ClaimsPage()),
      );
    } else if (index == 4) {
      // Navigate to Profile page
      Navigator.push(
        context,
        SmoothPageRoute(page: const ProfilePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo
                              Container(
                                width: AppIconSize.xxl,
                                height: AppIconSize.xxl,
                                decoration: BoxDecoration(
                                  color: AppColors.darkGray,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.white,
                                  size: AppIconSize.lg,
                                ),
                              ),
                              // Notification Bell
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SmoothPageRoute(page: const NotificationsPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _userName.isEmpty ? _getGreeting() : '${_getGreeting()}, $_userName',
                            style: AppTextStyles.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Ready to help the WVSU community?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Stats Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '245',
                                  'Karma\nCommunity\nScore',
                                  AppColors.successLight,
                                  icon: Icons.star,
                                  iconColor: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  '850',
                                  'Points\nExchange\nCurrency',
                                  const Color(0xFFE0F2F1),
                                  icon: Icons.bolt,
                                  iconColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  '#8',
                                  'Rank\nCampus',
                                  AppColors.darkGray,
                                  textColor: AppColors.white,
                                  icon: Icons.emoji_events,
                                  iconColor: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const PostFoundItemPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: AppIconSize.md),
                                  label: const Text('Report Find'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const PostsPage()),
                                    );
                                  },
                                  icon: Icon(Icons.search, size: AppIconSize.md, color: AppColors.textPrimary),
                                  label: Text(
                                    'Browse Posts',
                                    style: TextStyle(color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Recent Finds Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Finds',
                            style: AppTextStyles.titleMedium,
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                    ),
                    // Items List
                    _buildItemCard(
                      'Black iPhone 1',
                      'Found near the computer section, has a cracked screen',
                      '2h ago',
                      'Library',
                      'Available',
                      Icons.phone_iphone,
                    ),
                    _buildItemCard(
                      'Blue',
                      'Dark blue umbrella with wooden handle, left at table',
                      '4h ago',
                      'Cafeteria',
                      'Available',
                      Icons.umbrella,
                    ),
                    _buildItemCard(
                      'Red Backpack',
                      'Medium-sized red backup with laptop',
                      '6h ago',
                      'Engineering Building',
                      'Available',
                      Icons.backpack,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Game Hub Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events, size: AppIconSize.md),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Game Hub',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(page: const ChallengesPage()),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: _buildGameCard(
                                'Challenges',
                                '2 active',
                                AppColors.secondary,
                                Icons.flag,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(page: const LeaderboardsPage()),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: _buildGameCard(
                                'Leaderboard',
                                'Rank #8',
                                AppColors.primary,
                                Icons.emoji_events,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar (Fixed)
            Container(
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
                      _buildNavItem(Icons.home, 'Home', 0),
                      _buildNavItem(Icons.search, 'Posts', 1),
                      _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 2),
                      _buildNavItem(Icons.description_outlined, 'Claims', 3),
                      _buildNavItem(Icons.person_outline, 'Profile', 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value, 
    String label, 
    Color bgColor, {
    Color? textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? effectiveTextColor,
              size: AppIconSize.md,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            value,
            style: AppTextStyles.displaySmall.copyWith(
              color: effectiveTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: effectiveTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    String title,
    String description,
    String time,
    String location,
    String status,
    IconData icon,
  ) {
    // Create item map for details page
    final item = {
      'name': title,
      'description': description,
      'time': time,
      'location': location,
      'status': status,
      'image': icon,
      'category': 'Personal Items',
      'foundBy': 'Maria Santos',
      'date': 'November 4, 2024',
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(page: ItemDetailsPage(item: item)),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 6),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            // Item Image Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.mediumGray, size: 30),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: AppIconSize.sm, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        time,
                        style: AppTextStyles.captionLarge,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.location_on, size: AppIconSize.sm, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        location,
                        style: AppTextStyles.captionLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color == AppColors.secondary ? AppColors.black : AppColors.white, size: AppIconSize.lg),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color == AppColors.secondary ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.captionLarge.copyWith(
              color: color == AppColors.secondary ? AppColors.black.withOpacity(0.7) : AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
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
