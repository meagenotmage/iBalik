import 'package:cloud_firestore/cloud_firestore.dart';

// ============ CHALLENGE MODELS ============

/// Challenge type determines how progress is tracked
enum ChallengeType {
  daily,
  weekly,
  monthly,
  special,
  milestone,
}

/// Challenge category for filtering and display
enum ChallengeCategory {
  posting,      // Post found items
  returning,    // Return items to owners
  claiming,     // Claim lost items
  location,     // Location-based challenges
  category,     // Category-specific (electronics, documents, etc.)
  streak,       // Consecutive day activities
  community,    // Help other users
}

/// Challenge difficulty affects rewards
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  epic,
}

/// Challenge definition (template stored in /challenge_definitions)
class ChallengeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final ChallengeType type;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final int targetCount;
  final int rewardKarma;
  final int rewardPoints;
  final int rewardXP;
  final Duration? duration; // null for milestones
  final Map<String, dynamic>? requirements; // Additional conditions
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  ChallengeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.targetCount,
    required this.rewardKarma,
    required this.rewardPoints,
    required this.rewardXP,
    this.duration,
    this.requirements,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  factory ChallengeDefinition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeDefinition(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🎯',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.daily,
      ),
      category: ChallengeCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ChallengeCategory.posting,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      targetCount: data['targetCount'] ?? 1,
      rewardKarma: data['rewardKarma'] ?? 0,
      rewardPoints: data['rewardPoints'] ?? 0,
      rewardXP: data['rewardXP'] ?? 0,
      duration: data['durationHours'] != null 
          ? Duration(hours: data['durationHours']) 
          : null,
      requirements: data['requirements'] as Map<String, dynamic>?,
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.name,
      'category': category.name,
      'difficulty': difficulty.name,
      'targetCount': targetCount,
      'rewardKarma': rewardKarma,
      'rewardPoints': rewardPoints,
      'rewardXP': rewardXP,
      'durationHours': duration?.inHours,
      'requirements': requirements,
      'isActive': isActive,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}

/// User's progress on a specific challenge
class UserChallenge {
  final String id;
  final String challengeId;
  final String challengeName;
  final String description;
  final String icon;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int currentProgress;
  final int targetCount;
  final int rewardKarma;
  final int rewardPoints;
  final int rewardXP;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  UserChallenge({
    required this.id,
    required this.challengeId,
    required this.challengeName,
    required this.description,
    required this.icon,
    required this.type,
    required this.difficulty,
    required this.currentProgress,
    required this.targetCount,
    required this.rewardKarma,
    required this.rewardPoints,
    required this.rewardXP,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
    this.expiresAt,
  });

  double get progressPercent => targetCount > 0 ? currentProgress / targetCount : 0;
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  String get timeLeftString {
    if (expiresAt == null) return 'No time limit';
    if (isExpired) return 'Expired';
    
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) return '${diff.inHours} hours left';
    return '${diff.inMinutes} min left';
  }

  factory UserChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserChallenge(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      challengeName: data['challengeName'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🎯',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.daily,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      currentProgress: data['currentProgress'] ?? 0,
      targetCount: data['targetCount'] ?? 1,
      rewardKarma: data['rewardKarma'] ?? 0,
      rewardPoints: data['rewardPoints'] ?? 0,
      rewardXP: data['rewardXP'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'description': description,
      'icon': icon,
      'type': type.name,
      'difficulty': difficulty.name,
      'currentProgress': currentProgress,
      'targetCount': targetCount,
      'rewardKarma': rewardKarma,
      'rewardPoints': rewardPoints,
      'rewardXP': rewardXP,
      'isCompleted': isCompleted,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  UserChallenge copyWith({
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return UserChallenge(
      id: id,
      challengeId: challengeId,
      challengeName: challengeName,
      description: description,
      icon: icon,
      type: type,
      difficulty: difficulty,
      currentProgress: currentProgress ?? this.currentProgress,
      targetCount: targetCount,
      rewardKarma: rewardKarma,
      rewardPoints: rewardPoints,
      rewardXP: rewardXP,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt,
    );
  }
}

// ============ BADGE MODELS ============

/// Badge rarity affects display and prestige
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Badge definition (template stored in /badge_definitions)
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final String unlockCondition; // Human-readable condition
  final Map<String, dynamic> criteria; // Machine-readable criteria
  final bool isActive;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.unlockCondition,
    required this.criteria,
    this.isActive = true,
  });

  factory BadgeDefinition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeDefinition(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      unlockCondition: data['unlockCondition'] ?? '',
      criteria: data['criteria'] as Map<String, dynamic>? ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity.name,
      'unlockCondition': unlockCondition,
      'criteria': criteria,
      'isActive': isActive,
    };
  }
}

