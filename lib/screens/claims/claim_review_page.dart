import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/claims_theme.dart';
import '../../services/notification_service.dart';
import '../../services/activity_service.dart';

class ClaimReviewPage extends StatefulWidget {
  final Map<String, dynamic> claimData;

  const ClaimReviewPage({super.key, required this.claimData});

  @override
  State<ClaimReviewPage> createState() => _ClaimReviewPageState();
}

class _ClaimReviewPageState extends State<ClaimReviewPage> {
  bool _isProcessing = false;

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

  void _viewImage(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _NetworkImageViewerDialog(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submittedStr = _formatSubmitted(widget.claimData['submittedDate']);
    
    // Support both old single image and new multiple images
    final List<String> proofImages = [];
    if (widget.claimData['proofImages'] is List) {
      proofImages.addAll((widget.claimData['proofImages'] as List).cast<String>());
    } else if (widget.claimData['proofImage'] != null) {
      proofImages.add(widget.claimData['proofImage'].toString());
    }
    final bool hasImages = proofImages.isNotEmpty;
    
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
                          widget.claimData['itemTitle'] ?? 'Student ID - Jane Smith',
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
                                '${widget.claimData['claimerName'] ?? 'J. Smith'}\nEmail: ${widget.claimData['claimerEmail'] ?? 'jane.smith@wvsu.edu.ph'}\n${widget.claimData['claimerContactMethod'] ?? 'Contact'}: ${widget.claimData['claimerContactValue'] ?? 'No contact provided'}',
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
                    widget.claimData['claimDescription'] ??  
                    'This is my student ID. I lost it yesterday near the gymnasium. My student number is 2021-12345 and I remember dropping it when I was getting my things from my bag after basketball practice.',
                    style: ClaimsTypography.body.copyWith(height: 1.5),
                  ),
                  if ((widget.claimData['additionalInfo'] ?? '').toString().trim().isNotEmpty) ...[
                      SizedBox(height: ClaimsSpacing.sm),
                      Text('Additional Details (provided by claimer):', style: ClaimsTypography.bodyBold.copyWith(color: Colors.orange)),
                      SizedBox(height: ClaimsSpacing.xxs),
                      Text(
                        widget.claimData['additionalInfo'],
                        style: ClaimsTypography.body,
                      ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: ClaimsSpacing.lg),
            
            // Image Proof Section (only if images exist)
            if (hasImages) ...[
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
                        Text(
                          'Image Proof (${proofImages.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photos provided by claimant - Tap to enlarge',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    proofImages.length == 1
                        ? _buildSingleImage(proofImages[0], 0)
                        : _buildImageGrid(proofImages),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Claimer Contact Information Card
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
                  
                  // Name Card
                  _buildCompactInfoCard(
                    context,
                    icon: Icons.person,
                    iconColor: ClaimsColors.info,
                    label: 'Claimer Name',
                    value: widget.claimData['claimerName'] ?? 'Unknown Claimer',
                  ),
                  
                  SizedBox(height: ClaimsSpacing.sm),
                  
                  // Render only the selected contact method
                  ...() {
                    final contactMethod = widget.claimData['claimerContactMethod'];
                    final contactValue = widget.claimData['claimerContactValue'];
                    
                    if (contactMethod == null || contactValue == null || contactValue.toString().isEmpty) {
                      return [
                        _buildCompactInfoCard(
                          context,
                          icon: Icons.contact_phone,
                          iconColor: Colors.grey,
                          label: 'Contact Information',
                          value: 'Not provided',
                          onTap: null,
                        ),
                      ];
                    }
                    
                    // Determine icon, color, and label based on contact method
                    IconData icon;
                    Color iconColor;
                    String label;
                    String? subtitle;
                    
                    if (contactMethod == 'Phone Call') {
                      icon = Icons.phone;
                      iconColor = const Color(0xFF4CAF50);
                      label = 'Phone Number';
                      subtitle = 'Tap to copy';
                    } else if (contactMethod == 'Facebook Messenger') {
                      icon = Icons.messenger;
                      iconColor = const Color(0xFF0084FF);
                      label = 'Facebook Messenger';
                      subtitle = 'Tap to copy profile link';
                    } else if (contactMethod == 'Email') {
                      icon = Icons.email;
                      iconColor = const Color(0xFFFF9800);
                      label = 'Email Address';
                      subtitle = 'Tap to copy';
                    } else {
                      icon = Icons.contact_phone;
                      iconColor = Colors.grey;
                      label = contactMethod.toString();
                      subtitle = 'Tap to copy';
                    }
                    
                    return [
                      _buildCompactInfoCard(
                        context,
                        icon: icon,
                        iconColor: iconColor,
                        label: label,
                        value: contactValue.toString(),
                        subtitle: subtitle,
                        onTap: () {
                          _copyToClipboard(context, contactValue.toString());
                        },
                      ),
                    ];
                  }(),
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
                    isLoading: _isProcessing,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClaimsButton(
                    label: 'Approve Claim',
                    icon: Icons.check_circle,
                    onPressed: () => _showApproveDialog(context),
                    type: ClaimsButtonType.approve,
                    isLoading: _isProcessing,
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
              // Show loading indicator in button only
              setState(() {
                _isProcessing = true;
              });
              
              // Attempt to mark claim as rejected in Firestore
              final claimId = widget.claimData['docId'] as String?;
              final claimerId = widget.claimData['claimerId'] as String?;
              final itemId = widget.claimData['itemId'];
              final itemTitle = widget.claimData['itemTitle'] ?? '';
              final claimerName = widget.claimData['claimerName'] ?? 'Unknown';
              
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
                  
                  // Update processing state
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                  
                  // Show success dialog
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.orange,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Claim Rejected',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The claim has been rejected. The claimant has been notified.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close success dialog
                              Navigator.pop(context); // Go back to claims page
                            },
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  print('Error rejecting claim: $e');
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reject claim: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return; // Don't navigate on error
                }
                } else {
                // No loading dialog to close
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
              // Show loading indicator in button only
              setState(() {
                _isProcessing = true;
              });
              
              // Approve claim: update claim doc and update lost_items to 'claimed'
              final claimId = widget.claimData['docId'] as String?;
              final claimerId = widget.claimData['claimerId'] as String?;
              final itemId = widget.claimData['itemId'];
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final itemTitle = widget.claimData['itemTitle'] ?? '';
              final claimerName = widget.claimData['claimerName'] ?? 'Unknown';

              if (claimId != null) {
                try {
                  final fs = FirebaseFirestore.instance;
                  
                  // First, check if item is already claimed
                  if (itemId != null) {
                    DocumentSnapshot? itemDoc;
                    try {
                      itemDoc = await fs.collection('lost_items').doc(itemId.toString()).get();
                    } catch (_) {
                      // fallback: find by itemId field
                      final q = await fs.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
                      if (q.docs.isNotEmpty) {
                        itemDoc = q.docs.first;
                      }
                    }
                    
                    if (itemDoc != null && itemDoc.exists) {
                      final itemStatus = (itemDoc.data() as Map<String, dynamic>?)?['status'];
                      if (itemStatus == 'claimed' || itemStatus == 'completed') {
                        // Item already claimed by someone else
                        if (mounted) {
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                        
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Row(
                                children: [
                                  Icon(Icons.info, color: Color(0xFFFF9800), size: 28),
                                  SizedBox(width: 12),
                                  Text('Already Claimed'),
                                ],
                              ),
                              content: const Text(
                                'This item has already been claimed by another user. You cannot approve additional claims for this item.',
                                style: TextStyle(fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Go back to claims page
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }
                    }
                  }
                  
                  // Check if there's already an approved claim for this item
                  final existingApprovedClaims = await fs.collection('claims')
                      .where('itemId', isEqualTo: itemId)
                      .where('status', isEqualTo: 'approved')
                      .limit(1)
                      .get();
                  
                  if (existingApprovedClaims.docs.isNotEmpty) {
                    // Another claim is already approved for this item
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                    
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.info, color: Color(0xFFFF9800), size: 28),
                              SizedBox(width: 12),
                              Text('Already Approved'),
                            ],
                          ),
                          content: const Text(
                            'Another claim for this item has already been approved. You cannot approve multiple claims for the same item.',
                            style: TextStyle(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Go back to claims page
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }
                  
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
                    
                    // Auto-reject all other pending claims for this item
                    try {
                      final otherPendingClaims = await fs.collection('claims')
                          .where('itemId', isEqualTo: itemId)
                          .where('status', isEqualTo: 'pending')
                          .get();
                      
                      for (var doc in otherPendingClaims.docs) {
                        if (doc.id != claimId) {
                          await doc.reference.update({
                            'status': 'rejected',
                            'rejectedBy': currentUid,
                            'rejectedAt': FieldValue.serverTimestamp(),
                            'rejectionReason': 'Item already claimed by another user',
                          });
                          
                          // Notify the rejected claimer
                          final rejectedClaimerId = doc.data()['claimerId'] as String?;
                          if (rejectedClaimerId != null) {
                            try {
                              final notificationService = NotificationService();
                              await notificationService.notifyUserClaimDenied(
                                userId: rejectedClaimerId,
                                itemName: itemTitle,
                                claimId: doc.id,
                                reason: 'Item already claimed by another user',
                              );
                            } catch (_) {}
                          }
                        }
                      }
                    } catch (_) {
                      // If auto-rejection fails, continue with the approval
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
                  
                  // Update processing state
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                  
                  // Show success dialog
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Claim Approved!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The claim has been approved. The claimant can now coordinate pickup with you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close success dialog
                              Navigator.pop(context); // Go back to claims page
                            },
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  print('Error approving claim: $e');
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to approve claim: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return; // Don't navigate on error
                }
              } else {
                // Close loading dialog if it was shown
                if (context.mounted) {
                  Navigator.pop(context);
                }
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

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCompactInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(ClaimsSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              SizedBox(width: ClaimsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ClaimsTypography.caption.copyWith(
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: ClaimsSpacing.xxs),
                    Text(
                      value,
                      style: ClaimsTypography.bodyBold.copyWith(
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      SizedBox(height: ClaimsSpacing.xxs),
                      Text(
                        subtitle,
                        style: ClaimsTypography.caption.copyWith(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: ClaimsSpacing.xs),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.content_copy,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl, int index) {
    return InkWell(
      onTap: () => _viewImage([imageUrl], index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
          color: Colors.grey[200],
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to enlarge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _viewImage(imageUrls, index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Failed',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${index + 1}/${imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Network Image Viewer Dialog Widget
class _NetworkImageViewerDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _NetworkImageViewerDialog({
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<_NetworkImageViewerDialog> createState() => _NetworkImageViewerDialogState();
}

class _NetworkImageViewerDialogState extends State<_NetworkImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Image counter
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation arrows (if more than 1 image)
          if (widget.imageUrls.length > 1) ...[
            // Previous button
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            // Next button
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
