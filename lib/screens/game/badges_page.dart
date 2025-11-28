import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_service.dart';
import '../../services/game_data_service.dart';
import '../../utils/app_theme.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GameService _gameService = GameService();
  late GameDataService _gameDataService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _gameDataService = _gameService.gameData;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    // Badge definitions are loaded during GameDataService initialization
    await Future.delayed(const Duration(milliseconds: 300));
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
              Icons.military_tech,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Badges',
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
          final earnedBadges = _gameDataService.earnedBadges;
          final availableBadges = _gameDataService.getAvailableBadgesWithProgress();

          return Column(
            children: [
              // Badge Stats Header
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.darkSurface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Earned',
                      earnedBadges.length.toString(),
                      Icons.emoji_events,
                      AppColors.secondary,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.darkBorder,
                    ),
                    _buildStatItem(
                      'Available',
                      availableBadges.length.toString(),
                      Icons.lock_outline,
                      AppColors.lightTextSecondary,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.darkBorder,
                    ),
                    _buildStatItem(
                      'Total',
                      (earnedBadges.length + availableBadges.length).toString(),
                      Icons.stars,
                      AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              // Pill Tab Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.darkSurface,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPillTab('Earned', 0, earnedBadges.length),
                      ),
                      Expanded(
                        child: _buildPillTab('Available', 1, availableBadges.length),
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
                    _buildEarnedTab(earnedBadges),
                    _buildAvailableTab(availableBadges),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPillTab(String text, int index, int count) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.white.withOpacity(0.2) 
                    : AppColors.darkBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.white : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnedTab(List<UserBadge> badges) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (badges.isEmpty) {
      return _buildEmptyState(
        'No Badges Yet',
        'Complete challenges and reach milestones to earn badges!',
        Icons.emoji_events_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _initData,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) => _buildEarnedBadgeCard(badges[index]),
      ),
    );
  }

  Widget _buildEarnedBadgeCard(UserBadge badge) {
    final rarityColor = _getRarityColor(badge.rarity);
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge: badge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: rarityColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon with Glow
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Badge Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.lightText,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Rarity Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRarityLabel(badge.rarity),
                style: TextStyle(
                  fontSize: 10,
                  color: rarityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Earned Date
            Text(
              _formatEarnedDate(badge.earnedAt),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab(List<Map<String, dynamic>> badges) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (badges.isEmpty) {
      return _buildEmptyState(
        'All Badges Earned!',
        'Congratulations! You\'ve collected all available badges.',
        Icons.celebration,
      );
    }

    return RefreshIndicator(
      onRefresh: _initData,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) => _buildAvailableBadgeCard(badges[index]),
      ),
    );
  }

  Widget _buildAvailableBadgeCard(Map<String, dynamic> data) {
    final badge = data['definition'] as BadgeDefinition;
    final progress = (data['progress'] as double?) ?? 0.0;
    final current = data['current'] as int?;
    final required = data['required'] as int?;
    final rarityColor = _getRarityColor(badge.rarity);
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(definition: badge, progress: progress),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon (Locked style)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Opacity(
                        opacity: 0.5,
                        child: Text(
                          badge.icon,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                if (progress < 1.0)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.darkBorder,
                        width: 3,
                      ),
                    ),
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Badge Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Rarity Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRarityLabel(badge.rarity),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Progress
            if (current != null && required != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      '$current / $required',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: rarityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                badge.unlockCondition,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails({
    UserBadge? badge,
    BadgeDefinition? definition,
    double? progress,
  }) {
    final name = badge?.name ?? definition?.name ?? '';
    final icon = badge?.icon ?? definition?.icon ?? '';
    final desc = badge?.description ?? definition?.description ?? '';
    final rarity = badge?.rarity ?? definition?.rarity ?? BadgeRarity.common;
    final isEarned = badge != null;
    final rarityColor = _getRarityColor(rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Badge Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isEarned 
                    ? rarityColor.withOpacity(0.2) 
                    : AppColors.darkSurface,
                shape: BoxShape.circle,
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: rarityColor.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isEarned
                    ? Text(icon, style: const TextStyle(fontSize: 50))
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Opacity(
                          opacity: 0.5,
                          child: Text(icon, style: const TextStyle(fontSize: 50)),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Badge Name
            Text(
              name,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(isEarned ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: rarityColor.withOpacity(isEarned ? 0.5 : 0.3),
                ),
              ),
              child: Text(
                _getRarityLabel(rarity),
                style: TextStyle(
                  color: isEarned ? rarityColor : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              desc,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Status
            if (isEarned)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Earned ${_formatEarnedDate(badge!.earnedAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else if (definition != null)
              Column(
                children: [
                  Text(
                    'Requirement:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    definition.unlockCondition,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightText,
                    ),
                  ),
                  if (progress != null && progress > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% complete',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: rarityColor,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF10B981); // Green
      case BadgeRarity.rare:
        return const Color(0xFF3B82F6); // Blue
      case BadgeRarity.epic:
        return const Color(0xFF8B5CF6); // Purple
      case BadgeRarity.legendary:
        return const Color(0xFFF59E0B); // Gold
    }
  }

  String _getRarityLabel(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'COMMON';
      case BadgeRarity.rare:
        return 'RARE';
      case BadgeRarity.epic:
        return 'EPIC';
      case BadgeRarity.legendary:
        return 'LEGENDARY';
    }
  }

  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.lightTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
