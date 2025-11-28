import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../utils/claims_theme.dart';
import '../../services/notification_service.dart';
import '../../services/activity_service.dart';

class ClaimReviewPage extends StatelessWidget {
  final Map<String, dynamic> claimData;

  const ClaimReviewPage({super.key, required this.claimData});

  String _formatSubmitted(dynamic ts) {
    if (ts == null) return 'Unknown';
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else {
        dt = DateTime.parse(ts.toString());
      }
      final date =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date • $time';
    } catch (_) {
      // Fallback: just return plain string without nanoseconds if possible
      return ts.toString().split('.').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedStr = _formatSubmitted(claimData['submittedDate']);
    final bool hasImage = claimData['proofImage'] != null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Review and decide',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(ClaimsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Card
            Container(
              padding: EdgeInsets.all(ClaimsSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Item Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                        SizedBox(width: ClaimsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claimData['itemTitle'] ?? 'Student ID - Jane Smith',
                          style: ClaimsTypography.subtitle,
                        ),
                        SizedBox(height: ClaimsSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Claim submitted\n$submittedStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${claimData['claimerName'] ?? 'J. Smith'}\nEmail: ${claimData['claimerEmail'] ?? 'jane.smith@wvsu.edu.ph'}\nContact: ${claimData['claimerProvidedContactValue'] ?? claimData['claimerPhone'] ?? 'No contact provided'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Claim Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: ClaimsColors.info,
                      ),
                      SizedBox(width: ClaimsSpacing.xs),
                      Text(
                        'Claim Description',
                        style: ClaimsTypography.subtitle,
                      ),
                    ],
                  ),
                  SizedBox(height: ClaimsSpacing.xxs),
                  Text(
                    'Why they believe this item belongs to them',
                    style: ClaimsTypography.caption,
                  ),
                  SizedBox(height: ClaimsSpacing.md),
                  Text(
                    claimData['claimDescription'] ??  
                    'This is my student ID. I lost it yesterday near the gymnasium. My student number is 2021-12345 and I remember dropping it when I was getting my things from my bag after basketball practice.',
                    style: ClaimsTypography.body.copyWith(height: 1.5),
                  ),
                  if ((claimData['additionalInfo'] ?? '').toString().trim().isNotEmpty) ...[
                      SizedBox(height: ClaimsSpacing.sm),
                      Text('Additional Details (provided by claimer):', style: ClaimsTypography.bodyBold.copyWith(color: Colors.orange)),
                      SizedBox(height: ClaimsSpacing.xxs),
                      Text(
                        claimData['additionalInfo'],
                        style: ClaimsTypography.body,
                      ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: ClaimsSpacing.lg),
            
            // Image Proof Section (only if image exists)
            if (hasImage) ...[
              Container(
                padding: EdgeInsets.all(ClaimsSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Image Proof',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo provided by claimant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Seeker (founder) Contact Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claimer Information',
                    style: ClaimsTypography.subtitle,
                  ),
                  SizedBox(height: ClaimsSpacing.md),
                  ClaimsWidgets.infoRow(
                    icon: Icons.person,
                    text: claimData['claimerName'] ?? 'Unknown Claimer',
                  ),
                  SizedBox(height: ClaimsSpacing.sm),
                  ClaimsWidgets.infoRow(
                    icon: Icons.phone,
                    text: claimData['claimerProvidedContactValue'] ?? claimData['claimerPhone'] ?? 'No contact provided',
                  ),
                  SizedBox(height: ClaimsSpacing.sm),
                  ClaimsWidgets.infoRow(
                    icon: Icons.email,
                    text: claimData['claimerEmail'] ?? 'No email provided',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ClaimsSpacing.lg),
            
            // Verification Tips Card
            Container(
              padding: EdgeInsets.all(ClaimsSpacing.lg),
              decoration: ClaimsCardStyles.infoCard(ClaimsColors.pendingLight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ClaimsColors.pending,
                        size: 20,
                      ),
                      SizedBox(width: ClaimsSpacing.xs),
                      Text(
                        'Verification Tips',
                        style: ClaimsTypography.subtitle.copyWith(
                          color: ClaimsColors.pending,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Before approving, consider asking the claimant to:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Provide additional details about the item\'s condition'),
                  _buildTipItem('Show their student ID for verification'),
                  _buildTipItem('Describe the contents or unique markings'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons using ClaimsButton
            Row(
              children: [
                Expanded(
                  child: ClaimsButton(
                    label: 'Reject Claim',
                    icon: Icons.cancel_outlined,
                    onPressed: () => _showRejectDialog(context),
                    type: ClaimsButtonType.reject,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClaimsButton(
                    label: 'Approve Claim',
                    icon: Icons.check_circle,
                    onPressed: () => _showApproveDialog(context),
                    type: ClaimsButtonType.approve,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.blue[400]!,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Reject Claim?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to reject this claim? The claimant will be notified.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Attempt to mark claim as rejected in Firestore
              final claimId = claimData['docId'] as String?;
              final claimerId = claimData['claimerId'] as String?;
              final itemId = claimData['itemId'];
              final itemTitle = claimData['itemTitle'] ?? '';
              final claimerName = claimData['claimerName'] ?? 'Unknown';
              
              if (claimId != null) {
                try {
                  final fs = FirebaseFirestore.instance;
                  
                  // Update claim status
                  await fs.collection('claims').doc(claimId).update({
                    'status': 'rejected',
                    'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
                    'rejectedAt': FieldValue.serverTimestamp(),
                  });

                  // Notify claimer using NotificationService
                  if (claimerId != null) {
                    try {
                      final notificationService = NotificationService();
                      await notificationService.notifyUserClaimDenied(
                        userId: claimerId,
                        itemName: itemTitle,
                        claimId: claimId,
                        itemId: itemId?.toString(),
                      );
                    } catch (_) {}
                  }

                  // Record activity for claimer using ActivityService
                  if (claimerId != null) {
                    try {
                      final activityService = ActivityService();
                      await activityService.recordUserClaimDenied(
                        userId: claimerId,
                        itemName: itemTitle,
                        claimId: claimId,
                      );
                    } catch (_) {}
                  }

                  // Record activity for the reviewer (current user - the finder)
                  try {
                    final activityService = ActivityService();
                    await activityService.recordClaimReviewed(
                      itemName: itemTitle,
                      decision: 'Rejected',
                      claimerName: claimerName,
                      claimId: claimId,
                    );
                  } catch (_) {}
                  
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Claim rejected successfully'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reject claim: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Close loading dialog if it was shown
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
              
              // Go back to claims page (StreamBuilder will automatically update)
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Reject',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 12),
            Text('Approve Claim?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to approve this claim? The claimant will be able to coordinate pickup with you.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Approve claim: update claim doc and update lost_items to 'claimed'
              final claimId = claimData['docId'] as String?;
              final claimerId = claimData['claimerId'] as String?;
              final itemId = claimData['itemId'];
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final itemTitle = claimData['itemTitle'] ?? '';
              final claimerName = claimData['claimerName'] ?? 'Unknown';

              if (claimId != null) {
                try {
                  final fs = FirebaseFirestore.instance;
                  
                  // Update claim status (this will trigger StreamBuilder updates for both users)
                  await fs.collection('claims').doc(claimId).update({
                    'status': 'approved',
                    'approvedBy': currentUid,
                    'approvedAt': FieldValue.serverTimestamp(),
                  });

                  // Try to update lost_items doc by doc id first
                  if (itemId != null) {
                    try {
                      final itemRef = fs.collection('lost_items').doc(itemId.toString());
                      await itemRef.update({
                        'status': 'claimed',
                        'claimedBy': claimerId,
                        'claimedAt': FieldValue.serverTimestamp(),
                        'claimId': claimId,
                      });
                    } catch (_) {
                      // fallback: find by itemId field
                      try {
                        final q = await fs.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
                        if (q.docs.isNotEmpty) {
                          await q.docs.first.reference.update({
                            'status': 'claimed',
                            'claimedBy': claimerId,
                            'claimedAt': FieldValue.serverTimestamp(),
                            'claimId': claimId,
                          });
                        }
                      } catch (_) {}
                    }
                  }

                  // Notify claimer using NotificationService
                  if (claimerId != null) {
                    try {
                      final notificationService = NotificationService();
                      await notificationService.notifyUserClaimApproved(
                        userId: claimerId,
                        itemName: itemTitle,
                        claimId: claimId,
                        itemId: itemId?.toString(),
                      );
                    } catch (_) {}
                  }

                  // Record activity for claimer using ActivityService
                  if (claimerId != null) {
                    try {
                      final activityService = ActivityService();
                      await activityService.recordUserClaimApproved(
                        userId: claimerId,
                        itemName: itemTitle,
                        claimId: claimId,
                      );
                    } catch (_) {}
                  }

                  // Record activity for the reviewer (current user - the finder)
                  try {
                    final activityService = ActivityService();
                    await activityService.recordClaimReviewed(
                      itemName: itemTitle,
                      decision: 'Approved',
                      claimerName: claimerName,
                      claimId: claimId,
                    );
                  } catch (_) {}
                  
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Claim approved successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to approve claim: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Close loading dialog if it was shown
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }

              // Go back to claims page (StreamBuilder will automatically update in real-time)
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
