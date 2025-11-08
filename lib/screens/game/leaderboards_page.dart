import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenges_page.dart';
import '../../utils/page_transitions.dart';

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  String selectedCollege = 'All Colleges';
  String selectedTimePeriod = 'This Week';
  
  String userName = 'Loading...';
  String userInitials = 'YN';
  String? profilePictureUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          final username = data?['username'] as String?;
          final fullName = data?['name'] as String?;
          final profilePic = data?['profilePicture'] as String?;
          
          setState(() {
            // Use username if available, otherwise use full name
            userName = username ?? fullName ?? 'Your Name';
            userInitials = _getInitials(userName);
            profilePictureUrl = profilePic;
            isLoading = false;
          });
        } else {
          setState(() {
            userName = 'Your Name';
            userInitials = 'YN';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          userName = 'Your Name';
          userInitials = 'YN';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Your Name';
        userInitials = 'YN';
        isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'YN';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }

  // Top 3 users
  final List<Map<String, dynamic>> topThree = [
    {
      'rank': 2,
      'name': 'Juan Dela Cruz',
      'initials': 'JC',
      'karma': 423,
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'bgColor': Color(0xFF6B7280),
    },
    {
      'rank': 1,
      'name': 'Maria Santos',
      'initials': 'MS',
      'karma': 485,
      'badge': 'Campus Hero',
      'badgeIcon': Icons.military_tech,
      'bgColor': Color(0xFF1F2937),
    },
    {
      'rank': 3,
      'name': 'Anna Reyes',
      'initials': 'AR',
      'karma': 387,
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'bgColor': Color(0xFF9CA3AF),
    },
  ];

  // User's position
  final Map<String, dynamic> currentUser = {
    'name': 'Your Name',
    'rank': '#15',
    'karma': 125,
    'change': '+15',
    'changeLabel': 'karma this week',
    'initials': 'YN',
    'badge': 'Newcomer',
    'bgColor': Color(0xFF6B7280),
  };

  // Full rankings
  final List<Map<String, dynamic>> fullRankings = [
    {
      'rank': 1,
      'name': 'Maria Santos',
      'initials': 'MS',
      'department': 'Arts and Sciences',
      'badge': 'Campus Hero',
      'badgeIcon': Icons.military_tech,
      'badgeEmoji': '🏛️',
      'karma': 485,
      'karmaChange': '+76',
      'found': 15,
      'returned': 12,
      'bgColor': Color(0xFF1F2937),
    },
    {
      'rank': 2,
      'name': 'Juan Dela Cruz',
      'initials': 'JC',
      'department': 'Engineering and Technology',
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'badgeEmoji': '🔍',
      'karma': 423,
      'karmaChange': '+54',
      'found': 12,
      'returned': 10,
      'bgColor': Color(0xFF6B7280),
    },
    {
      'rank': 3,
      'name': 'Anna Reyes',
      'initials': 'AR',
      'department': 'Business and Management',
      'badge': 'Verified Finder',
      'badgeIcon': Icons.verified,
      'badgeEmoji': '🔍',
      'karma': 387,
      'karmaChange': '+43',
      'found': 11,
      'returned': 9,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 4,
      'name': 'Carlos Garcia',
      'initials': 'CG',
      'department': 'Education',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🙂',
      'karma': 312,
      'karmaChange': '+34',
      'found': 9,
      'returned': 8,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 5,
      'name': 'Lisa Chen',
      'initials': 'LC',
      'department': 'Arts and Sciences',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🔥',
      'karma': 298,
      'karmaChange': '+28',
      'found': 8,
      'returned': 7,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 6,
      'name': 'Miguel Torres',
      'initials': 'MT',
      'department': 'Agriculture and Forestry',
      'badge': 'Helper',
      'badgeIcon': Icons.emoji_emotions,
      'badgeEmoji': '🌱',
      'karma': 267,
      'karmaChange': '+23',
      'found': 7,
      'returned': 6,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 7,
      'name': 'Sofia Valdez',
      'initials': 'SV',
      'department': 'Nursing and Health Sciences',
      'badge': 'Newcomer',
      'badgeIcon': Icons.star,
      'badgeEmoji': '⭐',
      'karma': 198,
      'karmaChange': '+19',
      'found': 6,
      'returned': 5,
      'bgColor': Color(0xFF9CA3AF),
    },
    {
      'rank': 8,
      'name': 'David Kim',
      'initials': 'DK',
      'department': 'Engineering and Technology',
      'badge': 'Newcomer',
      'badgeIcon': Icons.star,
      'badgeEmoji': '⭐',
      'karma': 156,
      'karmaChange': '+12',
      'found': 5,
      'returned': 4,
      'bgColor': Color(0xFF9CA3AF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.black87,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Leaderboards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          selectedCollege,
                          ['All Colleges', 'Engineering', 'Arts and Sciences', 'Business'],
                          (value) => setState(() => selectedCollege = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Period',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          selectedTimePeriod,
                          ['This Week', 'This Month', 'All Time'],
                          (value) => setState(() => selectedTimePeriod = value!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current User Position Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: currentUser['bgColor'],
                        shape: BoxShape.circle,
                        image: profilePictureUrl != null
                            ? DecorationImage(
                                image: NetworkImage(profilePictureUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profilePictureUrl == null
                          ? Center(
                              child: Text(
                                userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${currentUser['rank']} • ${currentUser['karma']} karma',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser['badge'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Change indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                            Text(
                              currentUser['change'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currentUser['changeLabel'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Top 3 Podium
            _buildTopThreePodium(),

            const SizedBox(height: 24),

            // Full Rankings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Full Rankings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Full Rankings List
            ...fullRankings.map((user) => _buildRankingCard(user)),

            const SizedBox(height: 16),

            // View Active Challenges Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: const ChallengesPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'View Active Challenges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTopThreePodium() {
    // Reorder to show 2nd, 1st, 3rd
    final orderedTop = [topThree[0], topThree[1], topThree[2]];
    final heights = [140.0, 160.0, 120.0]; // Heights for 2nd, 1st, 3rd

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final user = orderedTop[index];
          final height = heights[index];
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: user['bgColor'],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user['initials'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge icon
                  Icon(
                    user['badgeIcon'],
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    user['name'].split(' ')[0],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    user['name'].split(' ').length > 1 
                        ? user['name'].split(' ').sublist(1).join(' ')
                        : '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Karma
                  Text(
                    '${user['karma']} karma',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Podium
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: user['bgColor'],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        user['rank'] == 1 ? Icons.workspace_premium : Icons.emoji_events,
                        color: Colors.white,
                        size: user['rank'] == 1 ? 40 : 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              // Rank
              SizedBox(
                width: 30,
                child: Text(
                  '#${user['rank']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: user['bgColor'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user['initials'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['badgeEmoji'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['department'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['badge'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Karma
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user['karma']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'karma',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: Color(0xFFEF4444),
                        size: 12,
                      ),
                      Text(
                        user['karmaChange'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            children: [
              const SizedBox(width: 30), // Align with name
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${user['found']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Found',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${user['returned']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Returned',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
