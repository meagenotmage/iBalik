// services/game_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ibalik/models/game_models.dart';
import 'package:flutter_ibalik/services/activity_service.dart';
import 'package:flutter_ibalik/services/notification_service.dart';
import 'package:flutter_ibalik/services/game_data_service.dart';

class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();
  final GameDataService _gameDataService = GameDataService();

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  int _points = 0;
  int _karma = 0;
  int _currentXP = 0;
  int _maxXP = 100;
  int _currentLevel = 1;
  int _itemsPosted = 0;
  int _itemsReturned = 0;
  int _currentStreak = 0;

  // Getters
  int get points => _points;
  int get karma => _karma;
  int get currentXP => _currentXP;
  int get maxXP => _maxXP;
  int get currentLevel => _currentLevel;
  int get itemsPosted => _itemsPosted;
  int get itemsReturned => _itemsReturned;
  int get currentStreak => _currentStreak;
  
  // Game Data Service getters (for challenges, badges, leaderboards)
  GameDataService get gameData => _gameDataService;

  String? get _userId => _auth.currentUser?.uid;

  GameService() {
    _initUserListener();
    _initGameDataService();
  }
  
  Future<void> _initGameDataService() async {
    // Initialize game data service (challenges, badges, leaderboards)
    await _gameDataService.initializeDefaultData();
    await _gameDataService.initialize();
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
            _itemsPosted = (data['itemsPosted'] ?? 0).toInt();
            _itemsReturned = (data['itemsReturned'] ?? data['returned'] ?? 0).toInt();
            _currentStreak = (data['currentStreak'] ?? data['streak'] ?? 0).toInt();
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
        _itemsPosted = 0;
        _itemsReturned = 0;
        _currentStreak = 0;
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
      'itemsPosted': 0,
      'itemsReturned': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'badgesEarned': 0,
      'challengesCompleted': 0,
      'claimsMade': 0,
      'claimsApproved': 0,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // ============ REWARD METHODS ============

  /// Reward for posting an item: +5 Pts, +10 Karma
  Future<void> rewardItemPost(String itemName, {String? category}) async {
    await _addRewards(
      points: 5,
      karma: 10,
      xp: 5,
      action: 'Item Posted',
      description: 'Posted "$itemName"',
      activityType: ActivityType.itemPosted,
      gameAction: GameAction.itemPosted,
      category: category,
      incrementField: 'itemsPosted',
    );
  }

  /// Reward for dropping off at hub: +8 Pts, +6 Karma
  Future<void> rewardDropOffAtHub(String itemName, {String? category}) async {
    await _addRewards(
      points: 8,
      karma: 6,
      xp: 15,
      action: 'Hub Drop-off',
      description: 'Dropped off "$itemName" at hub',
      activityType: ActivityType.returnCompleted, // Or a more specific type if available
      gameAction: GameAction.hubDropOff,
      category: category,
    );
  }

  /// Reward for successful hub handover: +15 Pts, +12 Karma
  Future<void> rewardHubHandoverSuccess(String itemName, {String? category}) async {
    await _addRewards(
      points: 15,
      karma: 12,
      xp: 30,
      action: 'Hub Handover Success',
      description: 'Successfully handed over "$itemName" at hub',
      activityType: ActivityType.returnCompleted,
      gameAction: GameAction.itemReturned,
      category: category,
      incrementField: 'itemsReturned',
    );
  }

  /// Reward for successful return (direct): +12 Pts, +15 Karma
  Future<void> rewardSuccessfulReturn(String itemName, {String? category}) async {
    await _addRewards(
      points: 12,
      karma: 15,
      xp: 25,
      action: 'Successful Return',
      description: 'Returned "$itemName" to owner',
      activityType: ActivityType.returnCompleted,
      gameAction: GameAction.itemReturned,
      category: category,
      incrementField: 'itemsReturned',
    );
  }

  /// Reward for verified claim fulfillment: +25 Pts, +20 Karma
  Future<void> rewardVerifiedClaimFulfillment(String itemName, {String? category}) async {
    await _addRewards(
      points: 25,
      karma: 20,
      xp: 50,
      action: 'Verified Claim Fulfillment',
      description: 'Fulfilled verified claim for "$itemName"',
      activityType: ActivityType.returnCompleted,
      gameAction: GameAction.claimApproved,
      category: category,
      incrementField: 'claimsApproved',
    );
  }
  
  /// Reward for submitting a claim
  Future<void> rewardClaimSubmitted(String itemName, {String? category}) async {
    await _addRewards(
      points: 2,
      karma: 3,
      xp: 5,
      action: 'Claim Submitted',
      description: 'Submitted claim for "$itemName"',
      activityType: ActivityType.claimSubmitted,
      gameAction: GameAction.claimSubmitted,
      category: category,
      incrementField: 'claimsMade',
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
    GameAction? gameAction,
    String? category,
    String? incrementField,
  }) async {
    if (_userId == null) return;

    try {
      final userRef = _firestore.collection('users').doc(_userId);
      int previousLevel = _currentLevel;

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
        int newLevel = currentLevel;
        int newMaxXP = maxXP;

        while (newXP >= newMaxXP) {
          newXP -= newMaxXP;
          newLevel++;
          newMaxXP = (newMaxXP * 1.2).round(); // Increase XP requirement by 20%
        }

        final updates = <String, dynamic>{
          'points': newPoints,
          'karma': newKarma,
          'currentXP': newXP,
          'level': newLevel,
          'maxXP': newMaxXP,
          'lastActiveAt': FieldValue.serverTimestamp(),
        };
        
        // Increment specific stat field if provided
        if (incrementField != null) {
          updates[incrementField] = FieldValue.increment(1);
        }

        transaction.update(userRef, updates);
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
      if (points >= 5 || karma >= 5) {
         await _notificationService.createNotification(
          type: NotificationType.pointsEarned,
          title: 'Rewards Earned!',
          message: 'You earned +$points Pts and +$karma Karma for $action.',
        );
      }

      // Track action for challenges and badges
      if (gameAction != null) {
        await _gameDataService.trackAction(ActionMetadata(
          action: gameAction,
          category: category,
        ));
      }

      // Check for level up
      final updatedDoc = await userRef.get();
      final updatedLevel = (updatedDoc.data()?['level'] ?? 1).toInt();
      
      if (updatedLevel > previousLevel) {
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
      debugPrint('Error adding rewards: $e');
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
    String? incrementField,
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

        final updates = <String, dynamic>{
          'points': newPoints,
          'karma': newKarma,
          'currentXP': newXP,
          'level': newLevel,
          'maxXP': newMaxXP,
          'lastActiveAt': FieldValue.serverTimestamp(),
        };
        
        if (incrementField != null) {
          updates[incrementField] = FieldValue.increment(1);
        }

        transaction.update(userRef, updates);
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
      debugPrint('Error adding rewards for user $userId: $e');
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
  
  /// Get level title for display
  String getLevelTitle() => _getLevelTitle(_currentLevel);
  
  /// Update streak on daily login
  Future<void> updateDailyStreak() async {
    if (_userId == null) return;
    
    try {
      final userRef = _firestore.collection('users').doc(_userId);
      final doc = await userRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final lastActive = (data['lastActiveAt'] as Timestamp?)?.toDate();
      final currentStreak = (data['currentStreak'] ?? data['streak'] ?? 0).toInt();
      final longestStreak = (data['longestStreak'] ?? 0).toInt();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int newStreak = currentStreak;
      
      if (lastActive != null) {
        final lastActiveDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
        final daysDiff = today.difference(lastActiveDate).inDays;
        
        if (daysDiff == 0) {
          // Already logged in today, don't update streak
          return;
        } else if (daysDiff == 1) {
          // Consecutive day - increment streak
          newStreak = currentStreak + 1;
        } else {
          // Streak broken - reset to 1
          newStreak = 1;
        }
      } else {
        // First login
        newStreak = 1;
      }
      
      // Update streak and longest streak
      await userRef.update({
        'currentStreak': newStreak,
        'streak': newStreak, // For backward compatibility
        'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      
      // Track daily login for challenges
      await _gameDataService.trackAction(ActionMetadata(
        action: GameAction.dailyLogin,
      ));
      
    } catch (e) {
      debugPrint('Error updating daily streak: $e');
    }
  }
}
