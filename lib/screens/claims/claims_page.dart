// ignore_for_file: unnecessary_cast, unused_element, dead_code, unused_local_variable, unused_parameter

import 'package:flutter/material.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../utils/claims_theme.dart';
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
  
  // Collapsible section states for My Claims
  bool _pendingExpanded = true;
  bool _approvedExpanded = true;
  bool _rejectedExpanded = true;
  bool _completedExpanded = false; // Collapsed by default
  
  // Collapsible section states for Found Claims
  bool _foundPendingExpanded = true;
  bool _foundApprovedExpanded = true;
  bool _foundRejectedExpanded = true;
  bool _foundCompletedExpanded = false; // Collapsed by default

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
    // First, try to use the founderName if it's already available
    if (founderName != null && founderName.isNotEmpty && founderName != 'null') {
      return Text(founderName, style: TextStyle(color: Colors.grey[800]));
    }
    
    // If we have founderId, try to resolve the name from Firestore
    if (founderId != null && founderId.isNotEmpty) {
      return FutureBuilder<String>(
        future: _resolveFounderDisplayNameVerbose(founderId, itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('Loading...', style: TextStyle(color: Colors.grey[600]));
          }
          String display = 'Unknown Founder';
          if (snapshot.hasData && snapshot.data!.isNotEmpty && snapshot.data != 'Unknown') {
            display = snapshot.data!;
          }
          return Text(display, style: TextStyle(color: Colors.grey[800]));
        },
      );
    }
    
    // Last resort: try to get founder name from the lost item
    return FutureBuilder<String>(
      future: _resolveFounderNameFromItem(itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...', style: TextStyle(color: Colors.grey[600]));
        }
        String display = 'Unknown Founder';
        if (snapshot.hasData && snapshot.data!.isNotEmpty && snapshot.data != 'Unknown') {
          display = snapshot.data!;
        }
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
                return ' ${parts.join(' ')}';
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

Future<String> _resolveFounderDisplayNameVerbose(String? founderId, dynamic itemId) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  print('Resolving founder display name:');
  print('  - founderId: $founderId');
  print('  - currentUserId: $currentUserId');
  print('  - itemId: $itemId');
  
  try {
    // 1) Try users/{founderId}
    if (founderId != null && founderId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(founderId).get();
      if (userDoc.exists) {
        final u = userDoc.data();
        final name = (u?['displayName'] ?? u?['name'] ?? u?['userName'])?.toString();
        if (name != null && name.isNotEmpty) {
          print('  - Found name from users collection: $name');
          return name;
        }
      }
    }

    // 2) Try lost_items by doc id (itemId could be a doc id)
    if (itemId != null) {
      try {
        final itemRef = FirebaseFirestore.instance.collection('lost_items').doc(itemId.toString());
        final itemDoc = await itemRef.get();
        if (itemDoc.exists) {
          final it = itemDoc.data();
          final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
          if (posterName != null && posterName.isNotEmpty) {
            print('  - Found name from lost_items: $posterName');
            return posterName;
          }
        }
      } catch (_) {}

      // 3) Fallback: query lost_items where itemId == itemId (for older data)
      try {
        final q = await FirebaseFirestore.instance.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
        if (q.docs.isNotEmpty) {
          final it = q.docs.first.data() as Map<String, dynamic>?;
          final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
          if (posterName != null && posterName.isNotEmpty) {
            print('  - Found name from lost_items query: $posterName');
            return posterName;
          }
        }
      } catch (_) {}
    }
  } catch (e) {
    print('Error resolving founder display name: $e');
  }
  
  // Last-resort: return founderId short or 'Unknown'
  if (founderId != null && founderId.isNotEmpty) {
    print('  - Using founderId as fallback: $founderId');
    return founderId;
  }
  
  print('  - No founder info found, using "Unknown"');
  return 'Unknown';
}

