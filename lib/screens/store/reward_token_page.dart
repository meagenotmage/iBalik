import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';

class RewardTokenPage extends StatelessWidget {
  final Map<String, dynamic> reward;
  final String tokenCode;
  final DateTime redemptionDate;

  const RewardTokenPage({
    super.key,
    required this.reward,
    required this.tokenCode,
    required this.redemptionDate,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _copyTokenCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: tokenCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token code copied to clipboard'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: Text(
          'Reward Token',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Take a screenshot to save your reward token!'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: Icon(Icons.screenshot, color: AppColors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Success Message
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              margin: EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Redemption Successful!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'Your reward token has been generated',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Reward Token Card (Main Screenshot Area)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: reward['color'] ?? AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: (reward['color'] ?? AppColors.primary).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WVSU iBalik',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'REWARD TOKEN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                reward['icon'] ?? Icons.card_giftcard,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSpacing.xl),

                        // Reward Details
                        Container(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward['title'] ?? 'Unknown Reward',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                reward['description'] ?? 'Reward description',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${reward['cost']} points redeemed',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.xl),

                        // Token Code Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TOKEN CODE',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _copyTokenCode(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightGray),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        tokenCode,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.copy,
                                        color: AppColors.textSecondary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Footer Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'USER ID',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  user?.uid.substring(0, 8).toUpperCase() ?? 'UNKNOWN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'REDEEMED',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  _formatDate(redemptionDate),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatTime(redemptionDate),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Instructions
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'How to use this token',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  _buildInstructionItem('📸', 'Take a screenshot of this token card'),
                  _buildInstructionItem('🏪', 'Present this token at the redemption location'),
                  _buildInstructionItem('📋', 'Show your token code to the staff'),
                  _buildInstructionItem('✅', 'Enjoy your reward!'),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Screenshot this page to save your token!'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.screenshot, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Screenshot',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String emoji, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}