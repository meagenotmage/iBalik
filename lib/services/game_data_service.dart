import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import 'activity_service.dart';

/// Service for managing challenges, badges, and leaderboards
/// All data is persisted in Firestore and synchronized in real-time
class GameDataService extends ChangeNotifier {
  static final GameDataService _instance = GameDataService._internal();
  factory GameDataService() => _instance;
  GameDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cached data
  List<UserChallenge> _activeChallenges = [];
  List<UserChallenge> _completedChallenges = [];
  List<UserBadge> _earnedBadges = [];
  List<BadgeDefinition> _allBadgeDefinitions = [];
  UserStats? _currentUserStats;

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _challengesSubscription;
  StreamSubscription<QuerySnapshot>? _badgesSubscription;
  StreamSubscription<QuerySnapshot>? _badgeDefsSubscription;
  StreamSubscription<DocumentSnapshot>? _userStatsSubscription;

  // Getters
  List<UserChallenge> get activeChallenges => _activeChallenges;
  List<UserChallenge> get completedChallenges => _completedChallenges;
  List<UserBadge> get earnedBadges => _earnedBadges;
  List<BadgeDefinition> get allBadgeDefinitions => _allBadgeDefinitions;
  UserStats? get currentUserStats => _currentUserStats;

  String? get _userId => _auth.currentUser?.uid;

  // ============ INITIALIZATION ============

  /// Initialize the service and start listening to user's game data
  Future<void> initialize() async {
    final userId = _userId;
    if (userId == null) return;

    // Load badge definitions first (shared across all users)
    await _loadBadgeDefinitions();

    // Start listening to user's challenges
    _listenToChallenges(userId);

    // Start listening to user's badges
    _listenToBadges(userId);

    // Start listening to user stats
    _listenToUserStats(userId);

    // Ensure user has active challenges (at least 3)
    await _ensureActiveChallenges(userId);
    
    // Check if user qualifies for any badges based on current stats
    await _checkBadgeUnlocks(userId, null);
  }

  /// Clean up subscriptions
  void dispose() {
    _challengesSubscription?.cancel();
    _badgesSubscription?.cancel();
    _badgeDefsSubscription?.cancel();
    _userStatsSubscription?.cancel();
    super.dispose();
  }

  // ============ CHALLENGE MANAGEMENT ============

  Future<void> _loadBadgeDefinitions() async {
    try {
      final snapshot = await _firestore
          .collection('badge_definitions')
          .where('isActive', isEqualTo: true)
          .get();

      _allBadgeDefinitions = snapshot.docs
          .map((doc) => BadgeDefinition.fromFirestore(doc))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading badge definitions: $e');
    }
  }

