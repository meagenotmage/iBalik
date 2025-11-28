import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_service.dart';
import '../../services/game_data_service.dart';
import '../../utils/app_theme.dart';

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  final GameService _gameService = GameService();
  late GameDataService _gameDataService;
  
  LeaderboardCriteria _selectedCriteria = LeaderboardCriteria.karma;
  List<LeaderboardEntry> _leaderboard = [];
  int _currentUserRank = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameDataService = _gameService.gameData;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _gameDataService.getLeaderboard(criteria: _selectedCriteria, limit: 50),
        _gameDataService.getCurrentUserRank(criteria: _selectedCriteria),
      ]);
      
      setState(() {
        _leaderboard = results[0] as List<LeaderboardEntry>;
        _currentUserRank = results[1] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
        title: Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Leaderboards',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: Column(
        children: [
          // Criteria Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LeaderboardCriteria.values.map((criteria) {
                  final isSelected = criteria == _selectedCriteria;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCriteria = criteria);
                        _loadLeaderboard();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.darkBorder,
                          ),
                        ),
                        child: Text(
                          criteria.displayName,
                          style: TextStyle(
                            color: isSelected ? AppColors.white : AppColors.lightTextSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Current User Rank Card
          if (_currentUserRank > 0)
            _buildCurrentUserRankCard(),
          
          // Leaderboard Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _leaderboard.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        color: AppColors.primary,
                        child: CustomScrollView(
                          slivers: [
                            // Top 3 Podium
                            if (_leaderboard.length >= 3)
                              SliverToBoxAdapter(
                                child: _buildPodium(),
                              ),
                            
                            // Full Rankings
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final startIndex = _leaderboard.length >= 3 ? 3 : 0;
                                    if (startIndex + index >= _leaderboard.length) {
                                      return null;
                                    }
                                    return _buildRankingCard(
                                      _leaderboard[startIndex + index],
                                    );
                                  },
                                  childCount: _leaderboard.length >= 3 
                                      ? _leaderboard.length - 3 
                                      : _leaderboard.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRankCard() {
    return ListenableBuilder(
      listenable: _gameService,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$_currentUserRank',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rank',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      'You are #$_currentUserRank in ${_selectedCriteria.displayName}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getScoreForCriteria(),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedCriteria.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getScoreForCriteria() {
    switch (_selectedCriteria) {
      case LeaderboardCriteria.karma:
        return _gameService.karma.toString();
      case LeaderboardCriteria.points:
        return _gameService.points.toString();
      case LeaderboardCriteria.itemsReturned:
        return _gameService.itemsReturned.toString();
      case LeaderboardCriteria.itemsPosted:
        return _gameService.itemsPosted.toString();
      case LeaderboardCriteria.level:
        return _gameService.currentLevel.toString();
      case LeaderboardCriteria.streak:
        return _gameService.currentStreak.toString();
    }
  }

  Widget _buildPodium() {
    if (_leaderboard.length < 3) return const SizedBox.shrink();
    
    final first = _leaderboard[0];
    final second = _leaderboard[1];
    final third = _leaderboard[2];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          _buildPodiumSpot(second, 2, 100),
          const SizedBox(width: 8),
          // 1st Place
          _buildPodiumSpot(first, 1, 130),
          const SizedBox(width: 8),
          // 3rd Place
          _buildPodiumSpot(third, 3, 80),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(LeaderboardEntry entry, int rank, double height) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    final color = colors[rank]!;
    final score = _getEntryScore(entry);

    return Column(
      children: [
        // Avatar
        Container(
          width: rank == 1 ? 70 : 60,
          height: rank == 1 ? 70 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipOval(
            child: entry.user.profileImageUrl != null
                ? Image.network(
                    entry.user.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialsAvatar(entry.user, color),
                  )
                : _buildInitialsAvatar(entry.user, color),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.user.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Score
        Text(
          score,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: rank == 1 ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 32 : 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(UserStats user, Color borderColor) {
    return Container(
      color: AppColors.darkSurface,
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: borderColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRankingCard(LeaderboardEntry entry) {
    final isTopTen = entry.rank <= 10;
    final score = _getEntryScore(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isTopTen
            ? Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopTen 
                  ? AppColors.secondary.withOpacity(0.2) 
                  : AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  color: isTopTen ? AppColors.secondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.darkBorder,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: entry.user.profileImageUrl != null
                  ? Image.network(
                      entry.user.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildSmallInitialsAvatar(entry.user),
                    )
                  : _buildSmallInitialsAvatar(entry.user),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.user.userName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${entry.user.level}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isTopTen ? AppColors.secondary : AppColors.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _selectedCriteria.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInitialsAvatar(UserStats user) {
    return Container(
      color: AppColors.darkSurface,
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _getEntryScore(LeaderboardEntry entry) {
    switch (_selectedCriteria) {
      case LeaderboardCriteria.karma:
        return entry.user.karma.toString();
      case LeaderboardCriteria.points:
        return entry.user.points.toString();
      case LeaderboardCriteria.itemsReturned:
        return entry.user.itemsReturned.toString();
      case LeaderboardCriteria.itemsPosted:
        return entry.user.itemsPosted.toString();
      case LeaderboardCriteria.level:
        return entry.user.level.toString();
      case LeaderboardCriteria.streak:
        return '${entry.user.currentStreak} days';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: AppColors.lightTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rankings Yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to climb the leaderboard!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
