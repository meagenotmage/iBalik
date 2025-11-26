// ignore_for_file: unnecessary_cast, unused_element, dead_code, unused_local_variable, unused_parameter

import 'package:flutter/material.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../posts/posts_page.dart';
import 'claim_details_page.dart';
import 'confirm_return_page.dart';
import 'claim_review_page.dart';
import '../game/game_hub_page.dart';
import '../home/profile_page.dart';

class ClaimsPage extends StatefulWidget {
  const ClaimsPage({super.key});

  @override
  State<ClaimsPage> createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showReturnedItems = false;
  bool _showReceivedReturnedItems = false;
  String? _expandedClaimId;
  int _selectedIndex = 3; // Claims tab is selected (new position)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildFoundBySubtitle(Map<String, dynamic> data, String status, String submittedStr) {
    final founderName = (data['founderName'] ?? data['posterName'] ?? data['userName'])?.toString();
    final founderId = data['founderId']?.toString();
    final itemId = data['itemId'];
    final description = (data['itemDescription'] ?? data['claimDescription'] ?? data['description'] ?? data['details'])?.toString() ?? '';
    final pickup = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'])?.toString() ?? '';

    Widget founderWidget() {
      if (founderName != null && founderName.isNotEmpty) return Text(founderName, style: TextStyle(color: Colors.grey[800]));
      if ((founderId == null || founderId.isEmpty) && (itemId == null)) return const Text('Unknown', style: TextStyle(color: Colors.grey));
      return FutureBuilder<String>(
        future: _resolveFounderDisplayName(founderId, itemId),
        builder: (context, snapshot) {
          String display = 'Unknown';
          if (snapshot.hasData && snapshot.data!.isNotEmpty) display = snapshot.data!;
          return Text(display, style: TextStyle(color: Colors.grey[800]));
        },
      );
    }

