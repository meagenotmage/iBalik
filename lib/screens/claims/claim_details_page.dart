import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimDetailsPage extends StatefulWidget {
  final Map<String, dynamic> claimData;

  const ClaimDetailsPage({super.key, required this.claimData});

  @override
  State<ClaimDetailsPage> createState() => _ClaimDetailsPageState();
}

class _ClaimDetailsPageState extends State<ClaimDetailsPage> {
  late Map<String, dynamic> _data;
  bool _processing = false;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _claimStream;

  @override
  void initState() {
    super.initState();
    // Initialize data from widget
    _data = Map.from(widget.claimData);

    // Listen to real-time updates for status changes
    _claimStream = FirebaseFirestore.instance
        .collection('claims')
        .doc(_data['docId'])
        .snapshots();

    // Load additional data
    _loadFounderIfNeeded();
    _resolveLostItemIfNeeded();
  }

  // --- ACTIONS ---

  Future<void> _rejectClaim() async {
    final claimId = _data['docId'] as String?;
    if (claimId == null) return;

    setState(() => _processing = true);

    try {
      await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
        'status': 'rejected',
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _markSuccessfulClaim() async {
    final claimId = _data['docId'] as String?;
    final itemId = _data['itemId'];
    final claimerId = _data['claimerId'] as String?;

    if (claimId == null) return;

    setState(() => _processing = true);

    final fs = FirebaseFirestore.instance;
    try {
      // 1. Update Claim Status
      await fs.collection('claims').doc(claimId).update({
        'status': 'completed',
        'completedBy': FirebaseAuth.instance.currentUser?.uid,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Lost Item Status
      if (itemId != null) {
        // Try direct doc ID first
        try {
          await fs.collection('lost_items').doc(itemId.toString()).update({
            'status': 'returned',
            'returnedTo': claimerId,
            'returnedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          // Fallback: Query by field
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
        }
      }
      
      // 3. Award Karma (Optional logic)
      final founderId = (_data['founderId'] ?? _data['posterId'])?.toString();
      if (founderId != null) {
          try {
            final userRef = fs.collection('users').doc(founderId);
            await fs.runTransaction((tx) async {
              final snap = await tx.get(userRef);
              if (snap.exists) {
                final data = snap.data() ?? {};
                final int oldKarma = (data['karma'] ?? 0) as int;
                final int oldPoints = (data['points'] ?? 0) as int;
                tx.update(userRef, {
                  'karma': oldKarma + 1,
                  'points': oldPoints + 10,
                });
              }
            });
          } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _data['status'] = 'completed';
          _processing = false;
        });

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Claim Completed'),
            content: const Text('The item has been marked as successfully returned.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // --- DATA LOADING HELPERS ---

  Future<void> _resolveLostItemIfNeeded() async {
    // This fetches the original item details (Image, Title) to display at the top
    try {
      final fs = FirebaseFirestore.instance;
      final itemIdRaw = _data['itemId'] ?? _data['lostItemId'];
      
      if (itemIdRaw == null) return;

      DocumentSnapshot<Map<String, dynamic>>? itemDoc;
      
      // Try get by ID
      try {
        final doc = await fs.collection('lost_items').doc(itemIdRaw.toString()).get();
        if (doc.exists) itemDoc = doc;
      } catch (_) {}

      // Try query by field
      if (itemDoc == null) {
        final q = await fs.collection('lost_items').where('itemId', isEqualTo: itemIdRaw).limit(1).get();
        if (q.docs.isNotEmpty) itemDoc = q.docs.first;
      }

      if (itemDoc != null && itemDoc.exists) {
        final d = itemDoc.data()!;
        if (mounted) {
          setState(() {
            // Only overwrite ITEM details, do not overwrite CLAIM details
            _data['itemTitle'] = d['title'] ?? d['name'] ?? d['itemName'];
            _data['itemDescription'] = d['description'] ?? d['details']; // The item's physical description
            _data['itemImageUrl'] = d['imageUrl'] ?? d['imageURL'];
            
            // Founder info backup
            _data['founderName'] = _data['founderName'] ?? d['founderName'] ?? d['finderName'];
            _data['founderPhone'] = _data['founderPhone'] ?? d['founderPhone'] ?? d['finderPhone'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFounderIfNeeded() async {
    // Fetch Founder profile if missing
    try {
      final founderId = (_data['founderId'] ?? _data['posterId'])?.toString();
      if (founderId != null && (_data['founderName'] == null || _data['founderName'].isEmpty)) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(founderId).get();
        if (doc.exists) {
          final d = doc.data();
          if (mounted) {
            setState(() {
              _data['founderName'] = d?['displayName'] ?? d?['name'];
              _data['founderPhone'] = _data['founderPhone'] ?? d?['phone'];
              _data['founderEmail'] = _data['founderEmail'] ?? d?['email'];
            });
          }
        }
      }
    } catch (_) {}
  }

  // --- UTILS ---

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
            ],
          ),
        )) ?? false;
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    try { await launchUrl(Uri(scheme: 'tel', path: phone)); } catch (_) {}
  }
  
  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    try { await launchUrl(Uri(scheme: 'mailto', path: email)); } catch (_) {}
  }

  Future<void> _launchWhatsapp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    try { await launchUrl(Uri.parse('https://wa.me/$normalized'), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final DateTime dt = (ts is Timestamp) ? ts.toDate() : (ts is DateTime ? ts : DateTime.now());
      return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _claimStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          // Update local data with real-time data, but prefer widget data for fields not in snapshot
          final newData = snapshot.data!.data()!;
          _data = {..._data, ...newData};
        }

        final statusRaw = (_data['status'] ?? 'pending').toString().toLowerCase();
        final isPending = statusRaw == 'pending';
        final isApproved = statusRaw == 'approved';
        final isRejected = statusRaw == 'rejected';
        final isCompleted = statusRaw == 'completed';

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final founderId = (_data['founderId'] ?? _data['posterId'])?.toString();
        final claimerId = (_data['claimerId'] ?? _data['claimer'])?.toString();

        // LOGIC: Who is viewing this page?
        final viewerIsFounder = currentUserId != null && founderId != null && currentUserId == founderId;
        final viewerIsClaimer = currentUserId != null && claimerId != null && currentUserId == claimerId;

        // Pickup Display
        final pickupLoc = _data['pickupLocation'] ?? _data['location'] ?? 'Location to be arranged';

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Claim Details'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 1. Status Banner
                        _buildStatusBanner(isPending, isApproved, isCompleted, isRejected),

                        const SizedBox(height: 20),

                        // 2. Item Details (Small summary of what is being claimed)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  image: _data['itemImageUrl'] != null 
                                      ? DecorationImage(image: NetworkImage(_data['itemImageUrl']), fit: BoxFit.cover)
                                      : null
                                ),
                                child: _data['itemImageUrl'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Claim for:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text(
                                      _data['itemTitle'] ?? _data['itemName'] ?? 'Unknown Item',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _data['itemDescription'] ?? 'No item details', // This is the ITEM description
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3. PROOF / REASON SECTION (Seeker's Info)
                        // This shows the text the claimer wrote to prove ownership
                        if (viewerIsFounder || viewerIsClaimer)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.help_outline, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text("Reason for Claim / Proof", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  _data['claimDescription'] ?? _data['description'] ?? _data['proof'] ?? 'No specific proof provided.',
                                  style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                                ),
                                if ((_data['additionalInfo'] != null) && (_data['additionalInfo'].toString().trim().isNotEmpty)) ...[
                                  const SizedBox(height: 12),
                                  const Text('Additional Details (provided by claimer):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange)),
                                  const SizedBox(height: 4),
                                  Text(_data['additionalInfo'], style: TextStyle(fontSize: 14, color: Colors.black87)),
                                ],
                                if (_data['proofImage'] != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(_data['proofImage'], height: 150, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                ]
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // 4. CONTACT INFORMATION CARD
                        // Dynamic: If Founder -> Show Claimer info. If Claimer -> Show Founder info.
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                viewerIsFounder ? "Claimer Information" : "Finder Information",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                viewerIsFounder 
                                  ? "This person is claiming the item." 
                                  : "This person found your item.",
                                style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                              ),
                              const SizedBox(height: 20),
                              // NAME
                              _buildContactRow(
                                icon: Icons.person,
                                title: viewerIsFounder
                                  ? (_data['claimerName'] ?? 'Unknown Claimer')
                                  : (_data['founderName'] ?? 'Unknown Finder'),
                                subtitle: viewerIsFounder ? "Claimer Name" : "Finder Name",
                              ),
                              const SizedBox(height: 12),
                              // PHONE / CONTACT
                              _buildContactRow(
                                icon: Icons.phone,
                                title: viewerIsFounder
                                  ? (_data['claimerProvidedContactValue'] ?? _data['claimerPhone'] ?? 'Not provided')
                                  : (_data['founderPhone'] ?? 'Not provided'),
                                subtitle: viewerIsFounder
                                  ? "Contact (${_data['claimerProvidedContactMethod'] ?? 'Phone'})"
                                  : "Mobile Number",
                                onCopy: () => _copyToClipboard(context, viewerIsFounder
                                  ? (_data['claimerProvidedContactValue'] ?? _data['claimerPhone'] ?? '')
                                  : (_data['founderPhone'] ?? '')),
                              ),
                              const SizedBox(height: 12),
                              // EMAIL
                              _buildContactRow(
                                icon: Icons.email,
                                title: viewerIsFounder
                                  ? (_data['claimerEmail'] ?? 'Not provided')
                                  : (_data['founderEmail'] ?? 'Not provided'),
                                subtitle: "Email Address",
                                onCopy: () => _copyToClipboard(context, viewerIsFounder
                                  ? (_data['claimerEmail']??'')
                                  : (_data['founderEmail']??'')),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 5. Pickup Info (Only relevant if approved/completed)
                        if (isApproved || isCompleted)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: const [
                                  Icon(Icons.location_on, color: Color(0xFF00695C)),
                                  SizedBox(width: 8),
                                  Text("Pickup Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00695C)))
                                ]),
                                const SizedBox(height: 12),
                                Builder(builder: (_) {
                                  final pickupType = (_data['pickupType'] ?? _data['availability'] ?? '').toString();
                                  final dropOff = (_data['dropOffLocation'] ?? _data['pickupLocation'] ?? _data['location'] ?? '').toString();
                                  if (pickupType == 'Keep with me' || pickupType == 'Kept with founder' || pickupType == 'Kept by founder') {
                                    final founder = _data['founderName'] ?? 'the founder';
                                    return Text("Kept with $founder. Contact for specific arrangement.", style: const TextStyle(fontWeight: FontWeight.bold));
                                  } else if (pickupType.toLowerCase().contains('drop') || pickupType.toLowerCase().contains('library') || dropOff.isNotEmpty) {
                                    final loc = dropOff.isNotEmpty ? dropOff : 'Drop-off location set by founder';
                                    return Text("Available for pickup at: $loc", style: const TextStyle(fontWeight: FontWeight.bold));
                                  } else {
                                    return Text("Location: ${dropOff.isNotEmpty ? dropOff : 'To be arranged'}", style: const TextStyle(fontWeight: FontWeight.bold));
                                  }
                                }),
                                const SizedBox(height: 4),
                                Text(_data['pickupInstructions'] ?? 'Please contact the finder to arrange the meeting.', style: TextStyle(color: Colors.grey[700])),
                              ],
                            ),
                          ),
                        
                        // 6. Action Buttons for Quick Contact
                        if (isApproved && !isCompleted)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchPhone(viewerIsFounder ? (_data['claimerProvidedContactValue'] ?? _data['claimerPhone']) : _data['founderPhone']),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Call'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchEmail(viewerIsFounder ? _data['claimerEmail'] : _data['founderEmail']),
                                    icon: const Icon(Icons.email),
                                    label: const Text('Email'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 80), // Space for bottom sheet
                      ],
                    ),
                  ),
                ),
                
                // BOTTOM ACTION BAR
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      // CLAIMER VIEW: Mark as received
                      if (isApproved && viewerIsClaimer)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _processing ? null : () async {
                              final confirm = await _showConfirmationDialog('Item Received?', 'Confirm that you have received the item. This will close the claim.');
                              if (confirm) await _markSuccessfulClaim();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _processing 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                              : const Text('I Have Received The Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                      // FOUNDER VIEW: Reject/Approve (Approval is usually done via a separate flow, but Reject is here)
                      if (isPending && viewerIsFounder)
                         Column(
                           children: [
                             // Note: Approval might be handled in a separate dialog or page in your app flow, 
                             // but if you need it here, you would add an 'Approve' button similar to Reject.
                             SizedBox(
                               width: double.infinity,
                               child: OutlinedButton(
                                 onPressed: _processing ? null : () async {
                                   final confirm = await _showConfirmationDialog('Reject Claim', 'Are you sure? This cannot be undone.');
                                   if (confirm) await _rejectClaim();
                                 },
                                 style: OutlinedButton.styleFrom(
                                   foregroundColor: Colors.red,
                                   side: const BorderSide(color: Colors.red),
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                 ),
                                 child: _processing
                                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red))
                                   : const Text('Reject Claim'),
                               ),
                             ),
                           ],
                         ),

                       if (!isPending && !isApproved && !isCompleted)
                        Text("Status: ${statusRaw.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(bool pending, bool approved, bool completed, bool rejected) {
    Color bg = Colors.grey;
    IconData icon = Icons.info;
    String title = "Status Unknown";
    String msg = "";

    if (pending) {
      bg = Colors.orange;
      icon = Icons.hourglass_top;
      title = "Under Review";
      msg = "The finder is reviewing the claim proof.";
    } else if (approved) {
      bg = Colors.blue;
      icon = Icons.check_circle;
      title = "Claim Approved";
      msg = "Contact the other party to arrange pickup.";
    } else if (completed) {
      bg = Colors.green;
      icon = Icons.verified;
      title = "Completed";
      msg = "The item has been returned successfully.";
    } else if (rejected) {
      bg = Colors.red;
      icon = Icons.cancel;
      title = "Rejected";
      msg = "This claim was not accepted by the finder.";
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(msg, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: onCopy, color: Colors.grey),
        ],
      ),
    );
  }
}