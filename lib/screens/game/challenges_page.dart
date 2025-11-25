import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update pill tab appearance
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Active challenges data
  final List<Map<String, dynamic>> activeChallenges = [
    {
      'icon': '☂️',
      'title': 'Rainy Day Hero',
      'description': 'Help 2 people find their umbrellas during rainy season',
      'karma': 15,
      'timeLeft': '6 hours',
      'type': 'Daily',
      'difficulty': 'Easy',
      'category': 'Weather Items',
      'progress': 1,
      'total': 2,
      'progressColor': Color(0xFF10B981),
    },
    {
      'icon': '📚',
      'title': 'Library Guardian',
      'description': 'Return 5 items found in the library',
      'karma': 50,
      'timeLeft': '3 days',
      'type': 'Weekly',
      'difficulty': 'Medium',
      'category': 'Location-based',
      'progress': 3,
      'total': 5,
      'progressColor': Color(0xFF3B82F6),
    },
    {
      'icon': '📱',
      'title': 'Tech Savior',
      'description': 'Help reunite 3 electronic devices with their owners',
      'karma': 75,
      'timeLeft': '5 days',
      'type': 'Weekly',
      'difficulty': 'Hard',
      'category': 'Electronics',
      'progress': 1,
      'total': 3,
      'progressColor': Color(0xFF3B82F6),
    },
    {
      'icon': '🏛️',
      'title': 'Campus Explorer',
      'description': 'Find items in 4 different buildings this month',
      'karma': 100,
      'timeLeft': '2 weeks',
      'type': 'Monthly',
      'difficulty': 'Epic',
      'category': 'Location-based',
      'progress': 2,
      'total': 4,
      'progressColor': Color(0xFF000000),
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
      body: Column(
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
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Progress Card
          Container(
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
                        '2/3 Complete',
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
                    value: 2 / 3,
                    minHeight: 8,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete one more challenge to earn today\'s bonus!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Challenge Cards
          ...activeChallenges.map((challenge) => 
            _buildChallengeCard(challenge)
          ),
          
          const SizedBox(height: 20),
          
          // View Leaderboards Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to leaderboards
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View Leaderboards',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final borderColor = _getDifficultyBorderColor(challenge['difficulty']);
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
                    challenge['icon'],
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
                            challenge['title'],
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
                              '${challenge['karma']} karma',
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
                      challenge['description'],
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
                color: AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                challenge['timeLeft'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.lightTextSecondary,
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
              _buildTag(challenge['type'], AppColors.darkSurface, AppColors.lightTextSecondary),
              _buildTag(
                challenge['difficulty'],
                _getDifficultyColor(challenge['difficulty']),
                _getDifficultyTextColor(challenge['difficulty']),
              ),
              _buildTag(challenge['category'], AppColors.darkSurface, AppColors.lightTextSecondary),
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
                    '${challenge['progress']}/${challenge['total']}',
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
                  value: challenge['progress'] / challenge['total'],
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.darkSurface;
      case 'medium':
        return AppColors.primary.withOpacity(0.2);
      case 'hard':
        return AppColors.secondary.withOpacity(0.2);
      case 'epic':
        return AppColors.secondary;
      default:
        return AppColors.darkSurface;
    }
  }

  Color _getDifficultyTextColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.lightTextSecondary;
      case 'medium':
        return AppColors.primary;
      case 'hard':
        return AppColors.secondary;
      case 'epic':
        return AppColors.black;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  Color _getDifficultyBorderColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981).withOpacity(0.5);
      case 'medium':
        return AppColors.primary.withOpacity(0.5);
      case 'hard':
        return AppColors.secondary.withOpacity(0.6);
      case 'epic':
        return AppColors.secondary;
      default:
        return AppColors.darkBorder;
    }
  }

  Widget _buildCompletedTab() {
    // Completed challenges data
    final List<Map<String, dynamic>> completedChallenges = [
      {
        'icon': '🎯',
        'title': 'First Steps',
        'description': 'Post your first found item',
        'karma': 25,
        'completedDate': 'Completed 2 days ago',
      },
      {
        'icon': '🤝',
        'title': 'Social Helper',
        'description': 'Help 10 different students find their items',
        'karma': 100,
        'completedDate': 'Completed 1 week ago',
      },
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
            ],
          ),
          const SizedBox(height: 16),
          
          // Completed Challenge Cards
          ...completedChallenges.map((challenge) => 
            _buildCompletedChallengeCard(challenge)
          ),
          
          const SizedBox(height: 20),
          
          // View Leaderboards Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to leaderboards
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View Leaderboards',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompletedChallengeCard(Map<String, dynamic> challenge) {
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
                challenge['icon'],
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
                  challenge['title'],
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge['description'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge['completedDate'],
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
                    '${challenge['karma']} karma',
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

  Widget _buildUpcomingTab() {
    // Upcoming challenges data
    final List<Map<String, dynamic>> upcomingChallenges = [
      {
        'icon': '⚡',
        'title': 'Weekend Warrior',
        'description': 'Find and post 3 items during weekend',
        'karma': 60,
        'startsIn': 'Starts in 2 days',
        'difficulty': 'Medium',
      },
      {
        'icon': '👼',
        'title': 'Exam Week Angel',
        'description': 'Help students find their study materials during exam week',
        'karma': 200,
        'startsIn': 'Starts in 1 week',
        'difficulty': 'Epic',
      },
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
          
          // Upcoming Challenge Cards
          ...upcomingChallenges.map((challenge) => 
            _buildUpcomingChallengeCard(challenge)
          ),
          
          const SizedBox(height: 20),
          
          // View Leaderboards Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to leaderboards
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View Leaderboards',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUpcomingChallengeCard(Map<String, dynamic> challenge) {
    final borderColor = _getDifficultyBorderColor(challenge['difficulty']);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 1,
        ),
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
                challenge['icon'],
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
                  challenge['title'],
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge['description'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge['startsIn'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Karma and Difficulty
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 18,
                    color: AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge['karma']}',
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
                  color: _getDifficultyColor(challenge['difficulty']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  challenge['difficulty'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _getDifficultyTextColor(challenge['difficulty']),
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
}
