import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

/// Notifications page displaying user notifications with gamified styling
/// - Limited to 20 notifications or past 3 months
/// - Real-time updates from Firestore
/// - Swipe to delete, tap to mark as read
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Log auth state for debugging
    _checkAuthState();
  }

  void _checkAuthState() {
    print('NotificationsPage initialized');
    final user = FirebaseAuth.instance.currentUser;
    print('Current user ID: ${user?.uid}');
    print('Current user email: ${user?.email}');
    print('Email verified: ${user?.emailVerified}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            StreamBuilder<int>(
              stream: _notificationService.getUnreadCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Text(
                  unreadCount > 0 ? '$unreadCount unread' : 'All caught up!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs & Mark All Read
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                StreamBuilder<int>(
                  stream: _notificationService.getUnreadCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildFilterChip('Unread ($count)');
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _notificationService.markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notifications List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationService.getNotificationsStream(),
              builder: (context, snapshot) {
                // Show loading only on initial load
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Detailed error logging
                  print('Notification stream error: ${snapshot.error}');
                  print('Error stack trace: ${snapshot.stackTrace}');
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Get docs and sort by createdAt descending (client-side)
                var notifications = snapshot.data?.docs ?? [];
                notifications = List.from(notifications);
                notifications.sort((a, b) {
                  final aTime = a.data()['createdAt'] as Timestamp?;
                  final bTime = b.data()['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // descending
                });

                // Apply filter
                final filteredNotifications = _selectedFilter == 'All'
                    ? notifications
                    : notifications.where((doc) => doc.data()['isRead'] == false).toList();

                if (filteredNotifications.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: _selectedFilter == 'All' 
                        ? 'No notifications yet' 
                        : 'No unread notifications',
                    subtitle: 'Your notifications will appear here',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final doc = filteredNotifications[index];
                    final notification = doc.data();
                    return _buildNotificationCard(
                      id: doc.id,
                      notification: notification,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = label.startsWith(_selectedFilter);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label.split(' ')[0];
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGray : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required Map<String, dynamic> notification,
  }) {
    final type = notification['type'] as String? ?? 'general';
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? true;
    final timestamp = notification['createdAt'] as Timestamp?;
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : '';

    // Get styling based on notification type
    final style = NotificationService.getNotificationStyle(type);
    final iconColor = Color(style['iconColor'] as int);
    final bgColor = Color(style['bgColor'] as int);
    final iconData = _getIconData(style['icon'] as String);

    // If read and in "All" filter, make it collapsible
    final shouldBeCollapsible = isRead && _selectedFilter == 'All';

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => _notificationService.deleteNotification(id),
      child: shouldBeCollapsible
          ? ExpansionTile(
              key: Key('expansion_$id'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.lightGray, width: 1),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.lightGray, width: 1),
              ),
              title: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Title and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: () {
                if (!isRead) {
                  _notificationService.markAsRead(id);
                }
                // Handle navigation based on actionRoute if needed
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.white : bgColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead ? AppColors.lightGray : bgColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'notifications': Icons.notifications,
      'check_circle': Icons.check_circle,
      'cancel': Icons.cancel,
      'celebration': Icons.celebration,
      'emoji_events': Icons.emoji_events,
      'flag': Icons.flag,
      'trending_up': Icons.trending_up,
      'arrow_upward': Icons.arrow_upward,
      'leaderboard': Icons.leaderboard,
      'local_fire_department': Icons.local_fire_department,
      'waving_hand': Icons.waving_hand,
    };
    return iconMap[iconName] ?? Icons.notifications;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
