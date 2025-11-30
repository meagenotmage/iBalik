import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notification types for the iBalik app
enum NotificationType {
  // Item-related
  itemPosted,           // Admin/central system posted an item
  itemMatched,          // Potential match found for user's lost item
  
  // Claim-related
  claimReceived,        // Someone claimed your posted item
  claimApproved,        // Your claim was approved
  claimDenied,          // Your claim was denied
  claimPending,         // Claim status update
  
  // Return-related
  returnCompleted,      // Item successfully returned
  pickupReminder,       // Reminder to pick up item
  
  // Gamification
  badgeEarned,          // New badge unlocked
  challengeCompleted,   // Challenge finished
  challengeProgress,    // Progress update on challenge
  levelUp,              // Level increased
  karmaEarned,          // Karma points earned
  pointsEarned,         // Points earned
  leaderboardUpdate,    // Rank changed on leaderboard
  streakMilestone,      // Streak achievement
  
  // System
  welcome,              // Welcome notification
  systemUpdate,         // App update or announcement
}

/// Service for managing user notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Create a new notification for current user
  Future<void> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
    String? actionRoute,
    String? actionId,
  }) async {
    if (_userId == null) return;

    try {
      // Use top-level notifications collection with userId field
      await _firestore.collection('notifications').add({
        'userId': _userId,
        'type': type.name,
        'title': title,
        'message': message,
        'metadata': metadata ?? {},
        'actionRoute': actionRoute,
        'actionId': actionId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cleanup old notifications (keep last 20 or 3 months)
      await _cleanupOldNotifications();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Create a notification for a specific user (e.g., when approving/denying claims)
  Future<void> createNotificationForUser({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
    String? actionRoute,
    String? actionId,
  }) async {
    try {
      // Use top-level notifications collection with userId field
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'metadata': metadata ?? {},
        'actionRoute': actionRoute,
        'actionId': actionId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cleanup old notifications for that user
      await _cleanupOldNotificationsForUser(userId);
    } catch (e) {
      print('Error creating notification for user $userId: $e');
    }
  }

  /// Cleanup old notifications for a specific user
  Future<void> _cleanupOldNotificationsForUser(String userId) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

      // Delete notifications older than 3 months for this user
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(threeMonthsAgo))
          .get();

      if (oldNotifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // TODO: Keep only last 20 notifications requires composite index
      // Create index at: https://console.firebase.google.com/
      // For now, commented out to avoid index errors
      /*
      final allNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (allNotifications.docs.length > 20) {
        // Sort by createdAt and delete oldest
        final sorted = allNotifications.docs;
        sorted.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        final toDelete = sorted.sublist(20);
        final batch = _firestore.batch();
        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      */
    } catch (e) {
      print('Error cleaning up notifications for user $userId: $e');
    }
  }

  /// Get notifications stream (limited to 20, most recent first)
  /// Note: 3-month cleanup happens on write, so we just get latest 20
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    print('Getting notification stream for user: $_userId');
    
    if (_userId == null) {
      print('User ID is null, returning empty stream');
      return const Stream.empty();
    }

    try {
      print('Creating Firestore query for notifications');
      // Query top-level collection filtered by userId
      final stream = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .limit(20)
          .snapshots();
      
      print('Notification stream created successfully');
      return stream;
    } catch (e) {
      print('Error creating notification stream: $e');
      rethrow;
    }
  }

  /// Get unread count
  Stream<int> getUnreadCountStream() {
    if (_userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      final unread = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Cleanup old notifications (keep max 20 or 3 months)
  Future<void> _cleanupOldNotifications() async {
    if (_userId == null) return;

    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

      // Delete notifications older than 3 months for this user
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(threeMonthsAgo))
          .get();

      if (oldNotifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Keep only last 20 notifications for this user
      final allNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .get();

      if (allNotifications.docs.length > 20) {
        // Sort by createdAt and delete oldest
        final sorted = allNotifications.docs;
        sorted.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        final toDelete = sorted.sublist(20);
        final batch = _firestore.batch();
        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }

  // ============ NOTIFICATION TRIGGER HELPERS ============

  /// Notify when a claim request is received on user's posted item
  Future<void> notifyClaimReceived({
    required String itemName,
    required String claimerName,
    String? claimId,
  }) async {
    await createNotification(
      type: NotificationType.claimReceived,
      title: '📬 New Claim Request',
      message: '$claimerName wants to claim your "$itemName"',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'claimerName': claimerName},
    );
  }

  /// Notify when user's claim is approved
  Future<void> notifyClaimApproved({
    required String itemName,
    String? pickupLocation,
    String? claimId,
  }) async {
    final locationInfo = pickupLocation != null ? ' Pick up at $pickupLocation.' : '';
    await createNotification(
      type: NotificationType.claimApproved,
      title: '✅ Claim Approved!',
      message: 'Your claim for "$itemName" was approved!$locationInfo',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'pickupLocation': pickupLocation},
    );
  }

  /// Notify when user's claim is denied
  Future<void> notifyClaimDenied({
    required String itemName,
    String? reason,
    String? claimId,
  }) async {
    final reasonInfo = reason != null ? ' Reason: $reason' : '';
    await createNotification(
      type: NotificationType.claimDenied,
      title: '❌ Claim Not Approved',
      message: 'Your claim for "$itemName" was not approved.$reasonInfo',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'reason': reason},
    );
  }

  /// Notify when item is successfully returned
  Future<void> notifyReturnCompleted({
    required String itemName,
    required int karmaEarned,
    required int pointsEarned,
  }) async {
    await createNotification(
      type: NotificationType.returnCompleted,
      title: '🎉 Return Successful!',
      message: '"$itemName" returned! You earned +$karmaEarned karma & +$pointsEarned points!',
      metadata: {
        'itemName': itemName,
        'karmaEarned': karmaEarned,
        'pointsEarned': pointsEarned,
      },
    );
  }

  /// Notify when a badge is earned
  Future<void> notifyBadgeEarned({
    required String badgeName,
    required String badgeDescription,
  }) async {
    await createNotification(
      type: NotificationType.badgeEarned,
      title: '🏆 Badge Unlocked!',
      message: 'You earned the "$badgeName" badge! $badgeDescription',
      actionRoute: '/badges',
      metadata: {'badgeName': badgeName, 'description': badgeDescription},
    );
  }

  /// Notify when a challenge is completed
  Future<void> notifyChallengeCompleted({
    required String challengeName,
    required int rewardKarma,
    required int rewardPoints,
  }) async {
    await createNotification(
      type: NotificationType.challengeCompleted,
      title: '🎯 Challenge Complete!',
      message: '"$challengeName" done! +$rewardKarma karma, +$rewardPoints points',
      actionRoute: '/challenges',
      metadata: {
        'challengeName': challengeName,
        'rewardKarma': rewardKarma,
        'rewardPoints': rewardPoints,
      },
    );
  }

  /// Notify challenge progress
  Future<void> notifyChallengeProgress({
    required String challengeName,
    required int current,
    required int total,
  }) async {
    await createNotification(
      type: NotificationType.challengeProgress,
      title: '📈 Challenge Progress',
      message: '"$challengeName": $current/$total complete. Keep going!',
      actionRoute: '/challenges',
      metadata: {
        'challengeName': challengeName,
        'current': current,
        'total': total,
      },
    );
  }

  /// Notify when user levels up
  Future<void> notifyLevelUp({
    required int newLevel,
    required String levelTitle,
  }) async {
    await createNotification(
      type: NotificationType.levelUp,
      title: '⬆️ Level Up!',
      message: 'You reached Level $newLevel: $levelTitle! Keep up the great work!',
      actionRoute: '/game',
      metadata: {'newLevel': newLevel, 'levelTitle': levelTitle},
    );
  }

  /// Notify leaderboard rank change
  Future<void> notifyLeaderboardUpdate({
    required int newRank,
    required int previousRank,
  }) async {
    final direction = newRank < previousRank ? '📈' : '📉';
    final change = (previousRank - newRank).abs();
    final verb = newRank < previousRank ? 'climbed' : 'dropped';
    
    await createNotification(
      type: NotificationType.leaderboardUpdate,
      title: '$direction Leaderboard Update',
      message: 'You $verb $change ${change == 1 ? "spot" : "spots"}! Now ranked #$newRank',
      actionRoute: '/leaderboard',
      metadata: {'newRank': newRank, 'previousRank': previousRank},
    );
  }

  /// Notify streak milestone
  Future<void> notifyStreakMilestone({
    required int streakDays,
  }) async {
    await createNotification(
      type: NotificationType.streakMilestone,
      title: '🔥 Streak Milestone!',
      message: '$streakDays-day streak! You\'re on fire! Keep helping the community!',
      metadata: {'streakDays': streakDays},
    );
  }

  /// Welcome notification for new users
  Future<void> notifyWelcome({required String userName}) async {
    await createNotification(
      type: NotificationType.welcome,
      title: '👋 Welcome to iBalik!',
      message: 'Hey $userName! Ready to help reunite lost items with their owners?',
      actionRoute: '/home',
    );
  }

  // ============ NOTIFY OTHER USERS (for claim workflows) ============

  /// Notify a specific user when someone claims their item
  Future<void> notifyUserClaimReceived({
    required String userId,
    required String itemName,
    required String claimerName,
    String? claimId,
    String? itemId,
  }) async {
    await createNotificationForUser(
      userId: userId,
      type: NotificationType.claimReceived,
      title: '📬 New Claim Request',
      message: '$claimerName wants to claim your "$itemName"',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'claimerName': claimerName, 'itemId': itemId},
    );
  }

  /// Notify a specific user their claim was approved
  Future<void> notifyUserClaimApproved({
    required String userId,
    required String itemName,
    String? claimId,
    String? itemId,
  }) async {
    await createNotificationForUser(
      userId: userId,
      type: NotificationType.claimApproved,
      title: '✅ Claim Approved!',
      message: 'Your claim for "$itemName" was approved! Coordinate pickup with the finder.',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'itemId': itemId},
    );
  }

  /// Notify a specific user their claim was denied
  Future<void> notifyUserClaimDenied({
    required String userId,
    required String itemName,
    String? reason,
    String? claimId,
    String? itemId,
  }) async {
    final reasonInfo = reason != null && reason.isNotEmpty ? ' Reason: $reason' : '';
    await createNotificationForUser(
      userId: userId,
      type: NotificationType.claimDenied,
      title: '❌ Claim Not Approved',
      message: 'Your claim for "$itemName" was not approved.$reasonInfo',
      actionRoute: '/claims',
      actionId: claimId,
      metadata: {'itemName': itemName, 'reason': reason, 'itemId': itemId},
    );
  }

  /// Notify a specific user that item was successfully returned (for finder)
  Future<void> notifyUserReturnCompleted({
    required String userId,
    required String itemName,
    required int karmaEarned,
    required int pointsEarned,
  }) async {
    await createNotificationForUser(
      userId: userId,
      type: NotificationType.returnCompleted,
      title: '🎉 Return Successful!',
      message: '"$itemName" returned! You earned +$karmaEarned karma & +$pointsEarned points!',
      metadata: {
        'itemName': itemName,
        'karmaEarned': karmaEarned,
        'pointsEarned': pointsEarned,
      },
    );
  }

  /// Get icon and colors for notification type
  static Map<String, dynamic> getNotificationStyle(String type) {
    switch (type) {
      case 'claimReceived':
        return {
          'icon': 'notifications',
          'iconColor': 0xFF6366F1,
          'bgColor': 0xFFE0E7FF,
        };
      case 'claimApproved':
        return {
          'icon': 'check_circle',
          'iconColor': 0xFF10B981,
          'bgColor': 0xFFD1FAE5,
        };
      case 'claimDenied':
        return {
          'icon': 'cancel',
          'iconColor': 0xFFEF4444,
          'bgColor': 0xFFFEE2E2,
        };
      case 'returnCompleted':
        return {
          'icon': 'celebration',
          'iconColor': 0xFF10B981,
          'bgColor': 0xFFD1FAE5,
        };
      case 'badgeEarned':
        return {
          'icon': 'emoji_events',
          'iconColor': 0xFFF59E0B,
          'bgColor': 0xFFFEF3C7,
        };
      case 'challengeCompleted':
        return {
          'icon': 'flag',
          'iconColor': 0xFF8B5CF6,
          'bgColor': 0xFFF3E8FF,
        };
      case 'challengeProgress':
        return {
          'icon': 'trending_up',
          'iconColor': 0xFF6366F1,
          'bgColor': 0xFFE0E7FF,
        };
      case 'levelUp':
        return {
          'icon': 'arrow_upward',
          'iconColor': 0xFF06B6D4,
          'bgColor': 0xFFCFFAFE,
        };
      case 'leaderboardUpdate':
        return {
          'icon': 'leaderboard',
          'iconColor': 0xFFEC4899,
          'bgColor': 0xFFFCE7F3,
        };
      case 'streakMilestone':
        return {
          'icon': 'local_fire_department',
          'iconColor': 0xFFF97316,
          'bgColor': 0xFFFFEDD5,
        };
      case 'welcome':
        return {
          'icon': 'waving_hand',
          'iconColor': 0xFF3B82F6,
          'bgColor': 0xFFDBEAFE,
        };
      default:
        return {
          'icon': 'notifications',
          'iconColor': 0xFF6B7280,
          'bgColor': 0xFFF3F4F6,
        };
    }
  }
}
