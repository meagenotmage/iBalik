import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Activity types for tracking user actions in iBalik
enum ActivityType {
  // Item actions
  itemPosted,           // User posted a found item
  itemEdited,           // User edited their posted item
  itemDeleted,          // User deleted their posted item
  
  // Claim actions
  claimSubmitted,       // User submitted a claim request
  claimApproved,        // User's claim was approved
  claimDenied,          // User's claim was denied
  claimReviewed,        // User reviewed someone's claim
  
  // Return actions
  returnCompleted,      // Item successfully returned
  itemReceived,         // User received their claimed item
  
  // Gamification
  badgeEarned,          // Badge unlocked
  challengeCompleted,   // Challenge finished
  challengeStarted,     // Started a new challenge
  levelUp,              // Level increased
  karmaEarned,          // Karma points gained
  pointsEarned,         // Points gained
  pointsExchanged,      // Points exchanged for reward
  streakAchieved,       // Streak milestone
  
  // Profile
  profileUpdated,       // Profile info updated
  settingsChanged,      // Settings modified
  
  // Account
  accountCreated,       // New account registered
  login,                // User logged in
}

/// Service for managing user activity history
class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get activities collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _activitiesRef {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('activities');
  }

  /// Record a new activity
  Future<void> recordActivity({
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
    int? karmaChange,
    int? pointsChange,
  }) async {
    if (_activitiesRef == null) return;

    try {
      await _activitiesRef!.add({
        'type': type.name,
        'title': title,
        'description': description,
        'metadata': metadata ?? {},
        'karmaChange': karmaChange,
        'pointsChange': pointsChange,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Cleanup old activities (keep max 50 or 3 months)
      await _cleanupOldActivities();
    } catch (e) {
      print('Error recording activity: $e');
    }
  }

  /// Record activity for a specific user (e.g., when their claim is approved/denied)
  Future<void> recordActivityForUser({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
    int? karmaChange,
    int? pointsChange,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
        'type': type.name,
        'title': title,
        'description': description,
        'metadata': metadata ?? {},
        'karmaChange': karmaChange,
        'pointsChange': pointsChange,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Cleanup old activities for that user
      await _cleanupOldActivitiesForUser(userId);
    } catch (e) {
      print('Error recording activity for user $userId: $e');
    }
  }

  /// Cleanup old activities for a specific user
  Future<void> _cleanupOldActivitiesForUser(String userId) async {
    try {
      final userActivitiesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities');

      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

      // Delete activities older than 3 months
      final oldActivities = await userActivitiesRef
          .where('timestamp', isLessThan: Timestamp.fromDate(threeMonthsAgo))
          .get();

      if (oldActivities.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldActivities.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Keep only last 50 activities
      final allActivities = await userActivitiesRef
          .orderBy('timestamp', descending: true)
          .get();

      if (allActivities.docs.length > 50) {
        final toDelete = allActivities.docs.sublist(50);
        final batch = _firestore.batch();
        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up activities for user $userId: $e');
    }
  }

  /// Get activities stream (limited to 50, most recent first)
  /// Note: 3-month cleanup happens on write, so we just get latest 50
  Stream<QuerySnapshot<Map<String, dynamic>>> getActivitiesStream() {
    if (_userId == null) {
      return const Stream.empty();
    }

    // Query without orderBy to avoid index requirements
    // Sorting will be handled client-side
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('activities')
        .limit(50)
        .snapshots();
  }

  /// Get activities as future (for one-time fetch)
  Future<List<Map<String, dynamic>>> getActivities() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .limit(50)
          .get();

      // Sort client-side by timestamp descending
      final activities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return activities;
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  /// Cleanup old activities (keep max 50 or 3 months)
  Future<void> _cleanupOldActivities() async {
    if (_activitiesRef == null) return;

    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

      // Delete activities older than 3 months
      final oldActivities = await _activitiesRef!
          .where('timestamp', isLessThan: Timestamp.fromDate(threeMonthsAgo))
          .get();

      if (oldActivities.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldActivities.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Keep only last 50 activities
      final allActivities = await _activitiesRef!
          .orderBy('timestamp', descending: true)
          .get();

      if (allActivities.docs.length > 50) {
        final toDelete = allActivities.docs.sublist(50);
        final batch = _firestore.batch();
        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up activities: $e');
    }
  }

  // ============ ACTIVITY RECORDING HELPERS ============

  /// Record item posted
  Future<void> recordItemPosted({
    required String itemName,
    required String category,
    String? itemId,
  }) async {
    await recordActivity(
      type: ActivityType.itemPosted,
      title: 'Found Item Posted',
      description: 'Posted "$itemName" in $category',
      metadata: {'itemName': itemName, 'category': category, 'itemId': itemId},
    );
  }

  /// Record claim submitted
  Future<void> recordClaimSubmitted({
    required String itemName,
    String? claimId,
  }) async {
    await recordActivity(
      type: ActivityType.claimSubmitted,
      title: 'Claim Submitted',
      description: 'Submitted claim for "$itemName"',
      metadata: {'itemName': itemName, 'claimId': claimId},
    );
  }

  /// Record claim approved (for claimer)
  Future<void> recordClaimApproved({
    required String itemName,
    String? claimId,
  }) async {
    await recordActivity(
      type: ActivityType.claimApproved,
      title: 'Claim Approved',
      description: 'Your claim for "$itemName" was approved',
      metadata: {'itemName': itemName, 'claimId': claimId},
    );
  }

  /// Record claim denied (for claimer)
  Future<void> recordClaimDenied({
    required String itemName,
    String? reason,
    String? claimId,
  }) async {
    await recordActivity(
      type: ActivityType.claimDenied,
      title: 'Claim Denied',
      description: 'Your claim for "$itemName" was not approved${reason != null ? ": $reason" : ""}',
      metadata: {'itemName': itemName, 'reason': reason, 'claimId': claimId},
    );
  }

  /// Record claim reviewed (for finder/poster)
  Future<void> recordClaimReviewed({
    required String itemName,
    required String decision,
    required String claimerName,
    String? claimId,
  }) async {
    await recordActivity(
      type: ActivityType.claimReviewed,
      title: 'Claim Reviewed',
      description: '$decision claim by $claimerName for "$itemName"',
      metadata: {
        'itemName': itemName,
        'decision': decision,
        'claimerName': claimerName,
        'claimId': claimId,
      },
    );
  }

  /// Record successful return
  Future<void> recordReturnCompleted({
    required String itemName,
    required int karmaEarned,
    required int pointsEarned,
  }) async {
    await recordActivity(
      type: ActivityType.returnCompleted,
      title: 'Item Returned',
      description: '"$itemName" successfully returned',
      karmaChange: karmaEarned,
      pointsChange: pointsEarned,
      metadata: {
        'itemName': itemName,
        'karmaEarned': karmaEarned,
        'pointsEarned': pointsEarned,
      },
    );
  }

  /// Record badge earned
  Future<void> recordBadgeEarned({
    required String badgeName,
    required String badgeDescription,
  }) async {
    await recordActivity(
      type: ActivityType.badgeEarned,
      title: 'Badge Earned',
      description: 'Unlocked "$badgeName" badge',
      metadata: {'badgeName': badgeName, 'description': badgeDescription},
    );
  }

  /// Record challenge completed
  Future<void> recordChallengeCompleted({
    required String challengeName,
    required int rewardKarma,
    required int rewardPoints,
  }) async {
    await recordActivity(
      type: ActivityType.challengeCompleted,
      title: 'Challenge Completed',
      description: 'Completed "$challengeName"',
      karmaChange: rewardKarma,
      pointsChange: rewardPoints,
      metadata: {
        'challengeName': challengeName,
        'rewardKarma': rewardKarma,
        'rewardPoints': rewardPoints,
      },
    );
  }

  /// Record level up
  Future<void> recordLevelUp({
    required int newLevel,
    required String levelTitle,
  }) async {
    await recordActivity(
      type: ActivityType.levelUp,
      title: 'Level Up!',
      description: 'Reached Level $newLevel: $levelTitle',
      metadata: {'newLevel': newLevel, 'levelTitle': levelTitle},
    );
  }

  /// Record points exchanged
  Future<void> recordPointsExchanged({
    required int pointsSpent,
    required String rewardName,
  }) async {
    await recordActivity(
      type: ActivityType.pointsExchanged,
      title: 'Points Exchanged',
      description: 'Exchanged $pointsSpent points for "$rewardName"',
      pointsChange: -pointsSpent,
      metadata: {'pointsSpent': pointsSpent, 'rewardName': rewardName},
    );
  }

  /// Record profile update
  Future<void> recordProfileUpdated() async {
    await recordActivity(
      type: ActivityType.profileUpdated,
      title: 'Profile Updated',
      description: 'Updated profile information',
    );
  }

  /// Record account creation
  Future<void> recordAccountCreated({required String userName}) async {
    await recordActivity(
      type: ActivityType.accountCreated,
      title: 'Welcome to iBalik!',
      description: 'Account created for $userName',
      metadata: {'userName': userName},
    );
  }

  // ============ RECORD ACTIVITIES FOR OTHER USERS ============

  /// Record claim approved for a specific user (claimer)
  Future<void> recordUserClaimApproved({
    required String userId,
    required String itemName,
    String? claimId,
  }) async {
    await recordActivityForUser(
      userId: userId,
      type: ActivityType.claimApproved,
      title: 'Claim Approved',
      description: 'Your claim for "$itemName" was approved',
      metadata: {'itemName': itemName, 'claimId': claimId},
    );
  }

  /// Record claim denied for a specific user (claimer)
  Future<void> recordUserClaimDenied({
    required String userId,
    required String itemName,
    String? reason,
    String? claimId,
  }) async {
    await recordActivityForUser(
      userId: userId,
      type: ActivityType.claimDenied,
      title: 'Claim Denied',
      description: 'Your claim for "$itemName" was not approved${reason != null && reason.isNotEmpty ? ": $reason" : ""}',
      metadata: {'itemName': itemName, 'reason': reason, 'claimId': claimId},
    );
  }

  /// Record return completed for a specific user (finder)
  Future<void> recordUserReturnCompleted({
    required String userId,
    required String itemName,
    required int karmaEarned,
    required int pointsEarned,
  }) async {
    await recordActivityForUser(
      userId: userId,
      type: ActivityType.returnCompleted,
      title: 'Item Returned',
      description: '"$itemName" successfully returned',
      karmaChange: karmaEarned,
      pointsChange: pointsEarned,
      metadata: {
        'itemName': itemName,
        'karmaEarned': karmaEarned,
        'pointsEarned': pointsEarned,
      },
    );
  }

  /// Get icon and colors for activity type
  static Map<String, dynamic> getActivityStyle(String type) {
    switch (type) {
      case 'itemPosted':
        return {
          'icon': 'add_box',
          'iconColor': 0xFF6366F1,
          'bgColor': 0xFFE0E7FF,
        };
      case 'claimSubmitted':
        return {
          'icon': 'assignment',
          'iconColor': 0xFF3B82F6,
          'bgColor': 0xFFDBEAFE,
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
      case 'claimReviewed':
        return {
          'icon': 'rate_review',
          'iconColor': 0xFF8B5CF6,
          'bgColor': 0xFFF3E8FF,
        };
      case 'returnCompleted':
      case 'itemReceived':
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
      case 'levelUp':
        return {
          'icon': 'trending_up',
          'iconColor': 0xFF06B6D4,
          'bgColor': 0xFFCFFAFE,
        };
      case 'karmaEarned':
        return {
          'icon': 'star',
          'iconColor': 0xFFEC4899,
          'bgColor': 0xFFFCE7F3,
        };
      case 'pointsEarned':
        return {
          'icon': 'monetization_on',
          'iconColor': 0xFFF59E0B,
          'bgColor': 0xFFFEF3C7,
        };
      case 'pointsExchanged':
        return {
          'icon': 'redeem',
          'iconColor': 0xFF6366F1,
          'bgColor': 0xFFE0E7FF,
        };
      case 'profileUpdated':
        return {
          'icon': 'person',
          'iconColor': 0xFF6B7280,
          'bgColor': 0xFFF3F4F6,
        };
      case 'accountCreated':
        return {
          'icon': 'person_add',
          'iconColor': 0xFF3B82F6,
          'bgColor': 0xFFDBEAFE,
        };
      default:
        return {
          'icon': 'history',
          'iconColor': 0xFF6B7280,
          'bgColor': 0xFFF3F4F6,
        };
    }
  }

  /// Get icon data from string name
  static int getIconCodePoint(String iconName) {
    final iconMap = {
      'add_box': 0xe146,
      'assignment': 0xe85d,
      'check_circle': 0xe86c,
      'cancel': 0xe5c9,
      'rate_review': 0xe560,
      'celebration': 0xea65,
      'emoji_events': 0xea23,
      'flag': 0xe153,
      'trending_up': 0xe8e5,
      'star': 0xe838,
      'monetization_on': 0xe263,
      'redeem': 0xe8b1,
      'person': 0xe7fd,
      'person_add': 0xe7fe,
      'history': 0xe889,
    };
    return iconMap[iconName] ?? 0xe889; // default to history icon
  }
}