  void _listenToChallenges(String userId) {
    _challengesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .orderBy('startedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final allChallenges = snapshot.docs
          .map((doc) => UserChallenge.fromFirestore(doc))
          .toList();

      // Separate active and completed challenges
      final now = DateTime.now();
      _activeChallenges = allChallenges
          .where((c) => !c.isCompleted && (c.expiresAt == null || c.expiresAt!.isAfter(now)))
          .toList();
      _completedChallenges = allChallenges
          .where((c) => c.isCompleted)
          .toList();

      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to challenges: $e');
    });
  }

  void _listenToBadges(String userId) {
    _badgesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _earnedBadges = snapshot.docs
          .map((doc) => UserBadge.fromFirestore(doc))
          .toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to badges: $e');
    });
  }

  void _listenToUserStats(String userId) {
    _userStatsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _currentUserStats = UserStats.fromFirestore(snapshot);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to user stats: $e');
    });
  }

  /// Ensure user has active challenges (assign new ones if needed)
  Future<void> _ensureActiveChallenges(String userId) async {
    try {
      // Get user's current active challenges
      final activeSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: false)
          .get();

      final now = DateTime.now();
      final activeCount = activeSnapshot.docs
          .where((doc) {
            final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
            return expiresAt == null || expiresAt.isAfter(now);
          })
          .length;

      // If user has fewer than 3 active challenges, assign new ones
      if (activeCount < 3) {
        await _assignNewChallenges(userId, 3 - activeCount);
      }
    } catch (e) {
      debugPrint('Error ensuring active challenges: $e');
    }
  }

  /// Assign new challenges to user
  Future<void> _assignNewChallenges(String userId, int count) async {
    try {
      // Get available challenge definitions
      final defsSnapshot = await _firestore
          .collection('challenge_definitions')
          .where('isActive', isEqualTo: true)
          .get();

      if (defsSnapshot.docs.isEmpty) {
        // Seed default challenges if none exist
        await _seedDefaultChallenges();
        return _assignNewChallenges(userId, count);
      }

      // Get IDs of challenges user already has (active or completed recently)
      final existingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .get();

      final existingIds = existingSnapshot.docs
          .map((doc) => doc.data()['challengeId'] as String)
          .toSet();

      // Filter to challenges user doesn't have
      final availableDefs = defsSnapshot.docs
          .where((doc) => !existingIds.contains(doc.id))
          .toList();

      if (availableDefs.isEmpty) return;

      // Pick random challenges
      availableDefs.shuffle();
      final toAssign = availableDefs.take(count);

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in toAssign) {
        final def = ChallengeDefinition.fromFirestore(doc);
        final challengeRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('challenges')
            .doc();

        DateTime? expiresAt;
        if (def.duration != null) {
          expiresAt = now.add(def.duration!);
        } else if (def.type == ChallengeType.daily) {
          expiresAt = DateTime(now.year, now.month, now.day + 1);
        } else if (def.type == ChallengeType.weekly) {
          expiresAt = now.add(const Duration(days: 7));
        }

        batch.set(challengeRef, {
          'challengeId': def.id,
          'challengeName': def.name,
          'description': def.description,
          'icon': def.icon,
          'type': def.type.name,
          'difficulty': def.difficulty.name,
          'currentProgress': 0,
          'targetCount': def.targetCount,
          'rewardKarma': def.rewardKarma,
          'rewardPoints': def.rewardPoints,
          'rewardXP': def.rewardXP,
          'isCompleted': false,
          'startedAt': Timestamp.fromDate(now),
          'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error assigning new challenges: $e');
    }
  }

  /// Update challenge progress based on user action
  Future<void> trackAction(ActionMetadata action) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      // Get active challenges that match this action
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: false)
          .get();

      final now = DateTime.now();
      final batch = _firestore.batch();
      bool anyCompleted = false;

      for (final doc in snapshot.docs) {
        final challenge = UserChallenge.fromFirestore(doc);
        
        // Check if expired
        if (challenge.expiresAt != null && challenge.expiresAt!.isBefore(now)) {
          continue;
        }

        // Check if action matches challenge criteria
        if (_doesActionMatchChallenge(action, challenge)) {
          final newProgress = challenge.currentProgress + 1;
          final isNowComplete = newProgress >= challenge.targetCount;

          final updates = <String, dynamic>{
            'currentProgress': newProgress,
          };

          if (isNowComplete) {
            updates['isCompleted'] = true;
            updates['completedAt'] = Timestamp.fromDate(now);
            anyCompleted = true;
          }

          batch.update(doc.reference, updates);
        }
      }

      await batch.commit();

      // Award rewards for completed challenges
      if (anyCompleted) {
        await _processCompletedChallenges(userId);
      }

      // Check for badge unlocks
      await _checkBadgeUnlocks(userId, action);
    } catch (e) {
      debugPrint('Error tracking action: $e');
    }
  }

  bool _doesActionMatchChallenge(ActionMetadata action, UserChallenge challenge) {
    // Match based on challenge name/type
    // This is simplified - in production, you'd match against stored criteria
    final challengeName = challenge.challengeName.toLowerCase();

    switch (action.action) {
      case GameAction.itemPosted:
        return challengeName.contains('post') || 
               challengeName.contains('upload') ||
               challengeName.contains('report');
      case GameAction.itemReturned:
        return challengeName.contains('return') || 
               challengeName.contains('reunite');
      case GameAction.claimSubmitted:
        return challengeName.contains('claim');
      case GameAction.claimApproved:
        return challengeName.contains('claim') || 
               challengeName.contains('verify');
      case GameAction.hubDropOff:
        return challengeName.contains('hub') || 
               challengeName.contains('drop');
      case GameAction.dailyLogin:
        return challengeName.contains('login') || 
               challengeName.contains('active') ||
               challengeName.contains('streak');
      default:
        return false;
    }
  }

  Future<void> _processCompletedChallenges(String userId) async {
    try {
      // Get recently completed challenges that haven't been rewarded
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: true)
          .where('rewarded', isEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) return;

      int totalKarma = 0;
      int totalPoints = 0;
      int totalXP = 0;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final challenge = UserChallenge.fromFirestore(doc);
        totalKarma += challenge.rewardKarma;
        totalPoints += challenge.rewardPoints;
        totalXP += challenge.rewardXP;

        batch.update(doc.reference, {'rewarded': true});

        // Record activity
        ActivityService().recordChallengeCompleted(
          challengeName: challenge.challengeName,
          rewardKarma: challenge.rewardKarma,
          rewardPoints: challenge.rewardPoints,
        );
      }

      // Update user stats
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'karma': FieldValue.increment(totalKarma),
        'points': FieldValue.increment(totalPoints),
        'currentXP': FieldValue.increment(totalXP),
        'challengesCompleted': FieldValue.increment(snapshot.docs.length),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error processing completed challenges: $e');
    }
  }

  // ============ BADGE MANAGEMENT ============

  /// Check if user has unlocked any new badges
  Future<void> _checkBadgeUnlocks(String userId, ActionMetadata? action) async {
    try {
      // Get user's current stats
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final stats = UserStats.fromFirestore(userDoc);

      // Get user's existing badges
      final existingBadges = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      final existingBadgeIds = existingBadges.docs
          .map((doc) => doc.data()['badgeId'] as String)
          .toSet();

      // Check each badge definition
      final badgeDefs = await _firestore
          .collection('badge_definitions')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      final newBadges = <BadgeDefinition>[];

      for (final doc in badgeDefs.docs) {
        final def = BadgeDefinition.fromFirestore(doc);
        
        // Skip if user already has this badge
        if (existingBadgeIds.contains(def.id)) continue;

        // Check if user meets criteria
        if (_meetsBadgeCriteria(def, stats)) {
          newBadges.add(def);

          final badgeRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('badges')
              .doc();

          batch.set(badgeRef, {
            'badgeId': def.id,
            'name': def.name,
            'description': def.description,
            'icon': def.icon,
            'rarity': def.rarity.name,
            'earnedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      if (newBadges.isNotEmpty) {
        // Update badge count
        batch.update(
          _firestore.collection('users').doc(userId),
          {'badgesEarned': FieldValue.increment(newBadges.length)},
        );

        await batch.commit();

        // Record activity for each badge
        for (final badge in newBadges) {
          ActivityService().recordBadgeEarned(
            badgeName: badge.name,
            badgeDescription: badge.description,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking badge unlocks: $e');
    }
  }

  bool _meetsBadgeCriteria(BadgeDefinition badge, UserStats stats) {
    final criteria = badge.criteria;
    if (criteria.isEmpty) return false;

    // Check each criterion
    for (final entry in criteria.entries) {
      final key = entry.key;
      final required = (entry.value as num).toInt();

      int current;
      switch (key) {
        case 'itemsPosted':
          current = stats.itemsPosted;
          break;
        case 'itemsReturned':
          current = stats.itemsReturned;
          break;
        case 'karma':
          current = stats.karma;
          break;
        case 'points':
          current = stats.points;
          break;
        case 'level':
          current = stats.level;
          break;
        case 'streak':
          current = stats.currentStreak;
          break;
        case 'longestStreak':
          current = stats.longestStreak;
          break;
        case 'badgesEarned':
          current = stats.badgesEarned;
          break;
        case 'challengesCompleted':
          current = stats.challengesCompleted;
          break;
        case 'claimsApproved':
          current = stats.claimsApproved;
          break;
        default:
          return false;
      }

      if (current < required) return false;
    }

    return true;
  }

  /// Get badge progress for a specific badge definition
  Map<String, dynamic> getBadgeProgress(BadgeDefinition badge) {
    final stats = _currentUserStats;
    if (stats == null || badge.criteria.isEmpty) {
      return {'progress': 0.0, 'current': 0, 'required': 1};
    }

    int total = 0;
    int completed = 0;

    for (final entry in badge.criteria.entries) {
      final key = entry.key;
      final required = (entry.value as num).toInt();
      total++;

      int current = 0;
      switch (key) {
        case 'itemsPosted':
          current = stats.itemsPosted;
          break;
        case 'itemsReturned':
          current = stats.itemsReturned;
          break;
        case 'karma':
          current = stats.karma;
          break;
        case 'points':
          current = stats.points;
          break;
        case 'level':
          current = stats.level;
          break;
        case 'streak':
          current = stats.currentStreak;
          break;
        default:
          continue;
      }

      if (current >= required) {
        completed++;
      }

      // Return first incomplete criterion
      if (current < required) {
        return {
          'progress': current / required,
          'current': current,
          'required': required,
          'criterion': key,
        };
      }
    }

    return {'progress': total > 0 ? completed / total : 0.0};
  }

  /// Check if user has earned a specific badge
  bool hasBadge(String badgeId) {
    return _earnedBadges.any((b) => b.badgeId == badgeId);
  }

  // ============ LEADERBOARD QUERIES ============

  /// Get leaderboard ranked by specified criteria
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardCriteria criteria = LeaderboardCriteria.karma,
    String? department,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Filter by department if specified
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }

      // Order by criteria
      query = query.orderBy(criteria.firestoreField, descending: true);
      query = query.limit(limit);

      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];

      int rank = 1;
      for (final doc in snapshot.docs) {
        final stats = UserStats.fromFirestore(doc);
        entries.add(LeaderboardEntry(
          rank: rank++,
          user: stats,
        ));
      }

      return entries;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get current user's rank on leaderboard
  Future<int> getCurrentUserRank({
    LeaderboardCriteria criteria = LeaderboardCriteria.karma,
    String? department,
  }) async {
    final userId = _userId;
    if (userId == null) return -1;

    try {
      // Get current user's score
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return -1;

      final userStats = UserStats.fromFirestore(userDoc);
      int userScore;
      
      switch (criteria) {
        case LeaderboardCriteria.karma:
          userScore = userStats.karma;
          break;
        case LeaderboardCriteria.points:
          userScore = userStats.points;
          break;
        case LeaderboardCriteria.itemsReturned:
          userScore = userStats.itemsReturned;
          break;
        case LeaderboardCriteria.itemsPosted:
          userScore = userStats.itemsPosted;
          break;
        case LeaderboardCriteria.level:
          userScore = userStats.level;
          break;
        case LeaderboardCriteria.streak:
          userScore = userStats.currentStreak;
          break;
      }

      // Count users with higher score
      Query query = _firestore.collection('users');
      
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }

      query = query.where(criteria.firestoreField, isGreaterThan: userScore);
      
      final count = await query.count().get();
      return count.count! + 1;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return -1;
    }
  }

  /// Stream leaderboard entries (real-time updates)
  Stream<List<LeaderboardEntry>> streamLeaderboard({
    LeaderboardCriteria criteria = LeaderboardCriteria.karma,
    String? department,
    int limit = 20,
  }) {
    Query query = _firestore.collection('users');

    if (department != null && department.isNotEmpty) {
      query = query.where('department', isEqualTo: department);
    }

    query = query.orderBy(criteria.firestoreField, descending: true);
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final entries = <LeaderboardEntry>[];
      int rank = 1;
      
      for (final doc in snapshot.docs) {
        final stats = UserStats.fromFirestore(doc);
        entries.add(LeaderboardEntry(
          rank: rank++,
          user: stats,
        ));
      }
      
      return entries;
    });
  }

  // ============ DATA SEEDING ============

  /// Seed default challenge definitions (call once to initialize)
  Future<void> _seedDefaultChallenges() async {
    final defaults = [
      // Daily challenges
      ChallengeDefinition(
        id: 'daily_post_1',
        name: 'First Post Today',
        description: 'Post one found item today',
        icon: '📦',
        type: ChallengeType.daily,
        category: ChallengeCategory.posting,
        difficulty: ChallengeDifficulty.easy,
        targetCount: 1,
        rewardKarma: 10,
        rewardPoints: 5,
        rewardXP: 20,
        duration: const Duration(hours: 24),
      ),
      ChallengeDefinition(
        id: 'daily_return_1',
        name: 'Good Samaritan',
        description: 'Return one item to its owner',
        icon: '🤝',
        type: ChallengeType.daily,
        category: ChallengeCategory.returning,
        difficulty: ChallengeDifficulty.medium,
        targetCount: 1,
        rewardKarma: 25,
        rewardPoints: 15,
        rewardXP: 50,
        duration: const Duration(hours: 24),
      ),
      
      // Weekly challenges
      ChallengeDefinition(
        id: 'weekly_post_5',
        name: 'Active Finder',
        description: 'Post 5 found items this week',
        icon: '🔍',
        type: ChallengeType.weekly,
        category: ChallengeCategory.posting,
        difficulty: ChallengeDifficulty.medium,
        targetCount: 5,
        rewardKarma: 50,
        rewardPoints: 30,
        rewardXP: 100,
        duration: const Duration(days: 7),
      ),
      ChallengeDefinition(
        id: 'weekly_return_3',
        name: 'Reunion Master',
        description: 'Return 3 items to their owners this week',
        icon: '🎁',
        type: ChallengeType.weekly,
        category: ChallengeCategory.returning,
        difficulty: ChallengeDifficulty.hard,
        targetCount: 3,
        rewardKarma: 100,
        rewardPoints: 50,
        rewardXP: 150,
        duration: const Duration(days: 7),
      ),
      
      // Monthly challenges
      ChallengeDefinition(
        id: 'monthly_post_20',
        name: 'Dedicated Scout',
        description: 'Post 20 found items this month',
        icon: '🏃',
        type: ChallengeType.monthly,
        category: ChallengeCategory.posting,
        difficulty: ChallengeDifficulty.hard,
        targetCount: 20,
        rewardKarma: 200,
        rewardPoints: 100,
        rewardXP: 300,
        duration: const Duration(days: 30),
      ),
      ChallengeDefinition(
        id: 'monthly_return_10',
        name: 'Community Hero',
        description: 'Return 10 items this month',
        icon: '🦸',
        type: ChallengeType.monthly,
        category: ChallengeCategory.returning,
        difficulty: ChallengeDifficulty.epic,
        targetCount: 10,
        rewardKarma: 300,
        rewardPoints: 150,
        rewardXP: 500,
        duration: const Duration(days: 30),
      ),
      
      // Streak challenges
      ChallengeDefinition(
        id: 'streak_3',
        name: 'Consistent Helper',
        description: 'Log in 3 days in a row',
        icon: '🔥',
        type: ChallengeType.milestone,
        category: ChallengeCategory.streak,
        difficulty: ChallengeDifficulty.easy,
        targetCount: 3,
        rewardKarma: 15,
        rewardPoints: 10,
        rewardXP: 30,
      ),
      ChallengeDefinition(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: 'Maintain a 7-day login streak',
        icon: '⚡',
        type: ChallengeType.milestone,
        category: ChallengeCategory.streak,
        difficulty: ChallengeDifficulty.medium,
        targetCount: 7,
        rewardKarma: 50,
        rewardPoints: 25,
        rewardXP: 75,
      ),
    ];

    final batch = _firestore.batch();
    
    for (final challenge in defaults) {
      final ref = _firestore.collection('challenge_definitions').doc(challenge.id);
      batch.set(ref, challenge.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Seed default badge definitions (call once to initialize)
  Future<void> seedDefaultBadges() async {
    final defaults = [
      // Welcome badge (instant)
      BadgeDefinition(
        id: 'welcome',
        name: 'Welcome!',
        description: 'Joined the iBalik community',
        icon: '👋',
        rarity: BadgeRarity.common,
        unlockCondition: 'Join iBalik',
        criteria: {'level': 1}, // Everyone starts at level 1
      ),
      
      // Starter badges (very easy)
      BadgeDefinition(
        id: 'karma_10',
        name: 'Getting Started',
        description: 'Earned your first 10 karma',
        icon: '🌱',
        rarity: BadgeRarity.common,
        unlockCondition: 'Earn 10 karma',
        criteria: {'karma': 10},
      ),
      BadgeDefinition(
        id: 'karma_50',
        name: 'Good Neighbor',
        description: 'Reached 50 karma points',
        icon: '🏠',
        rarity: BadgeRarity.common,
        unlockCondition: 'Earn 50 karma',
        criteria: {'karma': 50},
      ),
      
      // Posting badges
      BadgeDefinition(
        id: 'first_post',
        name: 'First Find',
        description: 'Posted your first found item',
        icon: '🔎',
        rarity: BadgeRarity.common,
        unlockCondition: 'Post 1 found item',
        criteria: {'itemsPosted': 1},
      ),
      BadgeDefinition(
        id: 'post_5',
        name: 'Active Scout',
        description: 'Posted 5 found items',
        icon: '🔦',
        rarity: BadgeRarity.common,
        unlockCondition: 'Post 5 found items',
        criteria: {'itemsPosted': 5},
      ),
      BadgeDefinition(
        id: 'post_10',
        name: 'Eagle Eye',
        description: 'Posted 10 found items',
        icon: '🦅',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Post 10 found items',
        criteria: {'itemsPosted': 10},
      ),
      BadgeDefinition(
        id: 'post_50',
        name: 'Lost & Found Expert',
        description: 'Posted 50 found items',
        icon: '🏆',
        rarity: BadgeRarity.epic,
        unlockCondition: 'Post 50 found items',
        criteria: {'itemsPosted': 50},
      ),
      
      // Return badges
      BadgeDefinition(
        id: 'first_return',
        name: 'Good Deed',
        description: 'Returned your first item to its owner',
        icon: '💝',
        rarity: BadgeRarity.common,
        unlockCondition: 'Return 1 item',
        criteria: {'itemsReturned': 1},
      ),
      BadgeDefinition(
        id: 'return_5',
        name: 'Helping Hand',
        description: 'Returned 5 items to their owners',
        icon: '🤲',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Return 5 items',
        criteria: {'itemsReturned': 5},
      ),
      BadgeDefinition(
        id: 'return_20',
        name: 'Campus Guardian',
        description: 'Returned 20 items to their owners',
        icon: '🛡️',
        rarity: BadgeRarity.epic,
        unlockCondition: 'Return 20 items',
        criteria: {'itemsReturned': 20},
      ),
      BadgeDefinition(
        id: 'return_50',
        name: 'Legendary Reuniter',
        description: 'Returned 50 items to their owners',
        icon: '👑',
        rarity: BadgeRarity.legendary,
        unlockCondition: 'Return 50 items',
        criteria: {'itemsReturned': 50},
      ),
      
      // Karma badges
      BadgeDefinition(
        id: 'karma_100',
        name: 'Good Vibes',
        description: 'Reached 100 karma points',
        icon: '✨',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Earn 100 karma',
        criteria: {'karma': 100},
      ),
      BadgeDefinition(
        id: 'karma_250',
        name: 'Karma Rising',
        description: 'Reached 250 karma points',
        icon: '🌈',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Earn 250 karma',
        criteria: {'karma': 250},
      ),
      BadgeDefinition(
        id: 'karma_500',
        name: 'Karma Champion',
        description: 'Reached 500 karma points',
        icon: '🌟',
        rarity: BadgeRarity.epic,
        unlockCondition: 'Earn 500 karma',
        criteria: {'karma': 500},
      ),
      BadgeDefinition(
        id: 'karma_1000',
        name: 'Karma Master',
        description: 'Reached 1000 karma points',
        icon: '💫',
        rarity: BadgeRarity.legendary,
        unlockCondition: 'Earn 1000 karma',
        criteria: {'karma': 1000},
      ),
      
      // Level badges
      BadgeDefinition(
        id: 'level_5',
        name: 'Rising Star',
        description: 'Reached level 5',
        icon: '⭐',
        rarity: BadgeRarity.common,
        unlockCondition: 'Reach level 5',
        criteria: {'level': 5},
      ),
      BadgeDefinition(
        id: 'level_10',
        name: 'Seasoned Helper',
        description: 'Reached level 10',
        icon: '🌠',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Reach level 10',
        criteria: {'level': 10},
      ),
      BadgeDefinition(
        id: 'level_20',
        name: 'Elite Guardian',
        description: 'Reached level 20',
        icon: '🏅',
        rarity: BadgeRarity.epic,
        unlockCondition: 'Reach level 20',
        criteria: {'level': 20},
      ),
      
      // Streak badges
      BadgeDefinition(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: 'Maintained a 7-day streak',
        icon: '🔥',
        rarity: BadgeRarity.common,
        unlockCondition: '7-day streak',
        criteria: {'streak': 7},
      ),
      BadgeDefinition(
        id: 'streak_30',
        name: 'Dedicated Helper',
        description: 'Maintained a 30-day streak',
        icon: '🎯',
        rarity: BadgeRarity.rare,
        unlockCondition: '30-day streak',
        criteria: {'streak': 30},
      ),
      BadgeDefinition(
        id: 'streak_100',
        name: 'Unstoppable',
        description: 'Maintained a 100-day streak',
        icon: '💎',
        rarity: BadgeRarity.legendary,
        unlockCondition: '100-day streak',
        criteria: {'streak': 100},
      ),
      
      // Special badges
      BadgeDefinition(
        id: 'early_adopter',
        name: 'Early Adopter',
        description: 'Joined during the beta period',
        icon: '🚀',
        rarity: BadgeRarity.legendary,
        unlockCondition: 'Join during beta',
        criteria: {},
      ),
      BadgeDefinition(
        id: 'challenge_10',
        name: 'Challenge Accepted',
        description: 'Completed 10 challenges',
        icon: '🎮',
        rarity: BadgeRarity.rare,
        unlockCondition: 'Complete 10 challenges',
        criteria: {'challengesCompleted': 10},
      ),
    ];

    final batch = _firestore.batch();
    
    for (final badge in defaults) {
      final ref = _firestore.collection('badge_definitions').doc(badge.id);
      batch.set(ref, badge.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
    
    // Reload definitions
    await _loadBadgeDefinitions();
  }

  /// Initialize default data - always re-seeds to ensure new content is added
  Future<void> initializeDefaultData() async {
    try {
      // Always seed challenge definitions (merge: true will update existing)
      await _seedDefaultChallenges();
      
      // Always seed badge definitions (merge: true will update existing)
      await seedDefaultBadges();
    } catch (e) {
      debugPrint('Error initializing default data: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Force refresh challenges (e.g., pull to refresh)
  Future<void> refreshChallenges() async {
    final userId = _userId;
    if (userId == null) return;
    
    // Clean up expired challenges
    await _cleanupExpiredChallenges(userId);
    
    // Ensure user has active challenges
    await _ensureActiveChallenges(userId);
  }

  Future<void> _cleanupExpiredChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: false)
          .get();

      final now = DateTime.now();
      final batch = _firestore.batch();
      int cleaned = 0;

      for (final doc in snapshot.docs) {
        final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
        if (expiresAt != null && expiresAt.isBefore(now)) {
          batch.update(doc.reference, {
            'isExpired': true,
            'isCompleted': true, // Mark as completed (failed) so user doesn't see it
          });
          cleaned++;
        }
      }

      if (cleaned > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error cleaning up expired challenges: $e');
    }
  }

  /// Get available (not yet earned) badges with progress
  List<Map<String, dynamic>> getAvailableBadgesWithProgress() {
    final earnedIds = _earnedBadges.map((b) => b.badgeId).toSet();
    
    return _allBadgeDefinitions
        .where((def) => !earnedIds.contains(def.id))
        .map((def) {
          final progress = getBadgeProgress(def);
          return {
            'definition': def,
            ...progress,
          };
        })
        .toList()
      ..sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));
  }

  /// Get recent achievements (badges and completed challenges)
  Future<List<Map<String, dynamic>>> getRecentAchievements({int limit = 5}) async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final achievements = <Map<String, dynamic>>[];

      // Get recent badges
      final badgesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .orderBy('earnedAt', descending: true)
          .limit(limit)
          .get();

      for (final doc in badgesSnapshot.docs) {
        final badge = UserBadge.fromFirestore(doc);
        achievements.add({
          'type': 'badge',
          'name': badge.name,
          'icon': badge.icon,
          'date': badge.earnedAt,
        });
      }

      // Get recent completed challenges
      final challengesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      for (final doc in challengesSnapshot.docs) {
        final challenge = UserChallenge.fromFirestore(doc);
        achievements.add({
          'type': 'challenge',
          'name': challenge.challengeName,
          'icon': challenge.icon,
          'date': challenge.completedAt ?? challenge.startedAt,
        });
      }

      // Sort by date and return top items
      achievements.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return achievements.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent achievements: $e');
      return [];
    }
  }
}
