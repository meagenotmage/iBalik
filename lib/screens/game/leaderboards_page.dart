import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenges_page.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../services/game_service.dart'; // Import GameService

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  final GameService _gameService = GameService(); // Instantiate GameService
  String selectedCollege = 'All Colleges';
  String selectedTimePeriod = 'This Week';
  
  String userName = 'Loading...';
  String userInitials = 'YN';
  String? profilePictureUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _gameService.dispose();
    super.dispose();
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
          final username = data?['username'] as String?;
          final fullName = data?['name'] as String?;
          final profilePic = data?['profilePicture'] as String?;
          
          setState(() {
            // Use username if available, otherwise use full name
            userName = username ?? fullName ?? 'Your Name';
            userInitials = _getInitials(userName);
            profilePictureUrl = profilePic;
            isLoading = false;
          });
        } else {
          setState(() {
            userName = 'Your Name';
            userInitials = 'YN';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          userName = 'Your Name';
          userInitials = 'YN';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Your Name';
        userInitials = 'YN';
        isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'YN';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }

  // Top 3 users
  final List<Map<String, dynamic>> topThree = [
    {
      'rank': 2,
      'name': 'Juan Dela Cruz',
      'initials': 'JC',
      'karma': 423,
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'bgColor': Color(0xFF6B7280),
    },
    {
      'rank': 1,
      'name': 'Maria Santos',
      'initials': 'MS',
      'karma': 485,
      'badge': 'Campus Hero',
      'badgeIcon': Icons.military_tech,
      'bgColor': Color(0xFF1F2937),
    },
    {
      'rank': 3,
      'name': 'Anna Reyes',
      'initials': 'AR',
      'karma': 387,
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'bgColor': Color(0xFF9CA3AF),
    },
  ];

  // User's position
  final Map<String, dynamic> currentUser = {
    'name': 'Your Name',
    'rank': '#15',
    'karma': 125,
    'change': '+15',
    'changeLabel': 'karma this week',
    'initials': 'YN',
    'badge': 'Newcomer',
    'bgColor': Color(0xFF6B7280),
  };

  // Full rankings
  final List<Map<String, dynamic>> fullRankings = [
    {
      'rank': 1,
      'name': 'Maria Santos',
      'initials': 'MS',
      'department': 'Arts and Sciences',
      'badge': 'Campus Hero',
      'badgeIcon': Icons.military_tech,
      'badgeEmoji': '🏛️',
      'karma': 485,
      'karmaChange': '+76',
      'found': 15,
      'returned': 12,
      'bgColor': Color(0xFF1F2937),
    },
    {
      'rank': 2,
      'name': 'Juan Dela Cruz',
      'initials': 'JC',
      'department': 'Engineering and Technology',
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'badgeEmoji': '🔍',
      'karma': 423,
      'karmaChange': '+54',
      'found': 12,
      'returned': 10,
      'bgColor': Color(0xFF6B7280),
    },
    {
      'rank': 3,
      'name': 'Anna Reyes',
      'initials': 'AR',
      'department': 'Business and Management',
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'badgeEmoji': '🔍',
      'karma': 387,
      'karmaChange': '+43',
      'found': 11,
      'returned': 9,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 4,
      'name': 'Carlos Garcia',
      'initials': 'CG',
      'department': 'Education',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🙂',
      'karma': 312,
      'karmaChange': '+34',
      'found': 9,
      'returned': 8,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 5,
      'name': 'Lisa Chen',
      'initials': 'LC',
      'department': 'Arts and Sciences',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🔥',
      'karma': 298,
      'karmaChange': '+28',
      'found': 8,
      'returned': 7,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 6,
      'name': 'Miguel Torres',
      'initials': 'MT',
      'department': 'Agriculture and Forestry',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🌱',
      'karma': 267,
      'karmaChange': '+23',
      'found': 7,
      'returned': 6,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 7,
      'name': 'Sofia Valdez',
      'initials': 'SV',
      'department': 'Nursing and Health Sciences',
      'badge': 'Newcomer',
      'badgeIcon': Icons.star,
      'badgeEmoji': '⭐',
      'karma': 198,
      'karmaChange': '+19',
      'found': 6,
      'returned': 5,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 8,
      'name': 'David Kim',
      'initials': 'DK',
      'department': 'Engineering and Technology',
      'badge': 'Newcomer',
      'badgeIcon': Icons.star,
      'badgeEmoji': '⭐',
      'karma': 156,
      'karmaChange': '+12',
      'found': 5,
      'returned': 4,
      'bgColor': Color(0xFF9CA3AF),
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
              Icons.emoji_events,
              color: AppColors.lightText,
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
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Container(
              color: AppColors.darkSurface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          selectedCollege,
                          ['All Colleges', 'Engineering', 'Arts and Sciences', 'Business'],
                          (value) => setState(() => selectedCollege = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Period',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          selectedTimePeriod,
                          ['This Week', 'This Month', 'All Time'],
                          (value) => setState(() => selectedTimePeriod = value!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current User Position Card
            ListenableBuilder(
              listenable: _gameService,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: currentUser['bgColor'],
                            shape: BoxShape.circle,
                            image: profilePictureUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(profilePictureUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profilePictureUrl == null
                              ? Center(
                                  child: Text(
                                    userInitials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.lightText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lvl ${_gameService.currentLevel} • ${_gameService.karma} karma',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Points: ${_gameService.points}',
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Change indicator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                                Text(
                                  currentUser['change'],
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              currentUser['changeLabel'],
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Top 3 Podium
            _buildTopThreePodium(),

            const SizedBox(height: 24),

            // Full Rankings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: AppColors.lightText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Full Rankings',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Full Rankings List
            ...fullRankings.map((user) => _buildRankingCard(user)),

            const SizedBox(height: 16),

            // View Active Challenges Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ChallengesPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'View Active Challenges',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.lightTextSecondary),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.lightText,
          ),
          dropdownColor: AppColors.darkCard,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: AppColors.lightText)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTopThreePodium() {
    // Reorder to show 2nd, 1st, 3rd
    final orderedTop = [topThree[0], topThree[1], topThree[2]];
    final heights = [140.0, 160.0, 120.0]; // Heights for 2nd, 1st, 3rd
    final podiumColors = [
      AppColors.darkCard, // 2nd place
      AppColors.primary,   // 1st place - brand blue
      AppColors.darkCard,  // 3rd place
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final user = orderedTop[index];
          final height = heights[index];
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: user['bgColor'],
                      shape: BoxShape.circle,
                      border: user['rank'] == 1 ? Border.all(
                        color: AppColors.secondary,
                        width: 2,
                      ) : null,
                    ),
                    child: Center(
                      child: Text(
                        user['initials'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge icon
                  Icon(
                    user['badgeIcon'],
                    size: 18,
                    color: user['rank'] == 1 ? AppColors.secondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    user['name'].split(' ')[0],
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    user['name'].split(' ').length > 1 
                        ? user['name'].split(' ').sublist(1).join(' ')
                        : '',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Karma
                  Text(
                    '${user['karma']} karma',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Podium
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: podiumColors[index],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: user['rank'] == 1 ? AppColors.secondary : AppColors.darkBorder,
                        width: user['rank'] == 1 ? 2 : 1,
                      ),
                      boxShadow: user['rank'] == 1 ? [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Icon(
                        user['rank'] == 1 ? Icons.workspace_premium : Icons.emoji_events,
                        color: user['rank'] == 1 ? AppColors.secondary : AppColors.lightTextSecondary,
                        size: user['rank'] == 1 ? 40 : 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank
              SizedBox(
                width: 30,
                child: Text(
                  '#${user['rank']}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: user['bgColor'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user['initials'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['name'],
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['badgeEmoji'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['department'],
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['badge'],
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Karma
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user['karma']}',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                  ),
                  Text(
                    'karma',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: AppColors.secondary,
                        size: 12,
                      ),
                      Text(
                        user['karmaChange'],
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            children: [
              const SizedBox(width: 30), // Align with name
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${user['found']}',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightText,
                            ),
                          ),
                          Text(
                            'Found',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${user['returned']}',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightText,
                            ),
                          ),
                          Text(
                            'Returned',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
