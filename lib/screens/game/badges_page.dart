import 'package:flutter/material.dart';
import 'challenges_page.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Earned badges data
    final List<Map<String, dynamic>> earnedBadges = [
      {
        'name': 'First Finder',
        'description': 'Posted your first found item',
        'icon': Icons.bookmark,
        'color': Colors.white,
        'bgColor': Colors.white,
        'iconColor': Colors.black87,
        'earned': '1/10/2024',
      },
      {
        'name': 'Good',
        'description': 'Helped return 3 items',
        'icon': Icons.bookmark,
        'color': Color(0xFF4ECDC4),
        'bgColor': Color(0xFF4ECDC4),
        'iconColor': Colors.white,
        'earned': '1/14/2024',
      },
      {
        'name': 'Campus Hero',
        'description': 'Reached 100 karma points',
        'icon': Icons.bookmark,
        'color': Color(0xFF8B7FFF),
        'bgColor': Color(0xFFE5E1FF),
        'iconColor': Color(0xFF3B28CC),
        'earned': '1/15/2024',
      },
    ];

    // Available badges data
    final List<Map<String, dynamic>> availableBadges = [
      {
        'name': 'Streak Master',
        'description': 'Maintained a 7-day streak',
        'icon': Icons.bookmark,
        'color': Colors.grey[300],
        'bgColor': Colors.white,
        'iconColor': Colors.grey[400],
        'progress': 5,
        'total': 7,
      },
      {
        'name': 'Helpful Heart',
        'description': 'Return 10 items to owners',
        'icon': Icons.bookmark,
        'color': Colors.grey[300],
        'bgColor': Colors.white,
        'iconColor': Colors.grey[400],
        'progress': 6,
        'total': 10,
      },
      {
        'name': 'Campus Explore',
        'description': 'Find items in 5 different buildings',
        'icon': Icons.bookmark,
        'color': Colors.grey[300],
        'bgColor': Colors.white,
        'iconColor': Colors.grey[400],
        'progress': 3,
        'total': 5,
      },
    ];

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
              'Badges',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.lightText,
              ),
            ),
            Text(
              'Your achievements and progress',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightTextSecondary,
              ),
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
            // Earned Badges Section
            Row(
              children: [
                const Icon(
                  Icons.stars,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Earned Badges (${earnedBadges.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: earnedBadges.length,
              itemBuilder: (context, index) {
                return _buildEarnedBadgeCard(earnedBadges[index]);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Available Badges Section
            Row(
              children: [
                const Icon(
                  Icons.bookmark_border,
                  size: 20,
                  color: AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Available Badges (${availableBadges.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Available Badges Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: availableBadges.length,
              itemBuilder: (context, index) {
                return _buildAvailableBadgeCard(availableBadges[index]);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Keep Going Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Keep Going!',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete more challenges to unlock new badges and increase your karma.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
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
                      child: Text(
                        'View Challenges',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
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

  Widget _buildEarnedBadgeCard(Map<String, dynamic> badge) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              badge['icon'],
              color: AppColors.black,
              size: 35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'],
            textAlign: TextAlign.center,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.lightTextSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Earned\n${badge['earned']}',
            textAlign: TextAlign.center,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.secondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBadgeCard(Map<String, dynamic> badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              badge['icon'],
              color: AppColors.lightTextSecondary.withOpacity(0.5),
              size: 35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'],
            textAlign: TextAlign.center,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.lightTextSecondary.withOpacity(0.7),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${badge['progress']} / ${badge['total']}',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
