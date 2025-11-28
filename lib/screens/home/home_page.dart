// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/lost_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_widgets.dart';
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
import '../../services/game_service.dart'; // Import GameService
import '../../services/game_data_service.dart'; // Import GameDataService

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final LostItemService _lostItemService = LostItemService();
  final GameService _gameService = GameService(); // Instantiate GameService
  late GameDataService _gameDataService;
  int _selectedIndex = 0;
  String _userName = '';
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _gameDataService = _gameService.gameData;
    _loadUserName();
    _loadUserRank();
    // GameService initializes its listener in constructor
  }

  @override
  void dispose() {
    _gameService.dispose(); // Dispose GameService
    super.dispose();
  }

  Future<void> _loadUserRank() async {
    final rank = await _gameDataService.getCurrentUserRank();
    if (mounted) {
      setState(() {
        _userRank = rank;
      });
    }
  }

  Future<void> _loadUserName() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Try to get username from Firestore first
      final username = await _authService.getUserUsername(user.uid);
      if (!mounted) return;

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

  // Format Firestore Timestamp, ISO string, or epoch into a relative "time ago" string
  String _formatTimeAgo(dynamic value) {
    if (value == null) return '';

    DateTime? dateTime;
    try {
      if (value is Timestamp) {
        dateTime = value.toDate();
      } else if (value is String) {
        // Attempt to parse ISO string
        dateTime = DateTime.tryParse(value);
      } else if (value is int) {
        // epoch milliseconds
        dateTime = DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is double) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
    } catch (_) {
      dateTime = null;
    }

    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // Older than a week -> show short date (e.g., Nov 12)
    return '${_shortMonth(dateTime.month)} ${dateTime.day}';
  }

  String _shortMonth(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
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
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: AppShadows.soft,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Image.asset(
                                  'assets/logo_icon.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
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
                          const SizedBox(height: 16),
                          Text(
                            _userName.isEmpty ? _getGreeting() : '${_getGreeting()}, $_userName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ready to help the WVSU community?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Stats Cards
                          ListenableBuilder(
                            listenable: _gameService,
                            builder: (context, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      '${_gameService.karma}',
                                      'Karma',
                                      AppColors.white,
                                      icon: Icons.star_outline,
                                      iconColor: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      '${_gameService.points}',
                                      'Points',
                                      AppColors.white,
                                      icon: Icons.bolt_outlined,
                                      iconColor: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Lvl ${_gameService.currentLevel}',
                                      'Level', // Changed from Rank to Level as Rank is harder to calculate efficiently client-side without a query
                                      AppColors.white,
                                      icon: Icons.emoji_events_outlined,
                                      iconColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
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
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Report Find'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const PostsPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.search_outlined, size: 20),
                                  label: const Text('Browse Posts'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(color: AppColors.lightGray),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Recent Finds Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Finds',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Items List (load recent available items from Firestore)
                    StreamBuilder<QuerySnapshot>(
                      stream: _lostItemService.getLostItems(status: 'available', limit: 3),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ShimmerWidgets.itemList(count: 3),
                          );
                        }

                        if (snapshot.hasError) {
                          // Log and show fallback message
                          print('Error loading recent finds: ${snapshot.error}');
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text('Unable to load recent finds', style: TextStyle(color: Colors.grey[600])),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text('No recent finds', style: TextStyle(color: Colors.grey[600])),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title = data['itemName'] ?? data['itemTitle'] ?? data['itemId'] ?? 'Found Item';
                            final description = data['description'] ?? '';
                            final timeSource = data['datePosted'] ?? data['dateFound'];
                            final time = _formatTimeAgo(timeSource);
                            final location = data['location'] ?? '';
                            final status = (data['status'] ?? 'available').toString().toLowerCase() == 'available' ? 'Available' : (data['status'] ?? '');
                            // Simple icon selection
                            final category = (data['category'] ?? '').toString().toLowerCase();
                            IconData icon = Icons.image;
                            if (category.contains('elect')) {
                              icon = Icons.phone_iphone;
                            } else if (category.contains('bag') || category.contains('backpack')) {
                              icon = Icons.backpack;
                            } else if (category.contains('umbrella')) {
                              icon = Icons.umbrella;
                            }

                            // Pass full Firestore item data so founder name etc. stay correct
                            return _buildItemCard(
                              data,
                              title,
                              description,
                              time.toString(),
                              location,
                              status,
                              icon,
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Game Hub Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 24, color: AppColors.textPrimary),
                              const SizedBox(width: 8),
                              const Text(
                                'Game Hub',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(page: const GameHubPage()),
                              );
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: ListenableBuilder(
                        listenable: _gameDataService,
                        builder: (context, _) {
                          final activeCount = _gameDataService.activeChallenges.length;
                          return Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const ChallengesPage()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildGameCard(
                                    'Challenges',
                                    activeCount > 0 ? '$activeCount active' : 'No active',
                                    AppColors.black,
                                    Icons.flag_outlined,
                                    AppColors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const LeaderboardsPage()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildGameCard(
                                    'Leaderboard',
                                    _userRank > 0 ? 'Rank #$_userRank' : 'Unranked',
                                    AppColors.black,
                                    Icons.emoji_events_outlined,
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? effectiveTextColor,
              size: 24,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ).copyWith(color: effectiveTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ).copyWith(
              color: effectiveTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> data,
    String title,
    String description,
    String time,
    String location,
    String status,
    IconData icon,
  ) {
    // Merge Firestore data with UI overrides so ItemDetailsPage sees the real founder/user fields
    final item = <String, dynamic>{
      ...data,
      'name': title,
      'description': description,
      'time': time,
      'location': location,
      'status': status,
      'image': icon,
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(page: ItemDetailsPage(item: item)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.lightGray.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            // Item Image Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.mediumGray, size: 28),
            ),
            const SizedBox(width: 16),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_outlined, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
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

  Widget _buildGameCard(String title, String subtitle, Color bgColor, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.7),
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
