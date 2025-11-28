import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/claims_theme.dart';
import '../../services/notification_service.dart';
import '../../services/activity_service.dart';
import '../../services/game_service.dart';

class ClaimDetailsPage extends StatefulWidget {
  final Map<String, dynamic> claimData;

  const ClaimDetailsPage({super.key, required this.claimData});

  @override
  State<ClaimDetailsPage> createState() => _ClaimDetailsPageState();
}

class _ClaimDetailsPageState extends State<ClaimDetailsPage> {
      Future<void> _rejectClaim() async {
        final claimId = _data['docId'] as String?;
        if (claimId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot locate claim document')));
          return;
        }
        setState(() {
          _processing = true;
        });
        try {
          await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
            'status': 'rejected',
            'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
            'rejectedAt': FieldValue.serverTimestamp(),
          });
          if (!mounted) return;
          setState(() {
            _data['status'] = 'rejected';
            _processing = false;
          });
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Claim Rejected'),
                content: const Text('The claim was successfully rejected.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _processing = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    Future<bool> _showConfirmationDialog(String title, String content) async {
      return (await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm')),
              ],
            ),
          )) ??
          false;
    }
  late Map<String, dynamic> _data;
  bool _processing = false;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _claimStream;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.claimData);
    _claimStream = FirebaseFirestore.instance
        .collection('claims')
        .doc(_data['docId'])
        .snapshots();
    _loadFounderIfNeeded();
    _resolveLostItemIfNeeded();
  }

  Future<void> _resolveLostItemIfNeeded() async {
    try {
      // If claim already has key fields, skip
      final hasTitle = (_data['itemTitle'] ??
              _data['title'] ??
              _data['itemName'] ??
              _data['name']) !=
          null;
      final hasFoundAt = _data['foundAt'] != null || _data['foundWhen'] != null;
      final hasLocation = _data['location'] != null ||
          _data['pickupLocation'] != null ||
          _data['foundAtLocation'] != null;

      if (hasTitle && hasFoundAt && hasLocation) return;

      final fs = FirebaseFirestore.instance;
      final itemIdRaw =
          _data['itemId'] ?? _data['lostItemId'] ?? _data['lost_item_id'];
      String? docId;
      if (itemIdRaw != null) docId = itemIdRaw.toString();

      DocumentSnapshot<Map<String, dynamic>>? itemDoc;
      if (docId != null) {
        try {
          final doc = await fs.collection('lost_items').doc(docId).get();
          if (doc.exists) itemDoc = doc;
        } catch (_) {}
      }

      if (itemDoc == null && itemIdRaw != null) {
        try {
          final q = await fs
              .collection('lost_items')
              .where('itemId', isEqualTo: itemIdRaw)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) itemDoc = q.docs.first;
        } catch (_) {}
      }

      if (itemDoc != null && itemDoc.exists) {
        final d = itemDoc.data() ?? {};
        if (!mounted) return;
        setState(() {
          // copy fields if missing
          _data['itemTitle'] = _data['itemTitle'] ??
              d['title'] ??
              d['name'] ??
              d['itemName'];
          _data['itemDescription'] = _data['itemDescription'] ??
              d['description'] ??
              d['details'] ??
              d['foundDescription'];
          _data['foundAt'] =
              _data['foundAt'] ?? d['foundAt'] ?? d['createdAt'] ?? d['timestamp'];
          _data['location'] = _data['location'] ??
              d['location'] ??
              d['pickupLocation'] ??
              d['foundAtLocation'];
          _data['pickupInstructions'] = _data['pickupInstructions'] ??
              d['pickupInstructions'] ??
              d['pickupInfo'];

          // if founder info missing, try copying from lost_item
          _data['founderName'] = _data['founderName'] ??
              d['founderName'] ??
              d['founderDisplayName'];
          _data['founderContactMethod'] = _data['founderContactMethod'] ?? d['founderContactMethod'];
          _data['founderContactValue'] = _data['founderContactValue'] ?? d['founderContactValue'];
          
          // Copy imageUrl from lost_item's images array if not present
          if (_data['imageUrl'] == null) {
            final images = d['images'];
            if (images is List && images.isNotEmpty && images[0] is String) {
              _data['imageUrl'] = images[0];
            }
          }
        });
      }
    } catch (_) {}
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else {
        return '';
      }

      final date =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date • $time';
    } catch (_) {
      return '';
    }
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _launchWhatsapp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.trim().isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _launchMessenger(String? handle) async {
    if (handle == null || handle.trim().isEmpty) return;
    // Try common patterns: if it looks like @username, open messenger profile link
    String url = handle;
    if (handle.startsWith('@')) {
      url = 'https://m.me/${handle.substring(1)}';
    } else if (!handle.startsWith('http')) {
      // fallback try messenger via m.me
      url = 'https://m.me/$handle';
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _loadFounderIfNeeded() async {
    try {
      final founderId = (_data['founderId'] ?? _data['posterId'])?.toString();
      if (((_data['founderName'] == null ||
              (_data['founderName'] as String).isEmpty)) &&
          founderId != null &&
          founderId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(founderId)
            .get();
        if (doc.exists) {
          final d = doc.data();
          if (!mounted) return;
          setState(() {
            _data['founderName'] = _data['founderName'] ??
                (d?['displayName'] ?? d?['name'] ?? d?['userName']);
            _data['founderAffiliation'] =
                _data['founderAffiliation'] ?? d?['affiliation'];
            // Only load contact if not already set from claim data
            if (_data['founderContactMethod'] == null && d?['phone'] != null) {
              _data['founderContactMethod'] = 'Phone Call';
              _data['founderContactValue'] = d?['phone'];
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _markSuccessfulClaim() async {
    final claimId = _data['docId'] as String?;
    final itemId = _data['itemId'];
    final claimerId = _data['claimerId'] as String?;
    final founderId = _data['founderId'] ?? _data['posterId'];
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    // Validate authentication
    if (currentUser == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to confirm return'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate claim ID
    if (claimId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot locate claim document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate user authorization (must be founder to confirm return)
    final isFounder = founderId != null && currentUserId == founderId.toString();
    if (!isFounder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the item finder can confirm the return'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate claim status (must be approved to confirm return)
    final currentStatus = (_data['status'] ?? '').toString().toLowerCase();
    if (currentStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot confirm return. Claim status is: $currentStatus'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Successful Return'),
        content: const Text(
            'Mark this claim as successfully returned? This will complete the claim and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Confirm Return')),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      _processing = true;
    });

    final fs = FirebaseFirestore.instance;
    try {
      // Update claim status to completed
      await fs.collection('claims').doc(claimId).update({
        'status': 'completed',
        'completedBy': currentUserId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update lost_items: try by doc id first, then fallback to itemId field
      if (itemId != null) {
        try {
          await fs.collection('lost_items').doc(itemId.toString()).update({
            'status': 'returned',
            'returnedTo': claimerId,
            'returnedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          try {
            final q = await fs
                .collection('lost_items')
                .where('itemId', isEqualTo: itemId)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              await q.docs.first.reference.update({
                'status': 'returned',
                'returnedTo': claimerId,
                'returnedAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (_) {}
        }
      }

      // Get item details for notifications
      final itemTitle = _data['itemTitle'] ?? _data['title'] ?? _data['itemName'] ?? _data['name'] ?? 'Item';
      final founderId = _data['foundBy'] ?? _data['foundById'];

      // Send notifications to both users
      final notificationService = NotificationService();
      final activityService = ActivityService();

      // Reward points for successful return
      const karmaReward = 20; // Updated to match Verified Claim Fulfillment
      const pointsReward = 25; // Updated to match Verified Claim Fulfillment

      // Notify claimer (owner) about successful return
      if (claimerId != null) {
        await notificationService.notifyUserReturnCompleted(
          userId: claimerId,
          itemName: itemTitle,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
        await activityService.recordReturnCompleted(
          itemName: itemTitle,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
      }

      // Notify founder about successful return completion
      if (founderId != null) {
        await notificationService.notifyUserReturnCompleted(
          userId: founderId,
          itemName: itemTitle,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
        
        // Use GameService for points/karma update and activity log
        final gameService = GameService();
        await gameService.rewardUserVerifiedClaimFulfillment(founderId, itemTitle);
      }

      if (!mounted) return;
      setState(() {
        _data['status'] = 'completed';
        _processing = false;
      });

      // Navigate back to Claims Page
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return confirmed successfully! Claim completed.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
      });

      String errorMessage = 'Failed to confirm return';
      
      // Handle specific error codes
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. You may not have access to complete this claim.';
        
        // Show dialog with retry option
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Permission Denied'),
              ],
            ),
            content: const Text(
              'You do not have permission to complete this claim. Please ensure you are the item finder and the claim is in "Approved" status.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Reload claim data
                  _resolveLostItemIfNeeded();
                  _loadFounderIfNeeded();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (e.code == 'not-found') {
        errorMessage = 'Claim not found. It may have been deleted.';
      } else if (e.code == 'unavailable') {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to confirm return: ${e.message ?? e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: e.code != 'permission-denied' ? SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _markSuccessfulClaim();
            },
          ) : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _markSuccessfulClaim();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _claimStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _data = {..._data, ...?snapshot.data!.data()};
        }

        final statusRaw = (_data['status'] ?? '').toString().toLowerCase();
        final isPending = statusRaw == 'pending';
        final isApproved = statusRaw == 'approved';
        final isRejected = statusRaw == 'rejected';
        final isCompleted = statusRaw == 'completed';

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final founderId = (_data['founderId'] ?? _data['posterId'])?.toString();
        final claimerId = (_data['claimerId'] ?? _data['claimer'])?.toString();

        final viewerIsFounder = currentUserId != null &&
            founderId != null &&
            currentUserId == founderId;
        final viewerIsClaimer = currentUserId != null &&
            claimerId != null &&
            currentUserId == claimerId;

        // Resolve pickup display values
        final pickupLoc = _data['pickupLocation'] ??
            _data['location'] ??
            (_data['founderName'] != null
                ? 'With ${_data['founderName']}'
                : 'Location unknown');
        final pickupInstr = _data['pickupInstructions'] ??
            'Pick up from $pickupLoc. Contact ${_data['founderName'] ?? 'the finder'} via ${_data['founderContactMethod'] ?? 'their contact method'} to arrange time. Bring a valid ID for verification.';

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        // Status Header
                        if (isPending)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: ClaimsSpacing.xl, horizontal: ClaimsSpacing.xl),
                            color: ClaimsColors.pending,
                            child: Column(
                              children: [
                                const Icon(Icons.hourglass_top,
                                    color: Colors.white, size: 48),
                                SizedBox(height: ClaimsSpacing.sm),
                                Text('Under Review',
                                    style: ClaimsTypography.title.copyWith(
                                        color: Colors.white,
                                        fontSize: 22)),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                    'The founder is reviewing your claim. Please wait for their response.',
                                    style: ClaimsTypography.body.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isApproved)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: ClaimsColors.approved,
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: ClaimsSpacing.xl, horizontal: ClaimsSpacing.xl),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 56),
                                SizedBox(height: ClaimsSpacing.md),
                                Text('Claim Approved!',
                                    style: ClaimsTypography.title.copyWith(
                                        color: Colors.white,
                                        fontSize: 26)),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                    'Your claim has been approved. Contact the finder to arrange pickup.',
                                    style: ClaimsTypography.body.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            width: double.infinity,
                            color: ClaimsColors.info,
                            padding: EdgeInsets.symmetric(
                                vertical: ClaimsSpacing.xl, horizontal: ClaimsSpacing.xl),
                            child: Column(
                              children: [
                                const Icon(Icons.verified,
                                    color: Colors.white, size: 48),
                                SizedBox(height: ClaimsSpacing.sm),
                                Text('Claim Completed',
                                    style: ClaimsTypography.title.copyWith(
                                        color: Colors.white,
                                        fontSize: 22)),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                    'This claim is completed. The item has been returned.',
                                    style: ClaimsTypography.body.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isRejected)
                          Container(
                            width: double.infinity,
                            color: ClaimsColors.rejected,
                            padding: EdgeInsets.symmetric(
                                vertical: ClaimsSpacing.xl, horizontal: ClaimsSpacing.xl),
                            child: Column(
                              children: [
                                const Icon(Icons.cancel,
                                    color: Colors.white, size: 48),
                                SizedBox(height: ClaimsSpacing.sm),
                                Text('Claim Rejected',
                                    style: ClaimsTypography.title.copyWith(
                                        color: Colors.white,
                                        fontSize: 22)),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                    'The founder has rejected this claim. You may contact them for more information.',
                                    style: ClaimsTypography.body.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        SizedBox(height: ClaimsSpacing.xl),

                        // Item Details Card
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                          padding: EdgeInsets.all(ClaimsSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: ClaimsSpacing.sm),
                                  Text(
                                    'Item Posted',
                                    style: ClaimsTypography.subtitle.copyWith(
                                      color: Colors.black87,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: ClaimsSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item Image
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: (_data['imageUrl'] != null && _data['imageUrl'].toString().isNotEmpty)
                                          ? Image.network(
                                              _data['imageUrl'].toString(),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[400],
                                                size: 32,
                                              ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                            )
                                          : Icon(
                                              Icons.image,
                                              color: Colors.grey[400],
                                              size: 32,
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: ClaimsSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (_data['itemTitle'] ??
                                                  _data['title'] ??
                                                  _data['itemName'] ??
                                                  _data['name']) ??
                                              'Black iPhone 13',
                                          style: ClaimsTypography.subtitle.copyWith(
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: ClaimsSpacing.xxs),
                                        Text(
                                          (_data['itemDescription'] ??
                                                  _data['claimDescription'] ??
                                                  _data['description'] ??
                                                  _data['details']) ??
                                              'Found in the library, has a cracked screen protector',
                                          style: ClaimsTypography.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: ClaimsSpacing.sm),
                              Container(
                                padding: EdgeInsets.all(ClaimsSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Found timestamp
                                    if ((_data['foundAt'] ??
                                            _data['foundWhen'] ??
                                            _data['createdAt']) !=
                                        null) ...[
                                      ClaimsWidgets.infoRow(
                                        icon: Icons.calendar_today,
                                        text: _formatTimestamp(_data['foundAt'] ??
                                            _data['foundWhen'] ??
                                            _data['createdAt']),
                                        iconColor: AppColors.primary,
                                      ),
                                      SizedBox(height: ClaimsSpacing.xs),
                                    ],
                                    ClaimsWidgets.infoRow(
                                      icon: Icons.location_on,
                                      text: (_data['location'] ??
                                              _data['pickupLocation'] ??
                                              _data['foundAt']) ??
                                          'Found at Library',
                                      iconColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ClaimsSpacing.xl),

                        // Claim Description Card
                        if ((_data['claimDescription'] ?? '').toString().trim().isNotEmpty) ...[
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                            padding: EdgeInsets.all(ClaimsSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ClaimsColors.info.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        color: ClaimsColors.info,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: ClaimsSpacing.sm),
                                    Text(
                                      'Claim Description',
                                      style: ClaimsTypography.subtitle.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ClaimsSpacing.md),
                                Text(
                                  _data['claimDescription'].toString(),
                                  style: ClaimsTypography.body.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                                if ((_data['additionalInfo'] ?? '').toString().trim().isNotEmpty) ...[
                                  SizedBox(height: ClaimsSpacing.md),
                                  Text(
                                    'Additional Information:',
                                    style: ClaimsTypography.bodyBold.copyWith(
                                      color: Colors.orange,
                                    ),
                                  ),
                                  SizedBox(height: ClaimsSpacing.xs),
                                  Text(
                                    _data['additionalInfo'].toString(),
                                    style: ClaimsTypography.body.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: ClaimsSpacing.xl),
                        ],

                        // Proof Images Card (only if images exist)
                        ...() {
                          final List<String> proofImages = [];
                          if (_data['proofImages'] is List) {
                            proofImages.addAll((_data['proofImages'] as List).cast<String>());
                          } else if (_data['proofImage'] != null && _data['proofImage'].toString().isNotEmpty) {
                            proofImages.add(_data['proofImage'].toString());
                          }
                          
                          if (proofImages.isEmpty) return <Widget>[];
                          
                          return <Widget>[
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                            padding: EdgeInsets.all(ClaimsSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.photo_library_outlined,
                                        color: const Color(0xFF9C27B0),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: ClaimsSpacing.sm),
                                    Text(
                                      'Proof Images (${proofImages.length})',
                                      style: ClaimsTypography.subtitle.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                  'Photos provided by claimer - Tap to enlarge',
                                  style: ClaimsTypography.caption,
                                ),
                                SizedBox(height: ClaimsSpacing.md),
                                proofImages.length == 1
                                    ? _buildSingleProofImage(proofImages[0], 0, proofImages)
                                    : _buildProofImageGrid(proofImages),
                              ],
                            ),
                          ),
                          SizedBox(height: ClaimsSpacing.xl),
                          ];
                        }(),

                        // Return Images Card (only for completed claims with return images)
                        if (isCompleted) ...() {
                          final List<String> returnImages = [];
                          if (_data['returnImages'] is List) {
                            returnImages.addAll((_data['returnImages'] as List).cast<String>());
                          } else if (_data['returnImage'] != null && _data['returnImage'].toString().isNotEmpty) {
                            returnImages.add(_data['returnImage'].toString());
                          }
                          
                          if (returnImages.isEmpty) return <Widget>[];
                          
                          return <Widget>[
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                            padding: EdgeInsets.all(ClaimsSpacing.lg),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: ClaimsSpacing.sm),
                                    Text(
                                      'Return Photos (${returnImages.length})',
                                      style: ClaimsTypography.subtitle.copyWith(
                                        fontSize: 17,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ClaimsSpacing.xs),
                                Text(
                                  'Photos from successful return - Tap to enlarge',
                                  style: ClaimsTypography.caption.copyWith(
                                    color: const Color(0xFF558B2F),
                                  ),
                                ),
                                SizedBox(height: ClaimsSpacing.md),
                                returnImages.length == 1
                                    ? _buildSingleProofImage(returnImages[0], 0, returnImages)
                                    : _buildProofImageGrid(returnImages),
                              ],
                            ),
                          ),
                          SizedBox(height: ClaimsSpacing.xl),
                          ];
                        }(),

                        // Contact Card: show the other party's profile depending on who is viewing
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Padding(
                                padding: EdgeInsets.only(bottom: ClaimsSpacing.sm),
                                child: Text(
                                  'Contact Information',
                                  style: ClaimsTypography.title.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              
                              // Name Card with Verified Badge
                              _buildCompactInfoCard(
                                icon: Icons.person,
                                iconColor: ClaimsColors.info,
                                label: viewerIsFounder ? 'Claimer' : 'Item Finder',
                                value: viewerIsFounder
                                    ? (_data['claimerName'] ?? 'Unknown')
                                    : (_data['founderName'] ?? 'Unknown'),
                                isVerified: !viewerIsFounder,
                                affiliation: viewerIsFounder ? null : (_data['founderAffiliation'] ?? ''),
                              ),
                              
                              SizedBox(height: ClaimsSpacing.sm),
                              
                              // Render only the selected contact method
                              ...() {
                                final contactMethod = viewerIsFounder
                                    ? _data['claimerContactMethod']
                                    : _data['founderContactMethod'];
                                final contactValue = viewerIsFounder
                                    ? _data['claimerContactValue']
                                    : _data['founderContactValue'];
                                
                                if (contactMethod == null || contactValue == null || contactValue.toString().isEmpty) {
                                  return [
                                    _buildCompactInfoCard(
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
                        SizedBox(height: ClaimsSpacing.xl),

                        // Pickup Information Card
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: ClaimsSpacing.xl),
                          padding: EdgeInsets.all(ClaimsSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: ClaimsColors.approved.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: ClaimsColors.approved,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: ClaimsSpacing.sm),
                                  Text('Pickup Information', style: ClaimsTypography.title),
                                ],
                              ),
                              SizedBox(height: ClaimsSpacing.md),
                              ClaimsWidgets.detailRow(label: 'Location', value: pickupLoc),
                              SizedBox(height: ClaimsSpacing.sm),
                              ClaimsWidgets.detailRow(label: 'Instructions', value: pickupInstr),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: ClaimsSpacing.xl),
                    // Meeting Guidelines Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meeting Guidelines',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF57C00),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGuideline(
                              'Meet in a public place (Library, CSC Office, Cafeteria)'),
                          const SizedBox(height: 12),
                          _buildGuideline(
                              'Bring a valid student ID for verification'),
                          const SizedBox(height: 12),
                          _buildGuideline(
                              'Be prepared to provide additional proof of ownership if requested'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Removed Item Claimed button - claimers just see status
                  // Show status container for all states
                  if (true) // Always show status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isPending
                            ? ClaimsColors.pending
                            : (isRejected
                                ? ClaimsColors.rejected
                                : (isCompleted
                                    ? ClaimsColors.info
                                    : Colors.grey[400])),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        isPending
                            ? 'Under Review'
                            : (isRejected
                                ? 'Claim Rejected'
                                : (isCompleted
                                    ? 'Claim Completed'
                                    : (isApproved
                                        ? 'Awaiting Claimer'
                                        : 'Not available'))),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Add reject button for founder when claim is pending
                  if (isPending && viewerIsFounder)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _processing
                            ? null
                            : () async {
                                final confirm = await _showConfirmationDialog(
                                  'Reject Claim',
                                  'Are you sure you want to reject this claim? This action cannot be undone.',
                                );
                                if (!confirm) return;
                                await _rejectClaim();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.red[600]!, width: 2),
                        ),
                        child: _processing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.red, strokeWidth: 2))
                            : const Text(
                                'Reject Claim',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Back to Claims',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Widget _buildContactRow({
required IconData icon,
required String title,
required String subtitle,
bool isVerified = false,
VoidCallback? onCopy,
}) {
return Container(
padding: EdgeInsets.all(ClaimsSpacing.sm),
decoration: BoxDecoration(
color: Colors.grey[50],
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: Colors.grey[200]!,
width: 1,
),
),
child: Row(
children: [
Container(
padding: EdgeInsets.all(8),
decoration: BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
border: Border.all(
color: ClaimsColors.info.withValues(alpha: 0.2),
width: 1,
),
),
child: Icon(
icon,
size: 18,
color: ClaimsColors.info,
),
),
SizedBox(width: ClaimsSpacing.sm),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
title,
style: ClaimsTypography.bodyBold.copyWith(
fontSize: 15,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
if (isVerified)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: const Color(0xFF4CAF50).withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: const [
Icon(
Icons.verified,
size: 14,
color: Color(0xFF4CAF50),
),
SizedBox(width: 4),
Text(
'Verified',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.bold,
color: Color(0xFF4CAF50),
),
),
],
),
),
],
),
if (subtitle.isNotEmpty) ...[
SizedBox(height: ClaimsSpacing.xxs),
Text(
subtitle,
style: ClaimsTypography.caption,
),
],
],
),
),
if (onCopy != null) ...[
SizedBox(width: ClaimsSpacing.xs),
Material(
color: Colors.transparent,
child: InkWell(
onTap: onCopy,
borderRadius: BorderRadius.circular(8),
child: Container(
padding: EdgeInsets.all(8),
decoration: BoxDecoration(
color: ClaimsColors.info.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(8),
),
child: Icon(
Icons.content_copy,
size: 18,
color: ClaimsColors.info,
),
),
),
),
],
],
),
);
}

Widget _buildCompactInfoCard({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
  bool isVerified = false,
  String? affiliation,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: ClaimsTypography.bodyBold.copyWith(
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Container(
                          margin: EdgeInsets.only(left: ClaimsSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ClaimsColors.approved.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: ClaimsColors.approved,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ClaimsColors.approved,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (affiliation != null && affiliation.isNotEmpty) ...[
                    SizedBox(height: ClaimsSpacing.xxs),
                    Text(
                      affiliation,
                      style: ClaimsTypography.caption.copyWith(
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
  Widget _buildGuideline(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFF57C00),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _viewProofImage(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _NetworkImageViewerDialog(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  Widget _buildSingleProofImage(String imageUrl, int index, List<String> allImages) {
    return InkWell(
      onTap: () => _viewProofImage(allImages, index),
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

  Widget _buildProofImageGrid(List<String> imageUrls) {
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
          onTap: () => _viewProofImage(imageUrls, index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.5),
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

// Network Image Viewer Dialog for ClaimDetailsPage
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