/// User's earned badge
class UserBadge {
  final String id;
  final String badgeId;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.badgeId,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.earnedAt,
  });

  factory UserBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadge(
      id: doc.id,
      badgeId: data['badgeId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'badgeId': badgeId,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity.name,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }
}

// ============ LEADERBOARD MODELS ============

/// User stats for leaderboard ranking
class UserStats {
  final String odI;
  final String userName;
  final String? profileImageUrl;
  final String? department;
  final int karma;
  final int points;
  final int level;
  final int itemsPosted;
  final int itemsReturned;
  final int claimsMade;
  final int claimsApproved;
  final int currentStreak;
  final int longestStreak;
  final int badgesEarned;
  final int challengesCompleted;
  final DateTime? lastActiveAt;

  UserStats({
    required this.odI,
    required this.userName,
    this.profileImageUrl,
    this.department,
    required this.karma,
    required this.points,
    required this.level,
    required this.itemsPosted,
    required this.itemsReturned,
    required this.claimsMade,
    required this.claimsApproved,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgesEarned,
    required this.challengesCompleted,
    this.lastActiveAt,
  });

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return 'UN';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStats(
      odI: doc.id,
      userName: data['username'] ?? data['name'] ?? 'Unknown',
      profileImageUrl: data['profileImageUrl'],
      department: data['department'],
      karma: (data['karma'] ?? 0).toInt(),
      points: (data['points'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      itemsPosted: (data['itemsPosted'] ?? 0).toInt(),
      itemsReturned: (data['itemsReturned'] ?? data['returned'] ?? 0).toInt(),
      claimsMade: (data['claimsMade'] ?? 0).toInt(),
      claimsApproved: (data['claimsApproved'] ?? 0).toInt(),
      currentStreak: (data['currentStreak'] ?? data['streak'] ?? 0).toInt(),
      longestStreak: (data['longestStreak'] ?? 0).toInt(),
      badgesEarned: (data['badgesEarned'] ?? 0).toInt(),
      challengesCompleted: (data['challengesCompleted'] ?? 0).toInt(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'profileImageUrl': profileImageUrl,
      'department': department,
      'karma': karma,
      'points': points,
      'level': level,
      'itemsPosted': itemsPosted,
      'itemsReturned': itemsReturned,
      'claimsMade': claimsMade,
      'claimsApproved': claimsApproved,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badgesEarned': badgesEarned,
      'challengesCompleted': challengesCompleted,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }
}

/// Leaderboard entry with rank
class LeaderboardEntry {
  final int rank;
  final UserStats user;
  final int? weeklyChange; // Change in karma this week

  LeaderboardEntry({
    required this.rank,
    required this.user,
    this.weeklyChange,
  });
}

/// Leaderboard ranking criteria
enum LeaderboardCriteria {
  karma,
  points,
  itemsReturned,
  itemsPosted,
  level,
  streak,
}

extension LeaderboardCriteriaExtension on LeaderboardCriteria {
  String get displayName {
    switch (this) {
      case LeaderboardCriteria.karma:
        return 'Karma';
      case LeaderboardCriteria.points:
        return 'Points';
      case LeaderboardCriteria.itemsReturned:
        return 'Items Returned';
      case LeaderboardCriteria.itemsPosted:
        return 'Items Posted';
      case LeaderboardCriteria.level:
        return 'Level';
      case LeaderboardCriteria.streak:
        return 'Streak';
    }
  }

  String get firestoreField {
    switch (this) {
      case LeaderboardCriteria.karma:
        return 'karma';
      case LeaderboardCriteria.points:
        return 'points';
      case LeaderboardCriteria.itemsReturned:
        return 'itemsReturned';
      case LeaderboardCriteria.itemsPosted:
        return 'itemsPosted';
      case LeaderboardCriteria.level:
        return 'level';
      case LeaderboardCriteria.streak:
        return 'currentStreak';
    }
  }
}

// ============ ACTION TRACKING ============

/// Actions that can trigger challenge/badge progress
enum GameAction {
  itemPosted,
  itemReturned,
  claimSubmitted,
  claimApproved,
  claimDenied,
  hubDropOff,
  dailyLogin,
  profileUpdated,
}

/// Metadata for an action (for filtering/matching criteria)
class ActionMetadata {
  final GameAction action;
  final String? category;      // Item category
  final String? location;      // Building/location
  final DateTime timestamp;
  final Map<String, dynamic>? extra;

  ActionMetadata({
    required this.action,
    this.category,
    this.location,
    DateTime? timestamp,
    this.extra,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'action': action.name,
      'category': category,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'extra': extra,
    };
  }
}
