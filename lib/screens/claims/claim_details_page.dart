import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import '../../services/activity_service.dart';
import '../../services/game_service.dart'; // Import GameService

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
          _data['founderPhone'] =
              _data['founderPhone'] ?? d['founderPhone'] ?? d['finderPhone'];
          _data['founderEmail'] =
              _data['founderEmail'] ?? d['founderEmail'] ?? d['finderEmail'];
          _data['founderMessenger'] = _data['founderMessenger'] ??
              d['founderMessenger'] ??
              d['finderMessenger'];
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
          setState(() {
            _data['founderName'] = _data['founderName'] ??
                (d?['displayName'] ?? d?['name'] ?? d?['userName']);
            _data['founderPhone'] = _data['founderPhone'] ?? d?['phone'];
            _data['founderEmail'] = _data['founderEmail'] ?? d?['email'];
            _data['founderAffiliation'] =
                _data['founderAffiliation'] ?? d?['affiliation'];
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

    if (claimId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot locate claim document')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Successful Return'),
        content: const Text(
            'Mark this claim as successfully returned? This will complete the claim.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _processing = true;
    });

    final fs = FirebaseFirestore.instance;
    try {
      // Update claim
      await fs.collection('claims').doc(claimId).update({
        'status': 'completed',
        'completedBy': FirebaseAuth.instance.currentUser?.uid,
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

      setState(() {
        _data['status'] = 'completed';
        _processing = false;
      });

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Claim Approved'),
              content: const Text('The claim was successfully approved and marked as completed.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
    } catch (e) {
      setState(() {
        _processing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
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
            'Pick up from $pickupLoc. Contact ${_data['founderName'] ?? 'the finder'} at ${_data['founderPhone'] ?? _data['founderEmail'] ?? ''} to arrange time. Bring a valid ID for verification.';

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
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 24),
                            color: Colors.amber[700],
                            child: Column(
                              children: const [
                                Icon(Icons.hourglass_top,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 12),
                                Text('Under Review',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text(
                                    'The founder is reviewing your claim. Please wait for their response.',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isApproved)
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 36, horizontal: 24),
                            child: Column(
                              children: const [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 56),
                                SizedBox(height: 16),
                                Text('Claim Approved!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text(
                                    'Your claim has been approved. Contact the finder to arrange pickup.',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            width: double.infinity,
                            color: Colors.green[900],
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 24),
                            child: Column(
                              children: const [
                                Icon(Icons.verified,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 12),
                                Text('Claim Completed',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text(
                                    'This claim is completed. The item has been returned.',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else if (isRejected)
                          Container(
                            width: double.infinity,
                            color: Colors.red[600],
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 24),
                            child: Column(
                              children: const [
                                Icon(Icons.cancel,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 12),
                                Text('Claim Rejected',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text(
                                    'The founder has rejected this claim. You may contact them for more information.',
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Item Details Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Item Image
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 35,
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (_data['itemDescription'] ??
                                              _data['claimDescription'] ??
                                              _data['description'] ??
                                              _data['details']) ??
                                          'Found in the library, has a cracked screen protector',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Found timestamp
                                    if ((_data['foundAt'] ??
                                            _data['foundWhen'] ??
                                            _data['createdAt']) !=
                                        null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimestamp(_data['foundAt'] ??
                                                  _data['foundWhen'] ??
                                                  _data['createdAt']),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (_data['location'] ??
                                                  _data['pickupLocation'] ??
                                                  _data['foundAt']) ??
                                              'Found at Library',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
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
                        const SizedBox(height: 24),

                        // Contact Card: show the other party's profile depending on who is viewing
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2196F3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          // If the viewer is the founder, show claimer info; otherwise show founder info
                                          viewerIsFounder
                                              ? (_data['claimerName'] ??
                                                  'Claimer')
                                              : (_data['founderName'] ??
                                                  'Item Finder'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2196F3),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          viewerIsFounder
                                              ? 'Claimer — contact them to verify ownership'
                                              : 'Contact them to arrange pickup',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Details: show claimer contact when founder views, otherwise show founder contact
                              if (viewerIsFounder)
                                _buildContactRow(
                                  icon: Icons.person_outline,
                                  title: _data['claimerName'] ?? 'Claimer',
                                  subtitle: '',
                                  isVerified: false,
                                )
                              else
                                _buildContactRow(
                                  icon: Icons.person_outline,
                                  title: _data['founderName'] ?? 'Finder',
                                  subtitle: _data['founderAffiliation'] ?? '',
                                  isVerified: true,
                                ),
                              const SizedBox(height: 16),
                              if (viewerIsFounder)
                                _buildContactRow(
                                  icon: Icons.phone_outlined,
                                  title: _data['claimerProvidedContactValue'] ??
                                      _data['claimerPhone'] ??
                                      '',
                                  subtitle:
                                      _data['claimerProvidedContactMethod'] ??
                                          'Contact method',
                                  onCopy: () => _copyToClipboard(
                                      context,
                                      _data['claimerProvidedContactValue'] ??
                                          _data['claimerPhone'] ??
                                          ''),
                                )
                              else
                                _buildContactRow(
                                  icon: Icons.phone_outlined,
                                  title: _data['founderPhone'] ?? '',
                                  subtitle: 'Mobile number',
                                  onCopy: () => _copyToClipboard(
                                      context, _data['founderPhone'] ?? ''),
                                ),
                              const SizedBox(height: 16),
                              if (viewerIsFounder)
                                _buildContactRow(
                                  icon: Icons.email_outlined,
                                  title: _data['claimerEmail'] ?? '',
                                  subtitle: 'Email',
                                  onCopy: () => _copyToClipboard(
                                      context, _data['claimerEmail'] ?? ''),
                                )
                              else
                                _buildContactRow(
                                  icon: Icons.email_outlined,
                                  title: _data['founderEmail'] ?? '',
                                  subtitle: 'Email',
                                  onCopy: () => _copyToClipboard(
                                      context, _data['founderEmail'] ?? ''),
                                ),
                              if ((!viewerIsFounder &&
                                      (_data['founderMessenger'] ?? '')
                                          .toString()
                                          .isNotEmpty) ||
                                  (viewerIsFounder &&
                                      (_data['claimerMessenger'] ?? '')
                                          .toString()
                                          .isNotEmpty)) ...[
                                const SizedBox(height: 16),
                                _buildContactRow(
                                  icon: Icons.message_outlined,
                                  title: viewerIsFounder
                                      ? (_data['claimerMessenger'] ?? '')
                                      : (_data['founderMessenger'] ?? ''),
                                  subtitle: 'Messenger',
                                  onCopy: () => _copyToClipboard(
                                      context,
                                      viewerIsFounder
                                          ? (_data['claimerMessenger'] ?? '')
                                          : (_data['founderMessenger'] ?? '')),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Contact Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
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
                              const Text(
                                'Quick Contact',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchWhatsapp(
                                          _data['founderPhone'] ??
                                              _data['founderPhoneRaw']),
                                      icon: const Icon(Icons.chat,
                                          color: Colors.white, size: 20),
                                      label: Text(
                                        (_data['founderMessenger'] != null &&
                                                (_data['founderMessenger']
                                                        as String)
                                                    .isNotEmpty)
                                            ? 'Messenger'
                                            : 'WhatsApp',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (_data[
                                                        'founderMessenger'] !=
                                                    null &&
                                                (_data['founderMessenger']
                                                        as String)
                                                    .isNotEmpty)
                                            ? const Color(0xFF0084FF)
                                            : const Color(0xFF25D366),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _launchPhone(_data['founderPhone']),
                                      icon: const Icon(Icons.phone,
                                          color: Colors.black87, size: 20),
                                      label: const Text(
                                        'Call',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey[300]!, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pickup Information Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.location_on,
                                    color: Color(0xFF00897B),
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Pickup Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00897B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text(
                                  'Pickup Location: $pickupLoc',
                                  style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                  pickupInstr,
                                  style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  ),
                                  ),
                                  ],
                                  ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                  children: [
                                  Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                  _data['approvedAt'] != null
                                  ? 'Approved ${_formatTimestamp(_data['approvedAt'])}'
                                  : (_data['status'] == 'approved'
                                  ? 'Approved'
                                  : ''),
                                  style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  ),
                                  ),
                                  ],
                                  ),
                                  ],
                                  ),
                                  ),
                                  const SizedBox(height: 24),
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
                  if (isApproved && viewerIsClaimer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _processing
                            ? null
                            : () async {
                                final confirm = await _showConfirmationDialog(
                                  'Confirm Claim Item',
                                  'Are you sure you want to mark this claim as completed and claim the item? This action cannot be undone.',
                                );
                                if (!confirm) return;
                                await _markSuccessfulClaim();

                                // Award karma/points to founder - handled in _markSuccessfulClaim via GameService
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _processing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Item Claimed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending
                              ? Colors.amber[700]
                              : (isRejected
                                  ? Colors.red[600]
                                  : (isCompleted
                                      ? Colors.green[900]
                                      : Colors.grey[400])),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
}

Widget _buildContactRow({
required IconData icon,
required String title,
required String subtitle,
bool isVerified = false,
VoidCallback? onCopy,
}) {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
icon,
size: 20,
color: Colors.grey[700],
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w600,
color: Colors.black87,
),
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
const SizedBox(height: 2),
Text(
subtitle,
style: TextStyle(
fontSize: 12,
color: Colors.grey[600],
),
),
],
),
),
if (onCopy != null) ...[
const SizedBox(width: 8),
IconButton(
onPressed: onCopy,
icon: const Icon(Icons.copy, size: 20),
color: Colors.grey[600],
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
),
],
],
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