    final submittedTs = data['submittedDate'];
    final shortDate = _formatShortDate(submittedTs);
    final relative = _formatRelativeCompact(submittedTs);
    final timeOfDay = _formatTimeOfDay(submittedTs);
    final dropOff = (data['dropOffLocation'] ?? data['dropoffLocation'] ?? data['founderLocation'] ?? pickup)?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800])),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: founderWidget()),
          ],
        ),
        const SizedBox(height: 6),
        // Claimed time (when the user submitted the claim)
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                (() {
                  final parts = <String>[];
                  if (shortDate.isNotEmpty) parts.add(shortDate);
                  if (relative.isNotEmpty) parts.add(relative);
                  return ' ' + parts.join(' ');
                })(),
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Drop-off / location info (either explicit dropOff or fallback to pickup/founder)
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: (() {
                if (dropOff.isNotEmpty && dropOff != 'null') {
                  return Text(dropOff, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                }
                if (pickup.isNotEmpty && pickup != 'null') {
                  return Text(pickup, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                }
                // Try resolving from lost_items asynchronously
                return FutureBuilder<String?>(
                  future: _resolveLocationFromItem(data['itemId'] ?? data['itemDocId'] ?? data['item']),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return Text('Resolving location...', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                    final loc = snap.data;
                    if (loc != null && loc.isNotEmpty) return Text(loc, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                    final fName = (data['founderName'] ?? data['posterName'] ?? data['userName'])?.toString();
                    if (fName != null && fName.isNotEmpty) return Text('With $fName', style: TextStyle(color: Colors.grey[700], fontSize: 12));
                    return Text('Location unknown', style: TextStyle(color: Colors.grey[700], fontSize: 12));
                  },
                );
              })(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimerSubtitle(Map<String, dynamic> data, String status, String submittedStr) {
    final claimerName = (data['claimerName'] ?? data['claimerDisplayName'] ?? data['claimerEmail'])?.toString();
    final claimerId = data['claimerId']?.toString();
    final itemId = data['itemId'];
    final description = (data['claimDescription'] ?? data['itemDescription'] ?? data['description'] ?? data['details'])?.toString() ?? '';
    final pickup = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'])?.toString() ?? '';

    Widget claimerWidget() {
      if (claimerName != null && claimerName.isNotEmpty) return Text(claimerName, style: TextStyle(color: Colors.grey[800]));
      if ((claimerId == null || claimerId.isEmpty) && (itemId == null)) return const Text('Unknown', style: TextStyle(color: Colors.grey));
      return FutureBuilder<String>(
        future: _resolveClaimerDisplayName(claimerId, itemId),
        builder: (context, snapshot) {
          String display = 'Unknown';
          if (snapshot.hasData && snapshot.data!.isNotEmpty) display = snapshot.data!;
          return Text(display, style: TextStyle(color: Colors.grey[800]));
        },
      );
    }

    final submittedTs = data['submittedDate'];
    final shortDate = _formatShortDate(submittedTs);
    final relative = _formatRelativeCompact(submittedTs);
    final timeOfDay = _formatTimeOfDay(submittedTs);
    final dropOff = (data['dropOffLocation'] ?? data['dropoffLocation'] ?? data['founderLocation'] ?? pickup)?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800])),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: claimerWidget()),
          ],
        ),
        const SizedBox(height: 6),
        // Claimed time (when the user submitted the claim)
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                (() {
                  final parts = <String>[];
                  if (shortDate.isNotEmpty) parts.add(shortDate);
                  if (relative.isNotEmpty) parts.add(relative);
                  return ' ' + parts.join(' ');
                })(),
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Drop-off / location info
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: (() {
                if (dropOff.isNotEmpty && dropOff != 'null') {
                  return Text(dropOff, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                }
                if (pickup.isNotEmpty && pickup != 'null') {
                  return Text(pickup, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                }
                return FutureBuilder<String?>(
                  future: _resolveLocationFromItem(data['itemId'] ?? data['itemDocId'] ?? data['item']),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return Text('Resolving location...', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                    final loc = snap.data;
                    if (loc != null && loc.isNotEmpty) return Text(loc, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis);
                    final cName = (data['claimerName'] ?? data['claimerDisplayName'] ?? data['claimerEmail'])?.toString();
                    if (cName != null && cName.isNotEmpty) return Text('With $cName', style: TextStyle(color: Colors.grey[700], fontSize: 12));
                    return Text('Location unknown', style: TextStyle(color: Colors.grey[700], fontSize: 12));
                  },
                );
              })(),
            ),
          ],
        ),
      ],
    );
  }

  Future<String> _resolveClaimerDisplayName(String? claimerId, dynamic itemId) async {
    try {
      if (claimerId != null && claimerId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(claimerId).get();
        if (userDoc.exists) {
          final u = userDoc.data() as Map<String, dynamic>?;
          final name = (u?['displayName'] ?? u?['name'] ?? u?['userName'])?.toString();
          if (name != null && name.isNotEmpty) return name;
        }
      }

      if (itemId != null) {
        try {
          final itemRef = FirebaseFirestore.instance.collection('lost_items').doc(itemId.toString());
          final itemDoc = await itemRef.get();
          if (itemDoc.exists) {
            final it = itemDoc.data() as Map<String, dynamic>?;
            final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
            if (posterName != null && posterName.isNotEmpty) return posterName;
          }
        } catch (_) {}

        try {
          final q = await FirebaseFirestore.instance.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
          if (q.docs.isNotEmpty) {
            final it = q.docs.first.data() as Map<String, dynamic>?;
            final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
            if (posterName != null && posterName.isNotEmpty) return posterName;
          }
        } catch (_) {}
      }
    } catch (_) {}
    if (claimerId != null && claimerId.isNotEmpty) return claimerId;
    return 'Unknown';
  }

  Future<String> _resolveFounderDisplayName(String? founderId, dynamic itemId) async {
    try {
      // 1) Try users/{founderId}
      if (founderId != null && founderId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(founderId).get();
        if (userDoc.exists) {
          final u = userDoc.data() as Map<String, dynamic>?;
          final name = (u?['displayName'] ?? u?['name'] ?? u?['userName'])?.toString();
          if (name != null && name.isNotEmpty) return name;
        }
      }

      // 2) Try lost_items by doc id (itemId could be a doc id)
      if (itemId != null) {
        try {
          final itemRef = FirebaseFirestore.instance.collection('lost_items').doc(itemId.toString());
          final itemDoc = await itemRef.get();
          if (itemDoc.exists) {
            final it = itemDoc.data() as Map<String, dynamic>?;
            final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
            if (posterName != null && posterName.isNotEmpty) return posterName;
          }
        } catch (_) {}

        // 3) Fallback: query lost_items where itemId == itemId (for older data)
        try {
          final q = await FirebaseFirestore.instance.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
          if (q.docs.isNotEmpty) {
            final it = q.docs.first.data() as Map<String, dynamic>?;
            final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
            if (posterName != null && posterName.isNotEmpty) return posterName;
          }
        } catch (_) {}
      }
    } catch (_) {}
    // Last-resort: return founderId short or 'Unknown'
    if (founderId != null && founderId.isNotEmpty) return founderId;
    return 'Unknown';
  }

  Future<String?> _resolveLocationFromItem(dynamic itemId) async {
    if (itemId == null) return null;
    try {
      final fs = FirebaseFirestore.instance;
      // Try doc id first
      final docRef = fs.collection('lost_items').doc(itemId.toString());
      final doc = await docRef.get();
      if (doc.exists) {
        final d = doc.data();
        final loc = (d?['location'] ?? d?['pickupLocation'] ?? d?['foundAt'])?.toString();
        if (loc != null && loc.isNotEmpty) return loc;
      }

      // Fallback: query by itemId field
      final q = await fs.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        final loc = (d['location'] ?? d['pickupLocation'] ?? d['foundAt'])?.toString();
        if (loc != null && loc.isNotEmpty) return loc;
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate().toLocal();
    } else if (ts is DateTime) {
      dt = ts.toLocal();
    } else {
      try {
        dt = DateTime.parse(ts.toString()).toLocal();
      } catch (_) {
        return ts.toString();
      }
    }
    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${monthNames[dt.month-1]} ${dt.day}, ${dt.year}';
  }

  String _formatShortDate(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) dt = ts.toDate().toLocal();
    else if (ts is DateTime) dt = ts.toLocal();
    else {
      try {
        dt = DateTime.parse(ts.toString()).toLocal();
      } catch (_) {
        return ts.toString();
      }
    }
    String dd = dt.day.toString().padLeft(2, '0');
    String mm = dt.month.toString().padLeft(2, '0');
    String yy = dt.year.toString().substring(2);
    return '$dd/$mm/$yy';
  }

  String _formatRelativeCompact(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) dt = ts.toDate().toLocal();
    else if (ts is DateTime) dt = ts.toLocal();
    else {
      try {
        dt = DateTime.parse(ts.toString()).toLocal();
      } catch (_) {
        return '';
      }
    }
    final diff = DateTime.now().toLocal().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    final years = (diff.inDays / 365).floor();
    return '${years}y ago';
  }

  String _formatTimeOfDay(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) dt = ts.toDate().toLocal();
    else if (ts is DateTime) dt = ts.toLocal();
    else {
      try {
        dt = DateTime.parse(ts.toString()).toLocal();
      } catch (_) {
        return '';
      }
    }
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claims',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage your claim requests',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: AppShadows.soft,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'My Claims',
                    isSelected: _tabController.index == 0,
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(0);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    label: 'Found Claims',
                    isSelected: _tabController.index == 1,
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(1);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Claims Tab
                _buildMyClaimsTab(),
                
                // Received Tab
                _buildReceivedTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.article, 'Posts', 1),
          _buildNavItem(Icons.assignment_return, 'Claims', 2),
          _buildNavItem(Icons.videogame_asset, 'Game', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to Home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      // Navigate to Posts
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const PostsPage()),
      );
    } else if (index == 2) {
      // Navigate to Game Hub
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const GameHubPage()),
      );
    } else if (index == 4) {
      // Navigate to Profile
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const ProfilePage()),
      );
    } else if (index != 3) {
      // For other tabs, just update the selected state
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildMyClaimsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Please sign in to view your claims.', style: TextStyle(color: Colors.grey[700])),
              ),
            );
    }

    final Stream<QuerySnapshot> myClaimsStream = FirebaseFirestore.instance
      .collection('claims')
      .where('claimerId', isEqualTo: uid)
      .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: myClaimsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading claims'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];
        // Client-side sort by submittedDate (newest first) to avoid requiring
        // a Firestore composite index on server-side ordering for older data.
        try {
          docs = docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['submittedDate'];
              final bTs = (b.data() as Map)['submittedDate'];
              DateTime aDt = DateTime.fromMillisecondsSinceEpoch(0);
              DateTime bDt = DateTime.fromMillisecondsSinceEpoch(0);
              if (aTs is Timestamp) aDt = aTs.toDate();
              if (bTs is Timestamp) bDt = bTs.toDate();
              return bDt.compareTo(aDt);
            });
        } catch (_) {}
        if (docs.isEmpty) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 40),
                Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No claims yet', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = Map<String, dynamic>.from(doc.data() as Map);
            data['docId'] = doc.id;
            // Normalize item fields: prefer values copied into the claim, then fall back
            data['itemTitle'] = (data['itemTitle'] ?? data['title'] ?? data['itemName'] ?? data['name'])?.toString();
            data['itemDescription'] = (data['itemDescription'] ?? data['description'] ?? data['details'] ?? data['claimDescription'])?.toString();
            data['location'] = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'] ?? data['dropOffLocation'])?.toString();
            data['title'] = (data['title'] ?? data['itemTitle'])?.toString();
            final title = (data['itemTitle'] ?? data['title'] ?? 'Untitled').toString();
            final status = (data['status'] ?? 'pending').toString();
            final submitted = data['submittedDate'];
            final submittedStr = _formatTimestamp(submitted);

            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[100]),
                child: Icon(Icons.image, color: Colors.grey[400]),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: _buildFoundBySubtitle(data, status, submittedStr),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (status == 'approved' ? Colors.green[50] : (status == 'rejected' ? Colors.red[50] : Colors.amber[50])),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: (status == 'approved' ? Colors.green[800] : (status == 'rejected' ? Colors.red[800] : Colors.amber[900])),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(page: ClaimDetailsPage(claimData: data)),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReceivedTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Please sign in to view received claims.', style: TextStyle(color: Colors.grey[700])),
        ),
      );
    }

    // For received/found claims we now read from the `claims` collection where
    // the current user is the founder of the item. Claim documents are created
    // by seekers (claimers) and have status 'pending' initially.
    final Stream<QuerySnapshot> receivedStream = FirebaseFirestore.instance
      .collection('claims')
      .where('founderId', isEqualTo: uid)
      .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: receivedStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error loading received claims'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data?.docs ?? [];
        try {
          docs = docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['submittedDate'];
              final bTs = (b.data() as Map)['submittedDate'];
              DateTime aDt = DateTime.fromMillisecondsSinceEpoch(0);
              DateTime bDt = DateTime.fromMillisecondsSinceEpoch(0);
              if (aTs is Timestamp) aDt = aTs.toDate();
              if (bTs is Timestamp) bDt = bTs.toDate();
              return bDt.compareTo(aDt);
            });
        } catch (_) {}
        if (docs.isEmpty) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 40),
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No received claims', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = Map<String, dynamic>.from(doc.data() as Map);
            data['docId'] = doc.id;
            data['itemTitle'] = (data['itemTitle'] ?? data['title'] ?? data['itemName'] ?? data['name'])?.toString();
            data['itemDescription'] = (data['itemDescription'] ?? data['description'] ?? data['details'] ?? data['claimDescription'])?.toString();
            data['location'] = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'] ?? data['dropOffLocation'])?.toString();
            data['title'] = (data['title'] ?? data['itemTitle'])?.toString();
            data['claimerName'] = (data['claimerName'] ?? data['claimerDisplayName'] ?? data['claimerEmail'])?.toString();
            final title = (data['itemTitle'] ?? 'Untitled').toString();
            final claimer = (data['claimerName'] ?? data['claimerEmail'] ?? '').toString();
            final submitted = data['submittedDate'];
            final submittedStr = _formatTimestamp(submitted);

            final status = (data['status'] ?? 'pending').toString();
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[100]),
                child: Icon(Icons.image, color: Colors.grey[400]),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Show claimer info and timing, but don't surface action/status chips here -
              // founders should open the claim to approve/reject, and seekers see under-review text.
              subtitle: _buildClaimerSubtitle(data, status, submittedStr),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(page: ClaimDetailsPage(claimData: data)),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPendingReviewClaimCard({
    required String id,
    required String title,
    required String claimedBy,
    required String submittedDate,
    required String claimDescription,
    String? claimerEmail,
    String? claimerId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: item image, title, submitted date, claimer name/email
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.badge,
                    color: Colors.grey[600],
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Claim submitted', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(submittedDate, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (claimedBy.isNotEmpty) Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$claimedBy' + (claimerEmail != null && claimerEmail.isNotEmpty ? ' (${claimerEmail})' : ''),
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Yellow warning box with claim description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF57C00),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tap to review details and decide',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF57C00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          claimDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Review Claim Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      page: ClaimReviewPage(
                        claimData: {
                          'itemTitle': title,
                          'claimerName': claimedBy,
                          'claimerEmail': claimerEmail ?? '',
                          'submittedDate': submittedDate,
                          'claimDescription': claimDescription,
                          'claimerId': claimerId ?? '',
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Review Claim',
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
    );
  }

  Widget _buildReceivedClaimCard({
    required String id,
    required String title,
    required String status,
    required Color statusColor,
    required String claimedBy,
    required String approvedDate,
    required String pickupLocation,
    Color? backgroundColor,
    required String itemDetails,
    required String seekerName,
    required String seekerPhone,
    required String seekerEmail,
  }) {
    final isExpanded = _expandedClaimId == id;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main claim card
          InkWell(
            onTap: () {
              setState(() {
                _expandedClaimId = isExpanded ? null : id;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Item Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.headphones,
                      color: Colors.grey[600],
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Claimed by $claimedBy',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Approved $approvedDate',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Color(0xFF2196F3),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Contact via phone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• Tap to expand',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
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
          ),
          
          // Expanded Details
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              seekerName,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              seekerPhone,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seekerEmail,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Pickup Location
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pickupLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Return Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            page: ConfirmReturnPage(
                              itemData: {
                                'title': title,
                                'description': itemDetails,
                                'seekerName': seekerName,
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Successful Return',
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
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableClaimCard({
    required String id,
    required String title,
    required String status,
    required Color statusColor,
    required String foundBy,
    required String claimedDate,
    String? pickupLocation,
    Color? backgroundColor,
    required String claimRequest,
    
    String? approvedDate,
  }) {
    final isExpanded = _expandedClaimId == id;
    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main claim card
          InkWell(
            onTap: () {
              setState(() {
                _expandedClaimId = isExpanded ? null : id;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Item Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.grey[500],
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Found by $foundBy',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Claimed $claimedDate',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (pickupLocation != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pickup: $pickupLocation',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Arrow Icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Your Claim Request section
                  const Text(
                    'Your Claim Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Claim message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      claimRequest,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Submitted date
                  Text(
                    'Submitted:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  if (approvedDate != null) ...[
                    Text(
                      'Approved: $approvedDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Status-specific message
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            color: Color(0xFFF57C00),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Under Review',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF57C00),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'The finder is reviewing your claim request. You\'ll be notified once they make a decision.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (isApproved) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Claim Approved!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your claim has been approved. Please follow the pickup instructions to collect your item.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Pickup location details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pickup Location: ${pickupLocation ?? 'TBD'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Visit the Library information desk during library hours with a valid ID.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // View Contact Details button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              page: ClaimDetailsPage(
                                claimData: {
                                  'title': title,
                                  'description': claimRequest,
                                  'foundBy': foundBy,
                                  'pickupLocation': pickupLocation,
                                  'approvedDate': approvedDate,
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Contact Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReturnedItemsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showReturnedItems = !_showReturnedItems;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF4CAF50),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Claimed Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '3 completed claims',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showReturnedItems ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded returned items list
          if (_showReturnedItems) ...[
            const Divider(height: 1),
            _buildCompletedClaimItem(
              title: 'Red Backpack',
              foundBy: 'L. Garcia',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildCompletedClaimItem(
              title: 'Brown Wallet',
              foundBy: 'M. Torres',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildCompletedClaimItem(
              title: 'Silver Calculator',
              foundBy: 'R. Gonzales',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedClaimItem({
    required String title,
    required String foundBy,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: Colors.grey[500],
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Found by $foundBy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Returned',
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
          
          // Completed badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedReturnedItemsSection() {
    return Container(
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
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showReceivedReturnedItems = !(_showReceivedReturnedItems);
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF4CAF50),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Successfully Returned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '2 items returned to owners',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    (_showReceivedReturnedItems) ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded returned items list
          if (_showReceivedReturnedItems == true) ...[
            const Divider(height: 1),
            _buildReceivedCompletedItem(
              title: 'Black Laptop Charger',
              returnedTo: 'J. Smith',
              returnedDate: '1/10/2024',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildReceivedCompletedItem(
              title: 'Blue Water Bottle',
              returnedTo: 'A. Johnson',
              returnedDate: '1/08/2024',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceivedCompletedItem({
    required String title,
    required String returnedTo,
    required String returnedDate,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: Colors.grey[500],
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Returned to $returnedTo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Date: $returnedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Completed badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Returned',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
