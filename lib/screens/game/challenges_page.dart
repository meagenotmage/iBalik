import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_service.dart';
import '../../services/game_data_service.dart';
import '../../utils/app_theme.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GameService _gameService = GameService();
  late GameDataService _gameDataService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update pill tab appearance
    });
    _gameDataService = _gameService.gameData;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _gameDataService.refreshChallenges();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Icons.radio_button_checked,
              color: AppColors.lightText,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Challenges',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: ListenableBuilder(
        listenable: _gameDataService,
        builder: (context, _) {
          return Column(
            children: [
              // Custom Pill Tab Bar with Sliding Indicator
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.darkSurface,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      // Sliding white pill indicator
                      AnimatedBuilder(
                        animation: _tabController.animation!,
                        builder: (context, child) {
                          return Row(
                            children: List.generate(3, (index) {
                              return Expanded(
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: index == _tabController.animation!.value.round()
                                      ? Container(
                                          width: double.infinity,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      // Tab labels
                      Row(
                        children: [
                          Expanded(
                            child: _buildPillTab('Active', 0),
                          ),
                          Expanded(
                            child: _buildPillTab('Completed', 1),
                          ),
                          Expanded(
                            child: _buildPillTab('Upcoming', 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(),
                    _buildCompletedTab(),
                    _buildUpcomingTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillTab(String text, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.white : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    final activeChallenges = _gameDataService.activeChallenges;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _initData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Progress Card
            _buildDailyProgressCard(activeChallenges),
            
            const SizedBox(height: 24),
            
            // Active Challenges Header
            Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Active Challenges',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeChallenges.length} active',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Challenge Cards or Empty State
            if (activeChallenges.isEmpty)
              _buildEmptyState(
                'No Active Challenges',
                'Check back later for new challenges!',
                Icons.check_circle_outline,
              )
            else
              ...activeChallenges.map((challenge) => 
                _buildChallengeCard(challenge)
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressCard(List<UserChallenge> challenges) {
    final dailyChallenges = challenges.where((c) => c.type == ChallengeType.daily).toList();
    final completedDaily = dailyChallenges.where((c) => c.isCompleted).length;
    final totalDaily = dailyChallenges.length;
    final progress = totalDaily > 0 ? completedDaily / totalDaily : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.darkBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Progress',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  totalDaily > 0 ? '$completedDaily/$totalDaily Complete' : 'No daily challenges',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.darkBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            completedDaily < totalDaily 
                ? 'Complete ${totalDaily - completedDaily} more challenge(s) to earn today\'s bonus!'
                : totalDaily > 0 
                    ? '🎉 All daily challenges complete!' 
                    : 'Pull down to refresh challenges',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(UserChallenge challenge) {
    final borderColor = _getDifficultyBorderColor(challenge.difficulty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    challenge.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title and Karma
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            challenge.challengeName,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_outline,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${challenge.rewardKarma} karma',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Time left
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: challenge.isExpired 
                    ? Colors.red.shade400 
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                challenge.timeLeftString,
                style: AppTextStyles.bodySmall.copyWith(
                  color: challenge.isExpired 
                      ? Colors.red.shade400 
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(_getChallengeTypeLabel(challenge.type), 
                  AppColors.darkSurface, AppColors.lightTextSecondary),
              _buildTag(
                _getDifficultyLabel(challenge.difficulty),
                _getDifficultyColor(challenge.difficulty),
                _getDifficultyTextColor(challenge.difficulty),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightText,
                    ),
                  ),
                  Text(
                    '${challenge.currentProgress}/${challenge.targetCount}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: challenge.progressPercent,
                  minHeight: 8,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.monthly:
        return 'Monthly';
      case ChallengeType.special:
        return 'Special';
      case ChallengeType.milestone:
        return 'Milestone';
    }
  }

  String _getDifficultyLabel(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.epic:
        return 'Epic';
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.darkSurface;
      case ChallengeDifficulty.medium:
        return AppColors.primary.withOpacity(0.2);
      case ChallengeDifficulty.hard:
        return AppColors.secondary.withOpacity(0.2);
      case ChallengeDifficulty.epic:
        return AppColors.secondary;
    }
  }

  Color _getDifficultyTextColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.lightTextSecondary;
      case ChallengeDifficulty.medium:
        return AppColors.primary;
      case ChallengeDifficulty.hard:
        return AppColors.secondary;
      case ChallengeDifficulty.epic:
        return AppColors.black;
    }
  }

  Color _getDifficultyBorderColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF10B981).withOpacity(0.5);
      case ChallengeDifficulty.medium:
        return AppColors.primary.withOpacity(0.5);
      case ChallengeDifficulty.hard:
        return AppColors.secondary.withOpacity(0.6);
      case ChallengeDifficulty.epic:
        return AppColors.secondary;
    }
  }

  Widget _buildCompletedTab() {
    final completedChallenges = _gameDataService.completedChallenges;

    return RefreshIndicator(
      onRefresh: _initData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completed Challenges Header
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Completed Challenges',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${completedChallenges.length} completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Completed Challenge Cards or Empty State
            if (completedChallenges.isEmpty)
              _buildEmptyState(
                'No Completed Challenges',
                'Complete challenges to see them here!',
                Icons.emoji_events_outlined,
              )
            else
              ...completedChallenges.map((challenge) => 
                _buildCompletedChallengeCard(challenge)
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedChallengeCard(UserChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                challenge.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.challengeName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCompletedDate(challenge.completedAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Karma and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.rewardKarma} karma',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Complete',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompletedDate(DateTime? date) {
    if (date == null) return 'Completed';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Completed today';
    if (diff.inDays == 1) return 'Completed yesterday';
    if (diff.inDays < 7) return 'Completed ${diff.inDays} days ago';
    if (diff.inDays < 30) return 'Completed ${(diff.inDays / 7).floor()} weeks ago';
    return 'Completed ${(diff.inDays / 30).floor()} months ago';
  }

  Widget _buildUpcomingTab() {
    return RefreshIndicator(
      onRefresh: _initData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upcoming Challenges Header
            Row(
              children: [
                const Icon(
                  Icons.star_outline,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Upcoming Challenges',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Upcoming info card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.darkBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.event,
                    size: 48,
                    color: AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Special Events Coming Soon',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep an eye out for special event challenges during exam weeks, holidays, and campus events!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingEventHint(
                    '⚡',
                    'Weekend Warrior',
                    'Find and post 3 items during weekend',
                    60,
                    'Weekends',
                  ),
                  const SizedBox(height: 12),
                  _buildUpcomingEventHint(
                    '👼',
                    'Exam Week Angel',
                    'Help students find study materials',
                    200,
                    'Exam Weeks',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventHint(
    String icon,
    String title,
    String description,
    int karma,
    String when,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkBorder.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$karma karma',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                when,
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.lightTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
