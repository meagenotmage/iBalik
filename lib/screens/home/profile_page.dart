import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_widgets.dart';
import '../../services/activity_service.dart';
import '../../services/game_service.dart';
import '../../services/game_data_service.dart';
import '../posts/posts_page.dart';
import '../game/game_hub_page.dart';
import '../game/leaderboards_page.dart';
import '../game/challenges_page.dart';
import '../claims/claims_page.dart';
import '../auth/login_page.dart';
import '../store/points_store_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTabIndex = 0;
  int _selectedIndex = 4; // Profile tab is selected
  final GameService _gameService = GameService(); // Add GameService instance
  final GameDataService _gameDataService = GameDataService(); // Add GameDataService instance

  // User data
  String userName = 'username';
  String department = 'CICT';
  String course = 'BS Information Technology';
  String year = '3rd Year';
  String bio = 'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!';
  String? profileImageUrl;

  // Stats (real data from Firestore)
  int _userRank = 0; // Calculated from leaderboard
  int _itemsReturned = 0;
  int _currentStreak = 0;
  bool _statsLoading = true;

  // Settings state
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool claimNotifications = true;
  bool publicProfile = true;
  bool showStatistics = true;

  // Department to courses mapping
  final Map<String, List<String>> _departmentCourses = {
    'College of Information and Communications Technology': [
      'BS Information Technology',
      'BS Computer Science',
      'BS Information Systems',
      'BS Entertainment and Multimedia Computing',
      'BS Library and Information Science',
    ],
    'College of Nursing': [
      'BS Nursing',
    ],
    'College of Law': [
      'Juris Doctor',
    ],
    'College of Education': [
      'BS Education - Elementary',
      'BS Education - Secondary',
      'BS Physical Education',
      'BS Special Education',
      'Bachelor of Early Childhood Education',
    ],
    'College of Business and Management': [
      'BS Business Administration',
      'BS in Office Administration',
      'BS in Hospitality Management',
    ],
    'College of PESCAR': [
      'BS in Sports Science',
      'BS in Physical Education',
    ],
    'College of Communications': [
      'BS in Development Communication',
      'BS in Broadcasting',
      'BS in Journalism',
    ],
    'College of Medicine': [
      'Doctor of Medicine',
    ],
    'College of Arts and Sciences': [
      'BS Psychology',
      'BS Biology',
      'BS Chemistry',
      'BS Mathematics',
      'BS Social Work',
      'AB in Political Science',
      'AB in English',
    ],
    'College of Dentistry': [
      'Doctor of Dental Medicine',
    ],
  };

  // Available options for dropdowns
  final List<String> departments = [
    'College of Information and Communications Technology',
    'College of Nursing',
    'College of Law',
    'College of Education',
    'College of Business and Management',
    'College of PESCAR',
    'College of Communications',
    'College of Medicine',
    'College of Arts and Sciences',
    'College of Dentistry',
  ];

  final List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _gameService.dispose();
    super.dispose();
  }

  /// Calculate user's rank based on karma leaderboard
  Future<void> _calculateUserRank() async {
    try {
      final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get the user's karma
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userKarma = (userDoc.data()?['karma'] as num?)?.toInt() ?? 0;

      // Count users with higher karma
      final higherKarmaQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('karma', isGreaterThan: userKarma)
          .count()
          .get();

      setState(() {
        _userRank = (higherKarmaQuery.count ?? 0) + 1;
        _statsLoading = false;
      });
    } catch (e) {
      debugPrint('Error calculating user rank: $e');
      setState(() {
        _userRank = 0;
        _statsLoading = false;
      });
    }
  }

 Future<void> _loadUserData() async {
  try {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          final username = data['username'] as String?;
          final fullName = data['name'] as String?;
          userName =
              username ??
              fullName ??
              user.displayName ??
              user.email?.split('@').first ??
              'User Name';

          // Handle department mapping - convert "CICT" to full name
          final storedDept = (data['department'] as String?) ?? 'CICT';
          department = _mapDepartmentToFullName(storedDept);
          
          course = (data['course'] as String?) ?? 'BS Information Technology';
          year = (data['year'] as String?) ?? '3rd Year';
          bio = (data['bio'] as String?) ?? 
                'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!';
          profileImageUrl = data['profileImageUrl'] as String?;
          // Load real stats from Firestore
          _itemsReturned = (data['itemsReturned'] as int?) ?? (data['returned'] as int?) ?? 0;
          _currentStreak = (data['currentStreak'] as int?) ?? (data['streak'] as int?) ?? 0;
          
          // Calculate user rank asynchronously
          _calculateUserRank();

          // Create sample activities for new users
          _createSampleActivities();

          // Load settings
          final settings = data['settings'] as Map<String, dynamic>?;
          final notifications = settings?['notifications'] as Map<String, dynamic>?;
          final privacy = settings?['privacy'] as Map<String, dynamic>?;

          pushNotifications = notifications?['pushNotifications'] as bool? ?? true;
          emailNotifications = notifications?['emailNotifications'] as bool? ?? true;
          claimNotifications = notifications?['claimNotifications'] as bool? ?? true;
          publicProfile = privacy?['publicProfile'] as bool? ?? true;
          showStatistics = privacy?['showStatistics'] as bool? ?? true;
        });
      } else {
        _createUserDocument(user);
      }
    }
  } catch (e) {
    debugPrint('Error loading user data: $e');
    setState(() {
      userName = 'User Name';
      department = 'College of Information and Communications Technology';
      course = 'BS Information Technology';
      year = '3rd Year';
      bio = 'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!';
    });
  }
}

 Future<void> _createUserDocument(firebase_auth.User user) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'username': user.displayName ?? user.email?.split('@').first ?? 'User',
      'department': 'College of Information and Communications Technology', // Use full name
      'course': 'BS Information Technology',
      'year': '3rd Year',
      'bio': 'Passionate about helping the WVSU community. Always happy to help reunite lost items with their owners!',
      // karma, points, and level will be initialized by GameService
      'itemsReturned': 0,
      'currentStreak': 0,
      'itemsPosted': 0,
      'settings': {
        'notifications': {
          'pushNotifications': true,
          'emailNotifications': true,
          'claimNotifications': true,
        },
        'privacy': {
          'publicProfile': true,
          'showStatistics': true,
        }
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error creating user document: $e');
  }
}

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadImageToSupabase(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadImageToSupabase(File imageFile) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if Supabase is initialized
      try {
        final supabase = Supabase.instance.client;
        supabase.auth.currentSession;
      } catch (e) {
        debugPrint('Supabase not initialized: $e');
        _showSnackBar('Storage service not available');
        return;
      }

      _showSnackBar('Uploading image...');

      // Read file as bytes for Supabase upload
      final fileBytes = await imageFile.readAsBytes();
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabase = Supabase.instance.client;
      
      // Upload to Supabase Storage using bytes
      await supabase.storage
          .from('profile-images')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Get public URL
      final imageUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Update Firestore with the new image URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': imageUrl,
      });

      // Update local state
      setState(() {
        profileImageUrl = imageUrl;
      });

      _showSnackBar('Profile image updated successfully!');
    } catch (e) {
      debugPrint('Error uploading image to Supabase: $e');
      _showSnackBar('Error uploading image: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);
    final TextEditingController bioController = TextEditingController(text: bio);
    
    // Use local state for the dialog
    String selectedDepartment = department;
    String selectedCourse = course;
    String selectedYear = year;
    
    // Initialize available courses for the dialog
    List<String> availableCourses = _departmentCourses[selectedDepartment] ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper function to update courses when department changes
          void updateCourses(String newDepartment) {
            final newCourses = _departmentCourses[newDepartment] ?? [];
            setDialogState(() {
              availableCourses = newCourses;
              // Reset course if it's not in the new department's courses
              if (!newCourses.contains(selectedCourse)) {
                selectedCourse = newCourses.isNotEmpty ? newCourses.first : '';
              }
            });
          }

          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image Upload
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.lightGray,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Department Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: departments.map((String dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedDepartment = newValue;
                        });
                        // Update available courses when department changes
                        updateCourses(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Course Dropdown (dynamically filtered by department)
                  DropdownButtonFormField<String>(
                    initialValue: availableCourses.contains(selectedCourse) ? selectedCourse : null,
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      border: OutlineInputBorder(),
                    ),
                    items: availableCourses.map((String crs) {
                      return DropdownMenuItem<String>(
                        value: crs,
                        child: Text(crs),
                      );
                    }).toList(),
                    onChanged: availableCourses.isNotEmpty ? (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedCourse = newValue;
                        });
                      }
                    } : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a course';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Year Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((String yr) {
                      return DropdownMenuItem<String>(
                        value: yr,
                        child: Text(yr),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedYear = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Bio Field
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate that a course is selected
                  if (selectedCourse.isEmpty) {
                    _showSnackBar('Please select a course');
                    return;
                  }
                  
                  await _updateProfile(
                    nameController.text,
                    selectedDepartment,
                    selectedCourse,
                    selectedYear,
                    bioController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

Future<void> _recordUserActivity({
  required String type,
  required String title,
  required String description,
  Map<String, dynamic>? metadata,
}) async {
  try {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .add({
      'type': type,
      'title': title,
      'description': description,
      'metadata': metadata ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Keep only the last 50 activities to prevent unlimited growth
    final activitiesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .get();

    if (activitiesSnapshot.docs.length > 50) {
      // Sort by timestamp and delete oldest
      final activities = activitiesSnapshot.docs;
      activities.sort((a, b) {
        final aTime = a.data()['timestamp'] as Timestamp?;
        final bTime = b.data()['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      final activitiesToDelete = activities.sublist(50);
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in activitiesToDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  } catch (e) {
    debugPrint('Error recording activity: $e');
  }
}

/// Create a test activity to verify the system is working
Future<void> _createTestActivity() async {
  try {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .add({
      'type': 'profileUpdated',
      'title': 'Activity Test',
      'description': 'Testing activity log functionality - ${DateTime.now().toString()}',
      'metadata': {'test': true},
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint('Test activity created successfully');
  } catch (e) {
    debugPrint('Error creating test activity: $e');
  }
}

/// Create some sample activities for new users to showcase the feature
Future<void> _createSampleActivities() async {
  try {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user already has activities
    final existingActivities = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .limit(1)
        .get();

    if (existingActivities.docs.isNotEmpty) {
      return; // User already has activities, don't create samples
    }

    // Create sample activities with different timestamps
    final now = DateTime.now();
    final activities = [
      {
        'type': 'accountCreated',
        'title': 'Welcome to iBalik!',
        'description': 'Your account has been created successfully',
        'metadata': {'userName': userName},
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'type': 'profileUpdated',
        'title': 'Profile Completed',
        'description': 'Added profile information and bio',
        'metadata': {},
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final activity in activities) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .doc();
      batch.set(docRef, activity);
    }

    await batch.commit();
  } catch (e) {
    debugPrint('Error creating sample activities: $e');
  }
}

Future<void> _updateProfile(
  String newName,
  String newDepartment,
  String newCourse,
  String newYear,
  String newBio,
) async {
  try {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'username': newName,
      'department': newDepartment,
      'course': newCourse,
      'year': newYear,
      'bio': newBio,
    });

    setState(() {
      userName = newName;
      department = newDepartment;
      course = newCourse;
      year = newYear;
      bio = newBio;
    });

    // Record activity using ActivityService for consistency
    final activityService = ActivityService();
    await activityService.recordProfileUpdated();

    _showSnackBar('Profile updated successfully!');
  } catch (e) {
    debugPrint('Error updating profile: $e');
    _showSnackBar('Error updating profile: $e');
  }
}

  // Helper to map department abbreviations to full names
  String _mapDepartmentToFullName(String dept) {
    switch (dept) {
      case 'CICT':
        return 'College of Information and Communications Technology';
      default:
        return dept;
    }
  }

  // Settings Methods
  Future<void> _updateNotificationSettings(String setting, bool value) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'settings.notifications.$setting': value,
      });

      _showSnackBar('Notification settings updated');
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      _showSnackBar('Error updating settings');
    }
  }

  Future<void> _updatePrivacySettings(String setting, bool value) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'settings.privacy.$setting': value,
      });

      _showSnackBar('Privacy settings updated');
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      _showSnackBar('Error updating settings');
    }
  }

  void _exportUserData() {
    _showSnackBar('Preparing your data for export...');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Your data export is being prepared. You will receive a download link via email when it\'s ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'How to post a found item?',
                'Go to the Posts tab and tap the + button to post a found item with details and photos.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'How to claim an item?',
                'Browse items in the Posts tab, tap on an item to view details, and use the Claim button.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'What are karma points?',
                'Karma points are earned by helping others find their lost items and being an active community member.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Need more help? Contact us:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('support@lostandfound.wvsu.edu.ph'),
              const Text('(033) 123-4567'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Lost & Found WVSU'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lost & Found WVSU',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'A community-driven platform for West Visayas State University students and staff to help reunite lost items with their owners.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('Post found items with photos'),
              _buildFeatureItem('Claim lost items securely'),
              _buildFeatureItem('Gamification with points and badges'),
              _buildFeatureItem('Real-time notifications'),
              _buildFeatureItem('Community karma system'),
              const SizedBox(height: 16),
              const Text(
                'Developed with ❤️ for the WVSU Community',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'By using Lost & Found WVSU, you agree to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTermItem('Post accurate and truthful information about found items'),
              _buildTermItem('Respect other users\' privacy and personal information'),
              _buildTermItem('Not post inappropriate or offensive content'),
              _buildTermItem('Return found items to their rightful owners promptly'),
              _buildTermItem('Use the platform for its intended purpose only'),
              const SizedBox(height: 12),
              const Text(
                'The university reserves the right to suspend accounts that violate these terms.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'We value your privacy and are committed to protecting your personal information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPolicyItem('We collect only necessary information for the app to function'),
              _buildPolicyItem('Your personal data is stored securely and not shared with third parties'),
              _buildPolicyItem('Photos and item descriptions are visible only to the WVSU community'),
              _buildPolicyItem('You can control your privacy settings in this settings tab'),
              _buildPolicyItem('You can request data deletion by contacting support'),
              const SizedBox(height: 12),
              const Text(
                'For questions about our privacy practices, contact our data protection officer.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String term) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(term)),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String policy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(policy)),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

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
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified Profile Section
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.medium,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // User Profile Section
                        Row(
                          children: [
                            // Profile Picture with Upload Capability
                            GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.xl),
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 3,
                                      ),
                                      boxShadow: AppShadows.medium,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(17),
                                      child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: profileImageUrl!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => ShimmerWidgets.imagePlaceholder(
                                                width: 64,
                                                height: 64,
                                                borderRadius: BorderRadius.circular(17),
                                              ),
                                              errorWidget: (context, url, error) => Icon(
                                                Icons.person,
                                                size: 32,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 32,
                                              color: Colors.grey[400],
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Color(0xFF4CAF50),
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    left: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            
                            // User Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName.isNotEmpty ? userName : 'User Name',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$department • $year',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    course,
                                    style: TextStyle(
                                      color: AppColors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Edit Button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: AppColors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showEditProfileDialog,
                                  borderRadius: BorderRadius.circular(AppRadius.standard),
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.white,
                                      size: AppIconSize.md,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Primary Stats Row
                        ListenableBuilder(
                          listenable: _gameService,
                          builder: (context, child) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        icon: Icons.star_rounded,
                                        value: _gameService.karma.toString(),
                                        label: 'Karma',
                                        subtitle: 'Community Score',
                                        color: AppColors.secondary,
                                        isPrimary: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            SmoothPageRoute(page: PointsStorePage()),
                                          );
                                        },
                                        child: _buildCompactStatCard(
                                          icon: Icons.bolt_rounded,
                                          value: _gameService.points.toString(),
                                          label: 'Points',
                                          subtitle: 'Exchange Points',
                                          color: AppColors.primary,
                                          isPrimary: true,
                                          isTappable: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppSpacing.sm),
                                
                                // Secondary Stats Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        icon: Icons.emoji_events_rounded,
                                        value: _statsLoading ? '...' : '#$_userRank',
                                        label: 'Rank',
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        icon: Icons.autorenew_rounded,
                                        value: _itemsReturned.toString(),
                                        label: 'Returned',
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        icon: Icons.local_fire_department_rounded,
                                        value: _currentStreak.toString(),
                                        label: 'Streak',
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        icon: Icons.star_border_rounded,
                                        value: 'Lv ${_gameService.currentLevel}',
                                        label: 'Level',
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bio Section
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.lightGray.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: AppIconSize.md,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Navigation
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.lightGray.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTab('Overview', 0)),
                      Expanded(child: _buildTab('Activity', 1)),
                      Expanded(child: _buildTab('Settings', 2)),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                
                // Tab Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildTabContent(),
                ),
                
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
                _buildNavItem(Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String value,
    required String label,
    String? subtitle,
    required Color color,
    bool isPrimary = false,
    bool isTappable = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isPrimary ? AppSpacing.md : AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: isTappable ? color : color.withOpacity(0.2),
          width: isTappable ? 2 : 1,
        ),
        boxShadow: AppShadows.standard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isPrimary ? AppIconSize.lg : AppIconSize.md,
          ),
          SizedBox(height: isPrimary ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isPrimary ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isPrimary ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isPrimary && subtitle != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isTappable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textTertiary,
                    size: 8,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedTabIndex = index;
        });
        
        // If Activity tab is selected, create a test activity
        if (index == 2) {
          await _createTestActivity();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isSelected ? Border.all(
            color: AppColors.primary.withOpacity(0.2),
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

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildOverviewTab();
    } else if (_selectedTabIndex == 1) {
      return _buildActivityTab();
    } else {
      return _buildSettingsTab();
    }
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions Grid
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Game Hub',
                Icons.emoji_events,
                const LinearGradient(
                  colors: [AppColors.black, AppColors.black],
                ),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const GameHubPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'My Posts',
                Icons.inventory_2,
                const LinearGradient(
                  colors: [AppColors.black, AppColors.black],
                ),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const PostsPage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Leaderboard',
                Icons.people,
                const LinearGradient(
                  colors: [AppColors.black, AppColors.black],
                ),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const LeaderboardsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Challenges',
                Icons.track_changes,
                const LinearGradient(
                  colors: [AppColors.black, AppColors.black],
                ),
                () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const ChallengesPage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              color: label == 'Game Hub' || label == 'Challenges' 
                ? AppColors.secondary 
                : AppColors.primary, 
              size: 28
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }











  Widget _buildBadgeCard({
    required IconData icon,
    required String name,
    required String description,
    required Color color,
    required Color bgColor,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked ? Colors.grey[300]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isLocked ? Colors.grey[400] : color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey[500] : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Activity Tab - Shows user's recent actions (limited to 50 items or 3 months)
  Widget _buildActivityTab() {
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      return _buildActivityEmptyState(
        icon: Icons.person_off,
        title: 'Not signed in',
        subtitle: 'Please sign in to view your activity',
      );
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildActivityEmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            subtitle: 'Unable to load activities',
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildActivityEmptyState(
            icon: Icons.history,
            title: 'No activity yet',
            subtitle: 'Your actions will appear here as you use iBalik',
          );
        }

        // Get activities and sort them client-side
        final allActivities = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort by timestamp (newest first) and filter by date
        final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
        final recentActivities = allActivities.where((activity) {
          final timestamp = activity['timestamp'] as Timestamp?;
          if (timestamp == null) return false;
          return timestamp.toDate().isAfter(threeMonthsAgo);
        }).toList();
        
        recentActivities.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (recentActivities.isEmpty) {
          return _buildActivityEmptyState(
            icon: Icons.history,
            title: 'No recent activity',
            subtitle: 'Your actions from the last 3 months will appear here',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with count and refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${recentActivities.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {}), // Trigger rebuild
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Last 3 months',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${allActivities.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Activity list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                itemBuilder: (context, index) {
                  final activity = recentActivities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityCard(activity: activity),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Empty state for activity tab
  Widget _buildActivityEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Activity card with gamified styling
  Widget _buildActivityCard({
    required Map<String, dynamic> activity,
  }) {
    final String type = activity['type'] ?? 'general';
    final String title = activity['title'] ?? '';
    final String description = activity['description'] ?? '';
    final Timestamp? timestamp = activity['timestamp'] as Timestamp?;
    final DateTime time = timestamp?.toDate() ?? DateTime.now();
    final int? karmaChange = activity['karmaChange'] as int?;
    final int? pointsChange = activity['pointsChange'] as int?;
    
    // Get styling from ActivityService
    final style = ActivityService.getActivityStyle(type);
    final iconColor = Color(style['iconColor'] as int);
    final bgColor = Color(style['bgColor'] as int);
    final iconData = _getActivityIcon(style['icon'] as String);
    final timeAgo = _getTimeAgo(time);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Bottom row: time + rewards
                Row(
                  children: [
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (karmaChange != null && karmaChange != 0) ...[
                      const SizedBox(width: 8),
                      _buildRewardBadge(
                        value: karmaChange,
                        label: 'karma',
                        color: const Color(0xFFEC4899),
                      ),
                    ],
                    if (pointsChange != null && pointsChange != 0) ...[
                      const SizedBox(width: 6),
                      _buildRewardBadge(
                        value: pointsChange,
                        label: 'pts',
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small badge showing karma/points earned
  Widget _buildRewardBadge({
    required int value,
    required String label,
    required Color color,
  }) {
    final isPositive = value > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? '+' : ''}$value $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Get icon data from string name
  IconData _getActivityIcon(String iconName) {
    final iconMap = {
      'add_box': Icons.add_box,
      'assignment': Icons.assignment,
      'check_circle': Icons.check_circle,
      'cancel': Icons.cancel,
      'rate_review': Icons.rate_review,
      'celebration': Icons.celebration,
      'emoji_events': Icons.emoji_events,
      'flag': Icons.flag,
      'trending_up': Icons.trending_up,
      'star': Icons.star,
      'monetization_on': Icons.monetization_on,
      'redeem': Icons.redeem,
      'person': Icons.person,
      'person_add': Icons.person_add,
      'history': Icons.history,
    };
    return iconMap[iconName] ?? Icons.history;
  }

  Widget _buildSettingsTab() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications Section
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildSettingItem(
                title: 'Push Notifications',
                subtitle: 'Get notified about claims and updates',
                hasSwitch: true,
                switchValue: pushNotifications,
                onSwitchChanged: (value) {
                  setState(() {
                    pushNotifications = value;
                  });
                  _updateNotificationSettings('pushNotifications', value);
                },
              ),
              
              _buildSettingItem(
                title: 'Email Notifications',
                subtitle: 'Receive emails for important updates',
                hasSwitch: true,
                switchValue: emailNotifications,
                onSwitchChanged: (value) {
                  setState(() {
                    emailNotifications = value;
                  });
                  _updateNotificationSettings('emailNotifications', value);
                },
              ),
              
              _buildSettingItem(
                title: 'Claim Notifications',
                subtitle: 'When someone claims your items',
                hasSwitch: true,
                switchValue: claimNotifications,
                onSwitchChanged: (value) {
                  setState(() {
                    claimNotifications = value;
                  });
                  _updateNotificationSettings('claimNotifications', value);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Privacy Section
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildSettingItem(
                title: 'Public Profile',
                subtitle: 'Allow others to view your profile',
                hasSwitch: true,
                switchValue: publicProfile,
                onSwitchChanged: (value) {
                  setState(() {
                    publicProfile = value;
                  });
                  _updatePrivacySettings('publicProfile', value);
                },
              ),
              
              _buildSettingItem(
                title: 'Show Statistics',
                subtitle: 'Display your stats on leaderboards',
                hasSwitch: true,
                switchValue: showStatistics,
                onSwitchChanged: (value) {
                  setState(() {
                    showStatistics = value;
                  });
                  _updatePrivacySettings('showStatistics', value);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Account Section
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildSettingItem(
                title: 'Export My Data',
                hasArrow: true,
                onTap: _exportUserData,
              ),
              
              _buildSettingItem(
                title: 'Help & Support',
                hasArrow: true,
                onTap: _showHelpAndSupport,
              ),

              _buildSettingItem(
                title: 'About App',
                hasArrow: true,
                onTap: _showAboutApp,
              ),

              _buildSettingItem(
                title: 'Terms of Service',
                hasArrow: true,
                onTap: _showTermsOfService,
              ),

              _buildSettingItem(
                title: 'Privacy Policy',
                hasArrow: true,
                onTap: _showPrivacyPolicy,
              ),
              
              const SizedBox(height: 16),
              
              // Sign Out Button
              InkWell(
                onTap: () async {
                  // Show confirmation dialog
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      // Sign out from Firebase
                      await firebase_auth.FirebaseAuth.instance.signOut();
                      
                      // Navigate to login page and remove all previous routes
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      // Show error message if sign out fails
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error signing out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    bool hasArrow = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: hasArrow ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: const Color(0xFF10B981),
              ),
            if (hasArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
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
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const PostsPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const GameHubPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, SmoothPageRoute(page: const ClaimsPage()));
        break;
      case 4:
        // Already on profile page
        break;
    }

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}