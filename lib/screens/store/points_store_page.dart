import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../utils/page_transitions.dart';
import '../../services/game_service.dart';
import 'reward_token_page.dart';

class PointsStorePage extends StatefulWidget {
  const PointsStorePage({super.key});

  @override
  State<PointsStorePage> createState() => _PointsStorePageState();
}

class _PointsStorePageState extends State<PointsStorePage> {
  final GameService _gameService = GameService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;

  // Available rewards
  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 'gift_card_50',
      'title': 'Gift Card ₱50',
      'description': 'Redeemable at WVSU Canteen',
      'cost': 500,
      'icon': Icons.card_giftcard,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'gift_card_100',
      'title': 'Gift Card ₱100',
      'description': 'Redeemable at WVSU Canteen',
      'cost': 1000,
      'icon': Icons.card_giftcard,
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'school_supplies',
      'title': 'School Supplies Pack',
      'description': 'Notebook, pens, and highlighters',
      'cost': 300,
      'icon': Icons.school,
      'color': Color(0xFF9C27B0),
    },
    {
      'id': 'library_voucher',
      'title': 'Library Access Voucher',
      'description': 'Extended library hours for 1 week',
      'cost': 200,
      'icon': Icons.library_books,
      'color': Color(0xFF607D8B),
    },
    {
      'id': 'parking_pass',
      'title': 'Parking Pass',
      'description': 'Free parking for 1 week',
      'cost': 400,
      'icon': Icons.local_parking,
      'color': Color(0xFF795548),
    },
    {
      'id': 'premium_badge',
      'title': 'Premium Profile Badge',
      'description': 'Special badge for your profile',
      'cost': 150,
      'icon': Icons.stars,
      'color': Color(0xFFFF9800),
    },
  ];

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onGameServiceUpdate);
  }
  
  @override
  void dispose() {
    _gameService.removeListener(_onGameServiceUpdate);
    super.dispose();
  }
  
  void _onGameServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    if (_gameService.points < reward['cost']) {
      _showInsufficientPointsDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique token
      final tokenCode = _generateTokenCode();
      final redemptionDate = DateTime.now();

      // Create batch for atomic operations
      final batch = _firestore.batch();

      // 1. Deduct points from user
      final userGameDataRef = _firestore.collection('game_data').doc(user.uid);
      batch.update(userGameDataRef, {
        'points': FieldValue.increment(-reward['cost']),
      });

      // 2. Log redemption history
      final redemptionRef = _firestore.collection('redemptions').doc();
      batch.set(redemptionRef, {
        'userId': user.uid,
        'userEmail': user.email,
        'rewardId': reward['id'],
        'rewardTitle': reward['title'],
        'pointsCost': reward['cost'],
        'tokenCode': tokenCode,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'redeemed',
      });

      // 3. Add activity
      final activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'userId': user.uid,
        'type': 'reward_redeemed',
        'title': 'Reward Redeemed',
        'message': 'You redeemed ${reward['title']} for ${reward['cost']} points',
        'createdAt': FieldValue.serverTimestamp(),
        'meta': {
          'rewardId': reward['id'],
          'rewardTitle': reward['title'],
          'pointsCost': reward['cost'],
          'tokenCode': tokenCode,
        },
      });

      // Commit all operations
      await batch.commit();

      // Update local points
      setState(() {
        // Points are automatically updated via GameService listener
        _isLoading = false;
      });

      // Navigate to reward token screen
      Navigator.push(
        context,
        SmoothPageRoute(
          page: RewardTokenPage(
            reward: reward,
            tokenCode: tokenCode,
            redemptionDate: redemptionDate,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to redeem reward: ${e.toString()}');
    }
  }

  String _generateTokenCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    
    for (int i = 0; i < 8; i++) {
      result += chars[(random + i) % chars.length];
    }
    
    return 'WVSU-$result';
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Insufficient Points'),
          ],
        ),
        content: Text('You don\'t have enough points for this reward. Keep helping the community to earn more points!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points Store',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Redeem your points for rewards',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          // Points Balance Card
          Container(
            margin: EdgeInsets.all(AppSpacing.lg),
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.stars,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Points Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_gameService.points}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ],
            ),
          ),

          // Rewards List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _rewards.length,
              itemBuilder: (context, index) {
                final reward = _rewards[index];
                  final canAfford = _gameService.points >= reward['cost'];                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: canAfford 
                          ? reward['color'].withOpacity(0.3)
                          : AppColors.lightGray,
                      width: 1,
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        // Reward Icon
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? reward['color'].withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            reward['icon'],
                            color: canAfford ? reward['color'] : Colors.grey,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        
                        // Reward Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford 
                                      ? AppColors.textPrimary 
                                      : AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                reward['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${reward['cost']} points',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: canAfford 
                                          ? AppColors.primary 
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Redeem Button
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: canAfford && !_isLoading
                                ? () => _redeemReward(reward)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canAfford 
                                  ? AppColors.primary 
                                  : AppColors.lightGray,
                              foregroundColor: Colors.white,
                              elevation: canAfford ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    canAfford ? 'Redeem' : 'Need ${reward['cost'] - _gameService.points}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Info
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.lightBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Earn points by helping the WVSU community! Find and return lost items, complete challenges, and engage with the platform.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}