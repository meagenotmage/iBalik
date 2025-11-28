// services/game_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ibalik/services/activity_service.dart';
import 'package:flutter_ibalik/services/notification_service.dart';

class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  int _points = 0;
  int _karma = 0;
  int _currentXP = 0;
  int _maxXP = 100;
  int _currentLevel = 1;

  // Getters
  int get points => _points;
  int get karma => _karma;
  int get currentXP => _currentXP;
  int get maxXP => _maxXP;
  int get currentLevel => _currentLevel;

  String? get _userId => _auth.currentUser?.uid;

  GameService() {
    _initUserListener();
  }

  void _initUserListener() {
    _auth.authStateChanges().listen((user) {
      _userSubscription?.cancel();
      if (user != null) {
        _userSubscription = _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            _points = (data['points'] ?? 0).toInt();
            _karma = (data['karma'] ?? 0).toInt();
            _currentXP = (data['currentXP'] ?? 0).toInt();
            _maxXP = (data['maxXP'] ?? 100).toInt();
            _currentLevel = (data['level'] ?? 1).toInt();
            notifyListeners();
          } else {
            // Initialize user stats if document doesn't exist or fields are missing
            _initializeUserStats(user.uid);
          }
        });
      } else {
        _points = 0;
        _karma = 0;
        _currentXP = 0;
        _maxXP = 100;
        _currentLevel = 1;
        notifyListeners();
      }
    });
  }

  Future<void> _initializeUserStats(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'points': 0,
      'karma': 0,
      'currentXP': 0,
      'maxXP': 100,
      'level': 1,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // ============ REWARD METHODS ============

  /// Reward for posting an item: +5 Pts, +10 Karma
  Future<void> rewardItemPost(String itemName) async {
    await _addRewards(
      points: 5,
      karma: 10,
      xp: 5,
      action: 'Item Posted',
      description: 'Posted "$itemName"',
      activityType: ActivityType.itemPosted,
    );
  }

  /// Reward for dropping off at hub: +8 Pts, +6 Karma
  Future<void> rewardDropOffAtHub(String itemName) async {
    await _addRewards(
      points: 8,
      karma: 6,
      xp: 15,
      action: 'Hub Drop-off',
      description: 'Dropped off "$itemName" at hub',
      activityType: ActivityType.returnCompleted, // Or a more specific type if available
    );
  }

  /// Reward for successful hub handover: +15 Pts, +12 Karma
  Future<void> rewardHubHandoverSuccess(String itemName) async {
    await _addRewards(
      points: 15,
      karma: 12,
      xp: 30,
      action: 'Hub Handover Success',
      description: 'Successfully handed over "$itemName" at hub',
      activityType: ActivityType.returnCompleted,
    );
  }

  /// Reward for successful return (direct): +12 Pts, +15 Karma
  Future<void> rewardSuccessfulReturn(String itemName) async {
    await _addRewards(
      points: 12,
      karma: 15,
      xp: 25,
      action: 'Successful Return',
      description: 'Returned "$itemName" to owner',
      activityType: ActivityType.returnCompleted,
    );
  }

  /// Reward for verified claim fulfillment: +25 Pts, +20 Karma
  Future<void> rewardVerifiedClaimFulfillment(String itemName) async {
    await _addRewards(
      points: 25,
      karma: 20,
      xp: 50,
      action: 'Verified Claim Fulfillment',
      description: 'Fulfilled verified claim for "$itemName"',
      activityType: ActivityType.returnCompleted,
    );
  }

  /// Reward another user for verified claim fulfillment (e.g. when claimer confirms receipt)
  Future<void> rewardUserVerifiedClaimFulfillment(String userId, String itemName) async {
    await _addRewardsForUser(
      userId: userId,
      points: 20,
      karma: 15,
      xp: 50,
      action: 'Verified Claim Fulfillment',
      description: 'Fulfilled verified claim for "$itemName"',
      activityType: ActivityType.returnCompleted,
      sendNotification: false, // Let the caller handle specific notification
    );
  }

  // ============ CORE LOGIC ============

  Future<void> _addRewards({
    required int points,
    required int karma,
    required int xp,
    required String action,
    required String description,
    required ActivityType activityType,
  }) async {
    if (_userId == null) return;

    try {
      final userRef = _firestore.collection('users').doc(_userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) {
          throw Exception("User document does not exist!");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        int currentPoints = (data['points'] ?? 0).toInt();
        int currentKarma = (data['karma'] ?? 0).toInt();
        int currentXP = (data['currentXP'] ?? 0).toInt();
        int currentLevel = (data['level'] ?? 1).toInt();
        int maxXP = (data['maxXP'] ?? 100).toInt();

        // Update values
        int newPoints = currentPoints + points;
        int newKarma = currentKarma + karma;
        int newXP = currentXP + xp;
        
        // Check for level up
        bool leveledUp = false;
        int newLevel = currentLevel;
        int newMaxXP = maxXP;

        while (newXP >= newMaxXP) {
          leveledUp = true;
          newXP -= newMaxXP;
          newLevel++;
          newMaxXP = (newMaxXP * 1.2).round(); // Increase XP requirement by 20%
        }

        transaction.update(userRef, {
          'points': newPoints,
          'karma': newKarma,
          'currentXP': newXP,
          'level': newLevel,
          'maxXP': newMaxXP,
        });

        // Post-transaction actions (Notifications & Activity Logs)
        // We do this AFTER the transaction to ensure data consistency, 
        // but since we can't await inside transaction easily for external services,
        // we'll do it here. Ideally, use Cloud Functions for this.
        // For now, we'll just trigger them.
        
        // Note: In a real app, you might want to queue these or handle them outside the transaction block
        // to avoid slowing down the transaction.
      });

      // Log Activity
      await _activityService.recordActivity(
        type: activityType,
        title: action,
        description: description,
        pointsChange: points,
        karmaChange: karma,
      );

      // Send Notification for Reward
      // Only notify for significant rewards or level ups to avoid spam
      if (points >= 5 || karma >= 5) {
         await _notificationService.createNotification(
          type: NotificationType.pointsEarned,
          title: 'Rewards Earned!',
          message: 'You earned +$points Pts and +$karma Karma for $action.',
        );
      }

      // Check if level up happened (we need to re-calculate or check the updated state)
      // Since we can't easily get the "leveledUp" bool out of the transaction without a return value,
      // we can check the local state after the listener updates, OR just calculate it again here roughly.
      // A better way is to check if the new level > old level.
      // But since `_currentLevel` is updated via stream, it might have a slight delay.
      // Let's just calculate it based on the values we passed.
      
      // Actually, let's just fetch the latest doc to see if level changed, or trust the logic.
      // For simplicity, I'll just check if the *local* state updates to a higher level in the stream listener
      // and trigger a notification there? No, that might be too disconnected.
      
      // Let's just do a quick check:
      final updatedDoc = await userRef.get();
      final updatedLevel = (updatedDoc.data()?['level'] ?? 1).toInt();
      
      if (updatedLevel > _currentLevel) {
        await _notificationService.notifyLevelUp(
          newLevel: updatedLevel,
          levelTitle: _getLevelTitle(updatedLevel),
        );
        await _activityService.recordLevelUp(
          newLevel: updatedLevel,
          levelTitle: _getLevelTitle(updatedLevel),
        );
      }

    } catch (e) {
      print('Error adding rewards: $e');
    }
  }

  Future<void> _addRewardsForUser({
    required String userId,
    required int points,
    required int karma,
    required int xp,
    required String action,
    required String description,
    required ActivityType activityType,
    bool sendNotification = true,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) {
          // If user doc doesn't exist, we might want to create it or skip
          // For now, let's skip or create basic
          return; 
        }

        final data = snapshot.data() as Map<String, dynamic>;
        int currentPoints = (data['points'] ?? 0).toInt();
        int currentKarma = (data['karma'] ?? 0).toInt();
        int currentXP = (data['currentXP'] ?? 0).toInt();
        int currentLevel = (data['level'] ?? 1).toInt();
        int maxXP = (data['maxXP'] ?? 100).toInt();

        // Update values
        int newPoints = currentPoints + points;
        int newKarma = currentKarma + karma;
        int newXP = currentXP + xp;
        
        // Check for level up
        int newLevel = currentLevel;
        int newMaxXP = maxXP;

        while (newXP >= newMaxXP) {
          newXP -= newMaxXP;
          newLevel++;
          newMaxXP = (newMaxXP * 1.2).round();
        }

        transaction.update(userRef, {
          'points': newPoints,
          'karma': newKarma,
          'currentXP': newXP,
          'level': newLevel,
          'maxXP': newMaxXP,
        });
      });

      // Log Activity for that user
      await _activityService.recordActivityForUser(
        userId: userId,
        type: activityType,
        title: action,
        description: description,
        pointsChange: points,
        karmaChange: karma,
      );

      // Send Notification
      if (sendNotification) {
        await _notificationService.createNotificationForUser(
          userId: userId,
          type: NotificationType.pointsEarned,
          title: 'Rewards Earned!',
          message: 'You earned +$points Pts and +$karma Karma for $action.',
        );
      }

    } catch (e) {
      print('Error adding rewards for user $userId: $e');
    }
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Novice Finder';
    if (level < 10) return 'Scout';
    if (level < 20) return 'Ranger';
    if (level < 30) return 'Guardian';
    if (level < 50) return 'Hero';
    return 'Legend';
  }
}
