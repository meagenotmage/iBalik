import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'All';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.User? _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _currentUser?.uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$unreadCount unread',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              // TODO: Navigate to notification settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('userId', isEqualTo: _currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Unread ($unreadCount)'),
                    const Spacer(),
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Color(0xFF4318FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Notifications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: _currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];
                final filteredNotifications = _selectedFilter == 'All'
                    ? notifications
                    : notifications.where((doc) => !(doc.data() as Map<String, dynamic>)['isRead']).toList();

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'All' ? 'No notifications yet' : 'No unread notifications',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'All' 
                              ? 'Your notifications will appear here'
                              : 'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationCard(notification);
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(QueryDocumentSnapshot notificationDoc) {
    final notification = notificationDoc.data() as Map<String, dynamic>;
    final notificationId = notificationDoc.id;
    
    // Determine icon and colors based on notification type
    final Map<String, dynamic> notificationStyle = _getNotificationStyle(notification['type']);
    final timeAgo = _getTimeAgo(notification['createdAt']?.toDate() ?? DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notificationStyle['bgColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification['isRead'] ? Colors.transparent : const Color(0xFF4318FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notificationStyle['iconColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificationStyle['icon'],
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (!notification['isRead'])
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4318FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (notification['hasAction'] == true) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleNotificationAction(notification, notificationId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: notificationStyle['actionColor'],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            notification['actionText'] ?? 'Take Action',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'claim_approved':
        return {
          'icon': Icons.check_circle,
          'iconColor': const Color(0xFF10B981),
          'bgColor': const Color(0xFFD1FAE5),
          'actionColor': const Color(0xFF10B981),
        };
      case 'new_claim':
        return {
          'icon': Icons.shopping_bag,
          'iconColor': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFDBEAFE),
          'actionColor': const Color(0xFF3B82F6),
        };
      case 'claim_rejected':
        return {
          'icon': Icons.cancel,
          'iconColor': const Color(0xFFEF4444),
          'bgColor': const Color(0xFFFEE2E2),
          'actionColor': const Color(0xFFEF4444),
        };
      case 'item_returned':
        return {
          'icon': Icons.verified,
          'iconColor': const Color(0xFF8B5CF6),
          'bgColor': const Color(0xFFEDE9FE),
          'actionColor': const Color(0xFF8B5CF6),
        };
      case 'challenge':
        return {
          'icon': Icons.emoji_events,
          'iconColor': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFEF3C7),
          'actionColor': const Color(0xFFF59E0B),
        };
      case 'karma_earned':
        return {
          'icon': Icons.star,
          'iconColor': const Color(0xFFEC4899),
          'bgColor': const Color(0xFFFCE7F3),
          'actionColor': const Color(0xFFEC4899),
        };
      default:
        return {
          'icon': Icons.notifications,
          'iconColor': const Color(0xFF6B7280),
          'bgColor': const Color(0xFFF3F4F6),
          'actionColor': const Color(0xFF6B7280),
        };
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _markAllAsRead() async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUser?.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void _handleNotificationAction(Map<String, dynamic> notification, String notificationId) async {
    // Mark as read when action is taken
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});

    final type = notification['type'];
    final metadata = notification['metadata'] ?? {};

    switch (type) {
      case 'claim_approved':
        // Navigate to pickup information or claims page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ClaimDetailsPage(claimId: metadata['claimId'])));
        break;
      case 'new_claim':
        // Navigate to review claim page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewClaimPage(claimId: metadata['claimId'])));
        break;
      case 'claim_rejected':
        // Navigate to claim details or post new item
        break;
      case 'item_returned':
        // Navigate to item details or success page
        break;
      case 'challenge':
        // Navigate to challenges page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ChallengesPage()));
        break;
      default:
        // Default action
        break;
    }
  }
}

// Utility function to create notifications from other parts of your app
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? actionText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'actionText': actionText,
        'hasAction': actionText != null,
        'metadata': metadata ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Example usage methods
  static Future<void> notifyClaimApproved({
    required String userId,
    required String claimId,
    required String itemName,
    required String pickupLocation,
  }) async {
    await createNotification(
      userId: userId,
      type: 'claim_approved',
      title: 'Claim Approved!',
      message: 'Your claim "$itemName" has been approved. You can pick it up from $pickupLocation.',
      actionText: 'View Pickup Info',
      metadata: {
        'claimId': claimId,
        'itemName': itemName,
        'pickupLocation': pickupLocation,
      },
    );
  }

  static Future<void> notifyNewClaim({
    required String userId,
    required String claimId,
    required String itemName,
    required String claimantName,
  }) async {
    await createNotification(
      userId: userId,
      type: 'new_claim',
      title: 'New Claim Received',
      message: '$claimantName wants to claim your posted item "$itemName"',
      actionText: 'Review Claim',
      metadata: {
        'claimId': claimId,
        'itemName': itemName,
        'claimantName': claimantName,
      },
    );
  }

  static Future<void> notifyChallengeProgress({
    required String userId,
    required String challengeName,
    required int progress,
    required int target,
  }) async {
    await createNotification(
      userId: userId,
      type: 'challenge',
      title: 'Challenge Progress',
      message: 'You\'re $progress/$target complete for "$challengeName"! Keep going!',
      actionText: 'View Challenges',
      metadata: {
        'challengeName': challengeName,
        'progress': progress,
        'target': target,
      },
    );
  }

  static Future<void> notifyKarmaEarned({
    required String userId,
    required int karmaPoints,
    required String reason,
  }) async {
    await createNotification(
      userId: userId,
      type: 'karma_earned',
      title: 'Karma Earned!',
      message: 'You earned $karmaPoints karma points for $reason',
      actionText: 'View Profile',
      metadata: {
        'karmaPoints': karmaPoints,
        'reason': reason,
      },
    );
  }
}