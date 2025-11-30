import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/page_transitions.dart';
import '../home/home_page.dart';
import '../../utils/app_theme.dart';

class ReturnSuccessPage extends StatefulWidget {
  final int pointsEarned;
  final int karmaEarned;
  final int xpEarned;
  
  const ReturnSuccessPage({
    super.key,
    this.pointsEarned = 20,  // Default from GameService.rewardSuccessfulReturn
    this.karmaEarned = 15,
    this.xpEarned = 25,
  });

  @override
  State<ReturnSuccessPage> createState() => _ReturnSuccessPageState();
}

class _ReturnSuccessPageState extends State<ReturnSuccessPage> {
  bool _loading = true;
  int _totalItemsReturned = 0;
  int _totalStudentsHelped = 0;
  int _campusRank = 0;
  int _currentLevel = 1;
  String _levelTitle = 'Newcomer';
  bool _leveledUp = false;
  int _previousLevel = 1;
  
  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }
  
  Future<void> _loadUserStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        
        // Get items returned (just updated)
        final itemsReturned = (data['itemsReturned'] ?? 0) as int;
        
        // Calculate students helped (could be claims + returns)
        final claimsApproved = (data['claimsApproved'] ?? 0) as int;
        final studentsHelped = itemsReturned + claimsApproved;
        
        // Get current level
        final level = (data['level'] ?? 1) as int;
        
        // Check if just leveled up (compare with previous activities)
        final activitiesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .limit(2)
            .get();
        
        bool levelUp = false;
        int prevLevel = level;
        if (activitiesSnapshot.docs.length >= 2) {
          // Check if most recent activity is level up
          final recentActivity = activitiesSnapshot.docs.first.data();
          if (recentActivity['type'] == 'level_up') {
            levelUp = true;
            prevLevel = level - 1;
          }
        }
        
        // Get user rank
        final higherKarmaQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('karma', isGreaterThan: data['karma'] ?? 0)
            .count()
            .get();
        final rank = (higherKarmaQuery.count ?? 0) + 1;
        
        if (mounted) {
          setState(() {
            _totalItemsReturned = itemsReturned;
            _totalStudentsHelped = studentsHelped;
            _campusRank = rank;
            _currentLevel = level;
            _levelTitle = _getLevelTitle(level);
            _leveledUp = levelUp;
            _previousLevel = prevLevel;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  String _getLevelTitle(int level) {
    if (level >= 10) return 'Legend';
    if (level >= 8) return 'Champion';
    if (level >= 6) return 'Hero';
    if (level >= 4) return 'Helper';
    if (level >= 2) return 'Beginner';
    return 'Newcomer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Top gradient section with trophy
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4ECDC4),
                      Color(0xFF44A08D),
                      Color(0xFFC6EA8D),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFFD700),
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amazing Work!',
                      style: AppTextStyles.successHeader,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'ve successfully returned\nanother item!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Rewards Earned Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Rewards Earned',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your contribution has been recognized!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Points, Karma, and XP
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.stars,
                                        color: Color(0xFF2196F3),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${widget.pointsEarned}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2196F3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Points',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2196F3),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Color(0xFF9C27B0),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${widget.karmaEarned}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF9C27B0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Karma',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9C27B0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        color: Color(0xFF4CAF50),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${widget.xpEarned}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'XP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Level Up (only show if leveled up)
                      if (_leveledUp)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFFFD700),
                                    size: 32,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Level Up!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You\'re now Level $_currentLevel • $_levelTitle',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Leveled up from Level $_previousLevel!',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF66BB6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (!_leveledUp)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Current Level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Level $_currentLevel • $_levelTitle',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Keep helping to level up!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF66BB6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Your Community Impact Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F1FF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Community Impact',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Making WVSU a better place',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  _totalItemsReturned.toString(),
                                  'Items Returned',
                                  const Color(0xFF6C63FF),
                                ),
                                _buildStatItem(
                                  _totalStudentsHelped.toString(),
                                  'Students Helped',
                                  const Color(0xFF6C63FF),
                                ),
                                _buildStatItem(
                                  _campusRank > 0 ? '#$_campusRank' : 'N/A',
                                  'Campus Rank',
                                  const Color(0xFF6C63FF),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // You're Making a Difference Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Color(0xFFFF4081),
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'You\'re Making a Difference!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC2185B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Every item you return helps create a more caring and connected campus community. Your kindness has a ripple effect that touches more lives than you know.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFD81B60),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            SmoothPageRoute(page: const HomePage()),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Social Share Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Color(0xFFFF6B35),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Want to share your good deed? Tag us',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@IBalikWVSU on social media!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }


}
