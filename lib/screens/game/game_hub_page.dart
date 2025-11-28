import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/game_data_service.dart';
import 'challenges_page.dart';
import 'badges_page.dart';
import 'leaderboards_page.dart';
import '../posts/posts_page.dart';
import '../claims/claims_page.dart';
import '../home/profile_page.dart';
import '../store/points_store_page.dart';

class GameHubPage extends StatefulWidget {
  const GameHubPage({super.key});

  @override
  State<GameHubPage> createState() => _GameHubPageState();
}

class _GameHubPageState extends State<GameHubPage> {
  int _selectedIndex = 2; // Game Hub tab is selected (center position)
  
  // Use GameService for real-time stats
  final GameService _gameService = GameService();
  late GameDataService _gameDataService;
  

  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _gameDataService = _gameService.gameData;
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // Ensure default data is seeded and user challenges are assigned
      await _gameDataService.initializeDefaultData();
      await _gameDataService.initialize();
      await _gameDataService.refreshChallenges();
      await _loadRecentAchievements();
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing game data: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadRecentAchievements() async {
    try {
      final achievements = await _gameDataService.getRecentAchievements(limit: 5);
      setState(() {

      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to Home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      // Navigate to Posts
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const PostsPage()),
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
    }
    // index == 2 is current page (Game Hub)
  }

  @override
  void dispose() {
    _gameService.dispose();
    super.dispose();
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Novice Finder';
    if (level < 10) return 'Scout';
    if (level < 20) return 'Ranger';
    if (level < 30) return 'Guardian';
    if (level < 50) return 'Hero';
    return 'Legend';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth >= 600;
    
    // Responsive values
    final horizontalPadding = isSmallScreen ? 12.0 : (isLargeScreen ? 24.0 : AppSpacing.lg);
    final profileSize = isSmallScreen ? 40.0 : (isLargeScreen ? 60.0 : 50.0);
    final profileIconSize = isSmallScreen ? 24.0 : (isLargeScreen ? 36.0 : 30.0);
    final levelFontSize = isSmallScreen ? 18.0 : (isLargeScreen ? 26.0 : 22.0);
    final subtitleFontSize = isSmallScreen ? 12.0 : (isLargeScreen ? 16.0 : 14.0);
    final smallFontSize = isSmallScreen ? 10.0 : (isLargeScreen ? 14.0 : 12.0);
    final sectionTitleFontSize = isSmallScreen ? 16.0 : (isLargeScreen ? 24.0 : 20.0);
    final cardSpacing = isSmallScreen ? 12.0 : 16.0;
    final sectionSpacing = isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Game Hub',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _gameDataService.refreshChallenges();
          await _loadRecentAchievements();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Level Section (White Background)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: ListenableBuilder(
                  listenable: _gameService,
                  builder: (context, child) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.md, horizontalPadding, AppSpacing.xl),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    // Profile Picture Placeholder
                                    Container(
                                      width: profileSize,
                                      height: profileSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.background,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: AppColors.textSecondary,
                                        size: profileIconSize,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 10 : 16),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Level ${_gameService.currentLevel}',
                                            style: TextStyle(
                                              fontSize: levelFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _getLevelTitle(_gameService.currentLevel),
                                            style: TextStyle(
                                              fontSize: subtitleFontSize,
                                              color: AppColors.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Next Level',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_gameService.maxXP - _gameService.currentXP} XP to go',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: sectionSpacing),
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _gameService.maxXP > 0 
                                      ? _gameService.currentXP / _gameService.maxXP 
                                      : 0,
                                  minHeight: isSmallScreen ? 8 : 12,
                                  backgroundColor: AppColors.lightGray,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_gameService.currentXP} XP',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_gameService.maxXP} XP',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Dark Content Below
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sectionSpacing),
                    
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
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: cardSpacing),
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
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: sectionSpacing),
                    
                    // Karma and Points Cards
                    ListenableBuilder(
                      listenable: _gameService,
                      builder: (context, child) {
                        return Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    SmoothPageRoute(page: PointsStorePage()),
                                  );
                                },
                                child: _buildStatCard(
                                  _gameService.points.toString(),
                                  'Points',
                                  'Currency',
                                  Icons.bolt,
                                  AppColors.primary,
                                  isSmallScreen: isSmallScreen,
                                  isTappable: true,
                                ),
                              ),
                            ),
                            SizedBox(width: cardSpacing),
                            Expanded(
                              child: _buildStatCard(
                                _gameService.karma.toString(),
                                'Karma',
                                'Public Rep',
                                Icons.star,
                                AppColors.secondary,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    SizedBox(height: sectionSpacing),
                    
                    // Badges Section
                    ListenableBuilder(
                      listenable: _gameDataService,
                      builder: (context, _) {
                        final earnedBadges = _gameDataService.earnedBadges;
                        final totalBadges = _gameDataService.allBadgeDefinitions.length;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.workspace_premium,
                                        size: isSmallScreen ? 20 : 24,
                                        color: AppColors.lightText,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Flexible(
                                        child: Text(
                                          'Badges (${earnedBadges.length}/${totalBadges})',
                                          style: TextStyle(
                                            fontSize: sectionTitleFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const BadgesPage()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
                                  ),
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: cardSpacing),
                            
                            // Badges Grid
                            _buildBadgesGrid(earnedBadges, isSmallScreen: isSmallScreen),
                          ],
                        );
                      },
                    ),
                    
                    SizedBox(height: sectionSpacing),
                    
                    // Not Yet Completed Badges Section
                    Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          size: isSmallScreen ? 18 : 22,
                          color: AppColors.lightText,
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          'Not Yet Completed',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: cardSpacing),
                    _buildIncompleteBadges(isSmallScreen: isSmallScreen),
                    
                    SizedBox(height: sectionSpacing),
                    
                    // Active Challenges Section
                    ListenableBuilder(
                      listenable: _gameDataService,
                      builder: (context, _) {
                        final activeChallenges = _gameDataService.activeChallenges;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flash_on,
                                        size: isSmallScreen ? 18 : 22,
                                        color: AppColors.lightText,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Flexible(
                                        child: Text(
                                          'Active Challenges (${activeChallenges.length})',
                                          style: TextStyle(
                                            fontSize: sectionTitleFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      SmoothPageRoute(page: const ChallengesPage()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
                                  ),
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: cardSpacing),
                            
                            // Challenge Cards
                            if (activeChallenges.isEmpty)
                              _buildEmptyState(
                                'No active challenges',
                                'Check back later for new challenges!',
                                isSmallScreen: isSmallScreen,
                              )
                            else
                              ...activeChallenges.take(3).map((challenge) => 
                                _buildChallengeCard(challenge, isSmallScreen: isSmallScreen)
                              ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isSmallScreen: isSmallScreen),
    );
  }

  Widget _buildStatCard(String value, String label, String subtitle, IconData icon, Color color, {bool isSmallScreen = false, bool isTappable = false}) {
    final cardPadding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;
    final iconSize = isSmallScreen ? 18.0 : 22.0;
    final valueFontSize = isSmallScreen ? 20.0 : 24.0;
    final labelFontSize = isSmallScreen ? 10.0 : 12.0;
    final subtitleFontSize = isSmallScreen ? 9.0 : 11.0;
    
    return Container(
      height: isSmallScreen ? 120 : 140,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: isTappable ? color : color.withOpacity(0.3),
          width: isTappable ? 2.0 : 1.0,
        ),
        boxShadow: isTappable ? AppShadows.standard : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
                child: Icon(
                  icon,
                  color: color == AppColors.secondary ? AppColors.black : AppColors.white,
                  size: iconSize,
                ),
              ),
              const Spacer(),
              if (isTappable)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.lightTextSecondary,
                  size: isSmallScreen ? 12.0 : 14.0,
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.lightText,
            ),
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            '$label • $subtitle',
            style: TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(List<UserBadge> badges, {bool isSmallScreen = false}) {
    final iconContainerSize = isSmallScreen ? 32.0 : 40.0;
    final iconFontSize = isSmallScreen ? 16.0 : 20.0;
    final nameFontSize = isSmallScreen ? 9.0 : 10.0;
    final itemPadding = isSmallScreen ? 6.0 : 10.0;
    final itemSpacing = isSmallScreen ? 8.0 : 12.0;
    
    if (badges.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Center(
          child: Text(
            'No badges earned yet. Complete challenges to earn badges!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
      );
    }

    // Show max 4 badges in a row that fills the width
    final badgesToShow = badges.take(4).toList();
    
    return Row(
      children: List.generate(badgesToShow.length, (index) {
        final badge = badgesToShow[index];
        final rarityColor = _getRarityColor(badge.rarity);
        
        return Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const BadgesPage()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: index < badgesToShow.length - 1 ? itemSpacing : 0),
              padding: EdgeInsets.all(itemPadding),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(AppRadius.standard),
                border: Border.all(
                  color: rarityColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: TextStyle(fontSize: iconFontSize),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF10B981);
      case BadgeRarity.rare:
        return const Color(0xFF3B82F6);
      case BadgeRarity.epic:
        return const Color(0xFF8B5CF6);
      case BadgeRarity.legendary:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _buildIncompleteBadges({bool isSmallScreen = false}) {
    return ListenableBuilder(
      listenable: _gameDataService,
      builder: (context, _) {
        final availableBadges = _gameDataService.getAvailableBadgesWithProgress();
        final cardPadding = isSmallScreen ? 12.0 : 16.0;
        final iconContainerSize = isSmallScreen ? 38.0 : 45.0;
        final iconFontSize = isSmallScreen ? 18.0 : 22.0;
        final titleFontSize = isSmallScreen ? 12.0 : 14.0;
        final subtitleFontSize = isSmallScreen ? 10.0 : 12.0;
        final itemSpacing = isSmallScreen ? 10.0 : 16.0;
        
        if (_isLoading) {
          return Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (availableBadges.isEmpty) {
          return _buildEmptyState(
            'All badges completed!',
            'Congratulations! You have earned all available badges.',
            isSmallScreen: isSmallScreen,
          );
        }

        // Show only first 3 incomplete badges
        final badgesToShow = availableBadges.take(3).toList();
        
        return Column(
          children: badgesToShow.map((badgeData) {
            final def = badgeData['definition'] as BadgeDefinition;
            final progress = badgeData['progress'] as double;
            final rarityColor = _getRarityColor(def.rarity);
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(AppRadius.standard),
                border: Border.all(
                  color: rarityColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                        ),
                        child: Center(
                          child: Text(
                            def.icon,
                            style: TextStyle(
                              fontSize: iconFontSize,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      if (progress > 0)
                        SizedBox(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: itemSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.name,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          def.unlockCondition,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: rarityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }



  Widget _buildChallengeCard(UserChallenge challenge, {bool isSmallScreen = false}) {
    final cardPadding = isSmallScreen ? 12.0 : 16.0;
    final iconContainerSize = isSmallScreen ? 34.0 : 40.0;
    final iconFontSize = isSmallScreen ? 18.0 : 22.0;
    final titleFontSize = isSmallScreen ? 12.0 : 14.0;
    final subtitleFontSize = isSmallScreen ? 10.0 : 12.0;
    final badgeFontSize = isSmallScreen ? 9.0 : 11.0;
    final itemSpacing = isSmallScreen ? 10.0 : 12.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                ),
                child: Center(
                  child: Text(
                    challenge.icon,
                    style: TextStyle(fontSize: iconFontSize),
                  ),
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.challengeName,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      challenge.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 10, 
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
                child: Text(
                  '+${challenge.rewardKarma} karma',
                  style: TextStyle(
                    fontSize: badgeFontSize,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: isSmallScreen ? 5 : 6,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: itemSpacing),
              Text(
                '${challenge.currentProgress}/${challenge.targetCount}',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isSmallScreen ? 12 : 14,
                color: AppColors.lightTextSecondary,
              ),
              SizedBox(width: isSmallScreen ? 3 : 4),
              Text(
                challenge.timeLeftString,
                style: TextStyle(
                  fontSize: badgeFontSize,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: isSmallScreen ? 32 : 40,
            color: AppColors.lightTextSecondary.withOpacity(0.5),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: AppColors.lightTextSecondary,
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
    Color iconColor, 
    VoidCallback onTap, {
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmallScreen ? 120 : 140,
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: isSmallScreen ? 24 : 28),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar({bool isSmallScreen = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? AppSpacing.md : AppSpacing.lg, 
            vertical: isSmallScreen ? 4 : AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0, isSmallScreen: isSmallScreen),
              _buildNavItem(Icons.article_outlined, 'Posts', 1, isSmallScreen: isSmallScreen),
              _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 2, isSmallScreen: isSmallScreen),
              _buildNavItem(Icons.description_outlined, 'Claims', 3, isSmallScreen: isSmallScreen),
              _buildNavItem(Icons.person_outline, 'Profile', 4, isSmallScreen: isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isSmallScreen = false}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
            size: isSmallScreen ? 22 : 26,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