Future<String> _resolveFounderNameFromItem(dynamic itemId) async {
  if (itemId == null) return 'Unknown';
  
  try {
    final fs = FirebaseFirestore.instance;
    
    // Try doc id first
    final docRef = fs.collection('lost_items').doc(itemId.toString());
    final doc = await docRef.get();
    if (doc.exists) {
      final d = doc.data();
      final name = (d?['userName'] ?? d?['posterName'] ?? d?['founderName'] ?? d?['foundBy'])?.toString();
      if (name != null && name.isNotEmpty && name != 'null') {
        return name;
      }
    }

    // Fallback: query by itemId field
    final q = await fs.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
    if (q.docs.isNotEmpty) {
      final d = q.docs.first.data();
      final name = (d['userName'] ?? d['posterName'] ?? d['founderName'] ?? d['foundBy'])?.toString();
      if (name != null && name.isNotEmpty && name != 'null') {
        return name;
      }
    }
  } catch (e) {
    print('Error resolving founder name from item: $e');
  }
  
  return 'Unknown';
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
                  return ' ${parts.join(' ')}';
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
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  print('Resolving founder display name:');
  print('  - founderId: $founderId');
  print('  - currentUserId: $currentUserId');
  print('  - itemId: $itemId');
  
  try {
    // 1) Try users/{founderId}
    if (founderId != null && founderId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(founderId).get();
      if (userDoc.exists) {
        final u = userDoc.data();
        final name = (u?['displayName'] ?? u?['name'] ?? u?['userName'])?.toString();
        if (name != null && name.isNotEmpty) {
          print('  - Found name from users collection: $name');
          return name;
        }
      }
    }

    // 2) Try lost_items by doc id (itemId could be a doc id)
    if (itemId != null) {
      try {
        final itemRef = FirebaseFirestore.instance.collection('lost_items').doc(itemId.toString());
        final itemDoc = await itemRef.get();
        if (itemDoc.exists) {
          final it = itemDoc.data();
          final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
          if (posterName != null && posterName.isNotEmpty) {
            print('  - Found name from lost_items: $posterName');
            return posterName;
          }
        }
      } catch (_) {}

      // 3) Fallback: query lost_items where itemId == itemId (for older data)
      try {
        final q = await FirebaseFirestore.instance.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
        if (q.docs.isNotEmpty) {
          final it = q.docs.first.data() as Map<String, dynamic>?;
          final posterName = (it?['userName'] ?? it?['posterName'] ?? it?['foundBy'])?.toString();
          if (posterName != null && posterName.isNotEmpty) {
            print('  - Found name from lost_items query: $posterName');
            return posterName;
          }
        }
      } catch (_) {}
    }
  } catch (e) {
    print('Error resolving founder display name: $e');
  }
  
  // Last-resort: return founderId short or 'Unknown'
  if (founderId != null && founderId.isNotEmpty) {
    print('  - Using founderId as fallback: $founderId');
    return founderId;
  }
  
  print('  - No founder info found, using "Unknown"');
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
    if (ts is Timestamp) {
      dt = ts.toDate().toLocal();
    } else if (ts is DateTime) dt = ts.toLocal();
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
    if (ts is Timestamp) {
      dt = ts.toDate().toLocal();
    } else if (ts is DateTime) dt = ts.toLocal();
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
    if (ts is Timestamp) {
      dt = ts.toDate().toLocal();
    } else if (ts is DateTime) dt = ts.toLocal();
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
        title: const Text(
          'Claims',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Switcher (Profile-style)
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.lightGray.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSwitchTab('My Claims', 0)),
                Expanded(child: _buildSwitchTab('Claim Requests', 1)),
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

  Widget _buildSwitchTab(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: isSelected ? Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ) : null,
          boxShadow: isSelected ? AppShadows.soft : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.article_outlined, 'Posts', 1),
              _buildNavItem(Icons.emoji_events_outlined, 'Game Hub', 2),
              _buildNavItem(Icons.description_outlined, 'Claims', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
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
      // Claims tab is already selected
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // =============================================
  // MY CLAIMS TAB - Categorized by Status
  // =============================================
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
        
        if (docs.isEmpty) {
          return _buildEmptyState('No claims yet', Icons.inbox);
        }

        // Group claims by status
        final Map<String, List<Map<String, dynamic>>> groupedClaims = {
          'pending': [],
          'approved': [],
          'rejected': [],
          'completed': [],
        };

        for (final doc in docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['docId'] = doc.id;
          // Normalize item fields: prefer values copied into the claim, then fall back
          data['itemTitle'] = (data['itemTitle'] ?? data['title'] ?? data['itemName'] ?? data['name'])?.toString();
          data['itemDescription'] = (data['itemDescription'] ?? data['description'] ?? data['details'] ?? data['claimDescription'])?.toString();
          data['location'] = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'] ?? data['dropOffLocation'])?.toString();
          data['title'] = (data['title'] ?? data['itemTitle'])?.toString();
          
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final category = _normalizeStatus(status);
          groupedClaims[category]?.add(data);
        }

        // Sort each group by recency
        for (final key in groupedClaims.keys) {
          _sortByRecency(groupedClaims[key]!);
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Pending Section
              if (groupedClaims['pending']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Pending',
                  count: groupedClaims['pending']!.length,
                  isExpanded: _pendingExpanded,
                  onToggle: () => setState(() => _pendingExpanded = !_pendingExpanded),
                  statusColor: ClaimsColors.pending,
                  icon: Icons.schedule,
                  claims: groupedClaims['pending']!,
                  isMyClaims: true,
                ),
              
              // Approved Section
              if (groupedClaims['approved']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Approved',
                  count: groupedClaims['approved']!.length,
                  isExpanded: _approvedExpanded,
                  onToggle: () => setState(() => _approvedExpanded = !_approvedExpanded),
                  statusColor: ClaimsColors.approved,
                  icon: Icons.check_circle_outline,
                  claims: groupedClaims['approved']!,
                  isMyClaims: true,
                ),
              
              // Rejected Section
              if (groupedClaims['rejected']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Rejected',
                  count: groupedClaims['rejected']!.length,
                  isExpanded: _rejectedExpanded,
                  onToggle: () => setState(() => _rejectedExpanded = !_rejectedExpanded),
                  statusColor: ClaimsColors.rejected,
                  icon: Icons.cancel_outlined,
                  claims: groupedClaims['rejected']!,
                  isMyClaims: true,
                ),
              
              // Completed Section (collapsed by default)
              if (groupedClaims['completed']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Completed',
                  count: groupedClaims['completed']!.length,
                  isExpanded: _completedExpanded,
                  onToggle: () => setState(() => _completedExpanded = !_completedExpanded),
                  statusColor: ClaimsColors.info,
                  icon: Icons.task_alt,
                  claims: groupedClaims['completed']!,
                  isMyClaims: true,
                ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // FOUND CLAIMS TAB - Categorized by Status
  // =============================================
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
        
        if (docs.isEmpty) {
          return _buildEmptyState('No received claims', Icons.inbox_outlined);
        }

        // Group claims by status
        final Map<String, List<Map<String, dynamic>>> groupedClaims = {
          'pending': [],
          'approved': [],
          'rejected': [],
          'completed': [],
        };

        for (final doc in docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['docId'] = doc.id;
          // Normalize item fields: prefer values copied into the claim, then fall back
          data['itemTitle'] = (data['itemTitle'] ?? data['title'] ?? data['itemName'] ?? data['name'])?.toString();
          data['itemDescription'] = (data['itemDescription'] ?? data['description'] ?? data['details'] ?? data['claimDescription'])?.toString();
          data['location'] = (data['location'] ?? data['pickupLocation'] ?? data['foundAt'] ?? data['dropOffLocation'])?.toString();
          data['title'] = (data['title'] ?? data['itemTitle'])?.toString();
          data['claimerName'] = (data['claimerName'] ?? data['claimerDisplayName'] ?? data['claimerEmail'])?.toString();
          
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final category = _normalizeStatus(status);
          groupedClaims[category]?.add(data);
        }

        // Sort each group by recency
        for (final key in groupedClaims.keys) {
          _sortByRecency(groupedClaims[key]!);
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Pending Section (Needs Review)
              if (groupedClaims['pending']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Needs Review',
                  count: groupedClaims['pending']!.length,
                  isExpanded: _foundPendingExpanded,
                  onToggle: () => setState(() => _foundPendingExpanded = !_foundPendingExpanded),
                  statusColor: ClaimsColors.pending,
                  icon: Icons.rate_review_outlined,
                  claims: groupedClaims['pending']!,
                  isMyClaims: false,
                ),
              
              // Approved Section (Awaiting Return)
              if (groupedClaims['approved']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Awaiting Return',
                  count: groupedClaims['approved']!.length,
                  isExpanded: _foundApprovedExpanded,
                  onToggle: () => setState(() => _foundApprovedExpanded = !_foundApprovedExpanded),
                  statusColor: ClaimsColors.approved,
                  icon: Icons.handshake_outlined,
                  claims: groupedClaims['approved']!,
                  isMyClaims: false,
                ),
              
              // Rejected Section
              if (groupedClaims['rejected']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Rejected',
                  count: groupedClaims['rejected']!.length,
                  isExpanded: _foundRejectedExpanded,
                  onToggle: () => setState(() => _foundRejectedExpanded = !_foundRejectedExpanded),
                  statusColor: ClaimsColors.rejected,
                  icon: Icons.cancel_outlined,
                  claims: groupedClaims['rejected']!,
                  isMyClaims: false,
                ),
              
              // Completed Section (Returned Items)
              if (groupedClaims['completed']!.isNotEmpty)
                _buildCollapsibleSection(
                  title: 'Returned',
                  count: groupedClaims['completed']!.length,
                  isExpanded: _foundCompletedExpanded,
                  onToggle: () => setState(() => _foundCompletedExpanded = !_foundCompletedExpanded),
                  statusColor: ClaimsColors.info,
                  icon: Icons.task_alt,
                  claims: groupedClaims['completed']!,
                  isMyClaims: false,
                ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // HELPER METHODS
  // =============================================
  
  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'submitted':
      case 'under_review':
        return 'pending';
      case 'approved':
      case 'accepted':
        return 'approved';
      case 'rejected':
      case 'denied':
        return 'rejected';
      case 'completed':
      case 'returned':
      case 'done':
        return 'completed';
      default:
        return 'pending';
    }
  }

  void _sortByRecency(List<Map<String, dynamic>> claims) {
    claims.sort((a, b) {
      final aTs = a['submittedDate'];
      final bTs = b['submittedDate'];
      DateTime aDt = DateTime.fromMillisecondsSinceEpoch(0);
      DateTime bDt = DateTime.fromMillisecondsSinceEpoch(0);
      if (aTs is Timestamp) aDt = aTs.toDate();
      if (bTs is Timestamp) bDt = bTs.toDate();
      return bDt.compareTo(aDt); // Newest first
    });
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ClaimsWidgets.emptyState(
        message: message,
        icon: icon,
        subtitle: 'Claims you submit or receive will appear here',
      ),
    );
  }

  // =============================================
  // COLLAPSIBLE SECTION WIDGET
  // =============================================
  Widget _buildCollapsibleSection({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color statusColor,
    required IconData icon,
    required List<Map<String, dynamic>> claims,
    required bool isMyClaims,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          // Section Header (Tap to expand/collapse)
          ClaimsWidgets.sectionHeader(
            title: title,
            count: count,
            isExpanded: isExpanded,
            onToggle: onToggle,
            color: statusColor,
            icon: icon,
          ),
          
          // Claims List (Animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: claims.asMap().entries.map((entry) {
                      final claim = entry.value;
                      return _buildCompactClaimCard(
                        claim: claim,
                        isMyClaims: isMyClaims,
                        statusColor: statusColor,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // =============================================
  // COMPACT EXPANDABLE CLAIM CARD
  // =============================================
  Widget _buildCompactClaimCard({
    required Map<String, dynamic> claim,
    required bool isMyClaims,
    required Color statusColor,
  }) {
    final isExpanded = _expandedClaimId == claim['docId'];
    final title = (claim['itemTitle'] ?? claim['title'] ?? 'Untitled').toString();
    final status = (claim['status'] ?? 'pending').toString();
    final normalizedStatus = _normalizeStatus(status);
    final submitted = claim['submittedDate'];
    final submittedDate = submitted is Timestamp ? submitted.toDate() : DateTime.now();
    final timeAgo = _getTimeAgo(submittedDate);
    final imageUrl = claim['imageUrl'] ?? claim['proofImage'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: isExpanded ? AppShadows.soft : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact View (Always visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedClaimId = isExpanded ? null : claim['docId'];
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Row(
                children: [
                  // Thumbnail
                  ClaimsWidgets.thumbnail(
                    imageUrl: imageUrl?.toString(),
                    placeholderIcon: isMyClaims ? Icons.inventory_2_outlined : Icons.person_outline,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Title and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMyClaims 
                              ? 'Submitted $timeAgo'
                              : 'From ${claim['claimerName'] ?? 'Unknown'} • $timeAgo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  _buildStatusBadge(normalizedStatus, statusColor),
                  
                  const SizedBox(width: AppSpacing.xs),
                  
                  // Expand Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Details (Animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(claim, isMyClaims, normalizedStatus, statusColor),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    String label;
    IconData? icon;
    switch (status) {
      case 'pending':
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'approved':
        label = 'Approved';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'completed':
        label = 'Done';
        icon = Icons.task_alt;
        break;
      default:
        label = 'Pending';
        icon = Icons.schedule;
    }
    
    return ClaimsWidgets.statusBadge(
      label: label,
      color: color,
      icon: icon,
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // =============================================
  // EXPANDED DETAILS VIEW
  // =============================================
  Widget _buildExpandedDetails(
    Map<String, dynamic> claim,
    bool isMyClaims,
    String status,
    Color statusColor,
  ) {
    final description = claim['claimDescription'] ?? claim['description'] ?? '';
    final imageUrl = claim['imageUrl'] ?? claim['proofImage'];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[200]),
          const SizedBox(height: AppSpacing.sm),
          
          // Item Image (if available)
          if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Description
          if (description.toString().isNotEmpty) ...[
            Text(
              'Claim Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Additional Info
          if (isMyClaims)
            _buildClaimerAdditionalInfo(claim)
          else
            _buildFounderAdditionalInfo(claim),
          
          const SizedBox(height: AppSpacing.md),
          
          // CTA Buttons
          _buildCTAButtons(claim, isMyClaims, status, statusColor),
        ],
      ),
    );
  }

Widget _buildClaimerAdditionalInfo(Map<String, dynamic> claim) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final founderId = claim['founderId'];
  final itemId = claim['itemId'];
  
  // If the current user is the founder, don't show "Found by: You"
  if (founderId == currentUserId) {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'You found this item',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
  
  // Otherwise, show the actual founder's name
  return FutureBuilder<String>(
    future: _resolveFounderDisplayNameVerbose(founderId, itemId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text('Loading founder...', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        );
      }
      
      String founderName = 'Unknown Founder';
      if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty && snapshot.data != 'Unknown') {
        founderName = snapshot.data!;
      }
      
      return Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Found by $founderName',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildFounderAdditionalInfo(Map<String, dynamic> claim) {
    final claimerName = claim['claimerName'] ?? claim['claimerEmail'] ?? 'Unknown';
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Claimed by $claimerName',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // =============================================
  // CTA BUTTONS BASED ON STATUS
  // =============================================
  Widget _buildCTAButtons(
    Map<String, dynamic> claim,
    bool isMyClaims,
    String status,
    Color statusColor,
  ) {
    if (isMyClaims) {
      return _buildMyClaimsCTA(claim, status, statusColor);
    } else {
      return _buildFoundClaimsCTA(claim, status, statusColor);
    }
  }

  Widget _buildMyClaimsCTA(Map<String, dynamic> claim, String status, Color statusColor) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final claimerId = claim['claimerId'];
    
    // Ensure this is actually the user's claim
    if (currentUserId != claimerId) {
      return const SizedBox.shrink();
    }
    
    switch (status) {
      case 'pending':
        // No detail view for pending claims
        return const SizedBox.shrink();
      
      case 'approved':
        return _buildSingleCTA(
          label: 'Pickup Details',
          icon: Icons.location_on_outlined,
          color: statusColor,
          onTap: () => _navigateToDetails(claim),
        );
      
      case 'rejected':
        // No detail view for rejected claims
        return const SizedBox.shrink();
      
      case 'completed':
        // No detail view for completed claims
        return const SizedBox.shrink();
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFoundClaimsCTA(Map<String, dynamic> claim, String status, Color statusColor) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final founderId = claim['founderId'];
    
    switch (status) {
      case 'pending':
        // Needs Review - show review button (only if user is founder)
        if (currentUserId != founderId) {
          return const SizedBox.shrink();
        }
        return _buildSingleCTA(
          label: 'Review Claim',
          icon: Icons.rate_review_outlined,
          color: statusColor,
          onTap: () => _navigateToReview(claim),
        );
      
      case 'approved':
        // Awaiting Return - show both Confirm Return and View Details (only if user is founder)
        if (currentUserId != founderId) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: ClaimsButton(
                  label: 'Confirm Return',
                  icon: Icons.check_circle_outline,
                  type: ClaimsButtonType.approve,
                  onPressed: () => _navigateToConfirmReturn(claim),
                  isFullWidth: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClaimsButton(
                  label: 'View Details',
                  icon: Icons.info_outline,
                  type: ClaimsButtonType.primary,
                  onPressed: () => _navigateToDetails(claim),
                  isFullWidth: false,
                ),
              ),
            ],
          ),
        );
      
      case 'rejected':
        // No detail view for rejected claim requests
        return const SizedBox.shrink();
      
      case 'completed':
        // No detail view for completed claim requests
        return const SizedBox.shrink();
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSingleCTA({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    // Determine button type based on action
    ClaimsButtonType buttonType;
    if (label.contains('Approve') || label.contains('Confirm')) {
      buttonType = ClaimsButtonType.approve;
    } else if (label.contains('Reject')) {
      buttonType = ClaimsButtonType.reject;
    } else if (outlined) {
      buttonType = ClaimsButtonType.secondary;
    } else {
      buttonType = ClaimsButtonType.primary;
    }

    return ClaimsButton(
      label: label,
      icon: icon,
      onPressed: onTap,
      type: buttonType,
      isFullWidth: true,
    );
  }

  void _navigateToDetails(Map<String, dynamic> claim) {
    Navigator.push(
      context,
      SmoothPageRoute(page: ClaimDetailsPage(claimData: claim)),
    );
  }

  void _navigateToReview(Map<String, dynamic> claim) {
    Navigator.push(
      context,
      SmoothPageRoute(page: ClaimReviewPage(claimData: claim)),
    );
  }

  void _navigateToConfirmReturn(Map<String, dynamic> claim) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final founderId = claim['founderId'];
    
    // Validate that current user is the founder before navigation
    if (currentUserId != founderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only the item founder can confirm returns. Current: $currentUserId, Required: $founderId'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      SmoothPageRoute(page: ConfirmReturnPage(itemData: claim, claimId: claim['docId'])),
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
      decoration: ClaimsCardStyles.infoCard(ClaimsColors.pendingLight),
      child: Padding(
        padding: const EdgeInsets.all(ClaimsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Header
            Row(
              children: [
                ClaimsWidgets.thumbnail(
                  placeholderIcon: Icons.badge,
                  size: 56,
                ),
                const SizedBox(width: ClaimsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ClaimsTypography.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: ClaimsSpacing.xxs),
                      ClaimsWidgets.infoRow(
                        icon: Icons.access_time,
                        text: submittedDate,
                        textStyle: ClaimsTypography.caption,
                      ),
                      if (claimedBy.isNotEmpty) ...[
                        const SizedBox(height: ClaimsSpacing.xxs),
                        ClaimsWidgets.infoRow(
                          icon: Icons.person_outline,
                          text: claimerEmail != null && claimerEmail.isNotEmpty
                              ? '$claimedBy • $claimerEmail'
                              : claimedBy,
                          textStyle: ClaimsTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: ClaimsSpacing.sm),

            // Compact Description
            Container(
              padding: const EdgeInsets.all(ClaimsSpacing.sm),
              decoration: BoxDecoration(
                color: ClaimsColors.pending.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: ClaimsColors.pending.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ClaimsColors.pending,
                    size: 16,
                  ),
                  const SizedBox(width: ClaimsSpacing.xs),
                  Expanded(
                    child: Text(
                      claimDescription,
                      style: ClaimsTypography.caption.copyWith(
                        color: ClaimsColors.pending,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ClaimsSpacing.sm),

            // Review Claim Button
            ClaimsButton(
              label: 'Review Claim',
              icon: Icons.rate_review,
              type: ClaimsButtonType.review,
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
              padding: EdgeInsets.all(ClaimsSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Information
                  Container(
                    padding: EdgeInsets.all(ClaimsSpacing.sm),
                    decoration: ClaimsCardStyles.compactCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact Information', style: ClaimsTypography.bodyBold),
                        SizedBox(height: ClaimsSpacing.xs),
                        ClaimsWidgets.infoRow(icon: Icons.person, text: seekerName),
                        SizedBox(height: ClaimsSpacing.xxs),
                        ClaimsWidgets.infoRow(icon: Icons.phone, text: seekerPhone),
                        SizedBox(height: ClaimsSpacing.xxs),
                        ClaimsWidgets.infoRow(icon: Icons.email, text: seekerEmail),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ClaimsSpacing.sm),
                  
                  // Pickup Location
                  Container(
                    padding: EdgeInsets.all(ClaimsSpacing.sm),
                    decoration: ClaimsCardStyles.compactCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup Location', style: ClaimsTypography.bodyBold),
                        SizedBox(height: ClaimsSpacing.xs),
                        ClaimsWidgets.infoRow(icon: Icons.location_on, text: pickupLocation),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Return Button
                  ClaimsButton(
                    label: 'Confirm Return',
                    icon: Icons.check_circle,
                    type: ClaimsButtonType.approve,
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
                            claimId: id,
                          ),
                        ),
                      );
                    },
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
              padding: EdgeInsets.fromLTRB(ClaimsSpacing.md, 0, ClaimsSpacing.md, ClaimsSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaimsWidgets.divider(),
                  SizedBox(height: ClaimsSpacing.sm),
                  
                  // Your Claim Request section
                  Text(
                    'Your Claim Request',
                    style: ClaimsTypography.subtitle,
                  ),
                  SizedBox(height: ClaimsSpacing.sm),
                  
                  // Claim message
                  Container(
                    padding: EdgeInsets.all(ClaimsSpacing.sm),
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
                      style: ClaimsTypography.body.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: ClaimsSpacing.xs),
                  
                  // Submitted date
                  Text(
                    'Submitted:',
                    style: ClaimsTypography.caption,
                  ),
                  
                  if (approvedDate != null) ...[
                    Text(
                      'Approved: $approvedDate',
                      style: ClaimsTypography.caption,
                    ),
                  ],
                  
                  SizedBox(height: ClaimsSpacing.md),
                  
                  // Status-specific message
                  if (isPending)
                    Container(
                      padding: EdgeInsets.all(ClaimsSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            color: ClaimsColors.pending,
                            size: 20,
                          ),
                          SizedBox(width: ClaimsSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Under Review',
                                  style: ClaimsTypography.bodyBold.copyWith(
                                    color: ClaimsColors.pending,
                                  ),
                                ),
                                SizedBox(height: ClaimsSpacing.xxs),
                                Text(
                                  'The finder is reviewing your claim request. You\'ll be notified once they make a decision.',
                                  style: ClaimsTypography.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (isApproved) ...[
                    Container(
                      padding: EdgeInsets.all(ClaimsSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: ClaimsColors.info,
                            size: 20,
                          ),
                          SizedBox(width: ClaimsSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Claim Approved!',
                                  style: ClaimsTypography.bodyBold.copyWith(
                                    color: ClaimsColors.info,
                                  ),
                                ),
                                SizedBox(height: ClaimsSpacing.xxs),
                                Text(
                                  'Your claim has been approved. Please follow the pickup instructions to collect your item.',
                                  style: ClaimsTypography.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: ClaimsSpacing.sm),
                    
                    // Pickup location details
                    Container(
                      padding: EdgeInsets.all(ClaimsSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ClaimsColors.info,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup Instructions', style: ClaimsTypography.bodyBold),
                          SizedBox(height: ClaimsSpacing.xs),
                          ClaimsWidgets.infoRow(icon: Icons.location_on, text: pickupLocation ?? 'TBD'),
                          SizedBox(height: ClaimsSpacing.xxs),
                          ClaimsWidgets.infoRow(icon: Icons.info_outline, text: 'Visit the Library information desk during library hours with a valid ID.'),
                        ],
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
