import 'package:flutter/material.dart';
import 'challenges_page.dart';
import '../../utils/page_transitions.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Your achievements and progress',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
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
                  color: Colors.black87,
                ),
                const SizedBox(width: 6),
                Text(
                  'Earned Badges (${earnedBadges.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                Icon(
                  Icons.bookmark_border,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Available Badges (${availableBadges.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5E1FF), Color(0xFFE5E1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B7FFF),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Keep Going!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete more challenges to unlock new badges and increase your karma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
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
                        backgroundColor: const Color(0xFF0000FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Challenges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
        color: badge['bgColor'],
        borderRadius: BorderRadius.circular(16),
        border: badge['bgColor'] == Colors.white 
            ? Border.all(color: Colors.grey[300]!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: badge['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              badge['icon'],
              color: badge['iconColor'],
              size: 35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Earned\n${badge['earned']}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
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
        color: badge['bgColor'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: badge['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              badge['icon'],
              color: badge['iconColor'],
              size: 35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${badge['progress']} / ${badge['total']}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
