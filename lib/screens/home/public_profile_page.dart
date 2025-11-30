import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_widgets.dart';
import '../../models/game_models.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String? userName;

  const PublicProfilePage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Map<String, dynamic>? _userData;
  UserStats? _userStats;
  bool _isLoading = true;
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Load user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final data = userDoc.data()!;
      
      // Convert to UserStats for consistent data handling
      final userStats = UserStats.fromFirestore(userDoc);
      
      // Calculate user rank
      final karma = (data['karma'] as num?)?.toInt() ?? 0;
      final higherKarmaQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('karma', isGreaterThan: karma)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _userData = data;
          _userStats = userStats;
          _userRank = (higherKarmaQuery.count ?? 0) + 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName ?? 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Card
                        _buildProfileHeader(),
                        
                        // Stats Section
                        _buildStatsSection(),
                        
                        // Bio Section
                        if (_userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty)
                          _buildBioSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = _userData!['username'] ?? _userData!['name'] ?? 'Unknown User';
    final department = _userData!['department'] ?? '';
    final course = _userData!['course'] ?? '';
    final year = _userData!['year'] ?? '';
    final profileImageUrl = _userData!['profileImageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Picture
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.white,
                      width: 3,
                    ),
                    boxShadow: AppShadows.medium,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerWidgets.imagePlaceholder(
                              width: 64,
                              height: 64,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (department.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          year.isNotEmpty ? '$department • $year' : department,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (course.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          course,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Primary Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.star_rounded,
                    value: (_userStats?.karma ?? 0).toString(),
                    label: 'Karma',
                    subtitle: 'Community Score',
                    color: AppColors.secondary,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.bolt_rounded,
                    value: (_userStats?.points ?? 0).toString(),
                    label: 'Points',
                    subtitle: 'Exchange Points',
                    color: AppColors.primary,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Secondary Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.emoji_events_rounded,
                    value: _userRank > 0 ? '#$_userRank' : '---',
                    label: 'Rank',
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.autorenew_rounded,
                    value: (_userStats?.itemsReturned ?? 0).toString(),
                    label: 'Returned',
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: (_userStats?.currentStreak ?? 0).toString(),
                    label: 'Streak',
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatCard(
                    icon: Icons.star_border_rounded,
                    value: 'Lv ${_userStats?.level ?? 1}',
                    label: 'Level',
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.lightGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: AppIconSize.md,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Items Posted', (_userStats?.itemsPosted ?? 0).toString(), Icons.add_box_rounded),
          _buildStatRow('Items Returned', (_userStats?.itemsReturned ?? 0).toString(), Icons.autorenew_rounded),
          _buildStatRow('Current Streak', '${_userStats?.currentStreak ?? 0} days', Icons.local_fire_department_rounded),
          _buildStatRow('Longest Streak', '${_userStats?.longestStreak ?? 0} days', Icons.workspace_premium_rounded),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    final bio = _userData!['bio'] as String;
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.lightGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: AppIconSize.md,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String value,
    required String label,
    String? subtitle,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isPrimary ? AppSpacing.md : AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppShadows.standard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isPrimary ? AppIconSize.lg : AppIconSize.md,
          ),
          SizedBox(height: isPrimary ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isPrimary ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isPrimary ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isPrimary && subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This user profile could not be loaded',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
