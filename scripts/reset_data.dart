import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script to reset posts, claims, and user game stats
/// Run with: dart run scripts/reset_data.dart
Future<void> main() async {
  print('🔧 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  try {
    print('\n📋 Starting data reset...');
    print('━' * 50);
    
    // 1. Delete all posts (lost_items collection)
    print('\n🗑️  Deleting posts...');
    final postsQuery = await firestore.collection('lost_items').get();
    int postsDeleted = 0;
    for (var doc in postsQuery.docs) {
      await doc.reference.delete();
      postsDeleted++;
    }
    print('✅ Deleted $postsDeleted posts');
    
    // 2. Delete all claims
    print('\n🗑️  Deleting claims...');
    final claimsQuery = await firestore.collection('claims').get();
    int claimsDeleted = 0;
    for (var doc in claimsQuery.docs) {
      await doc.reference.delete();
      claimsDeleted++;
    }
    print('✅ Deleted $claimsDeleted claims');
    
    // 3. Reset user stats (points, level, karma, xp, etc.)
    print('\n🔄 Resetting user game stats...');
    final usersQuery = await firestore.collection('users').get();
    int usersReset = 0;
    
    for (var doc in usersQuery.docs) {
      await doc.reference.update({
        // Reset game stats
        'points': 0,
        'level': 1,
        'karma': 0,
        'xp': 0,
        
        // Reset activity counts
        'itemsPosted': 0,
        'itemsReturned': 0,
        'returned': 0, // Legacy field
        'claimsMade': 0,
        'claimsApproved': 0,
        
        // Reset streak
        'currentStreak': 0,
        'streak': 0, // Legacy field
        'longestStreak': 0,
        
        // Reset badges and challenges
        'badgesEarned': 0,
        'challengesCompleted': 0,
      });
      
      // Delete user's badges subcollection
      final badgesQuery = await doc.reference.collection('badges').get();
      for (var badge in badgesQuery.docs) {
        await badge.reference.delete();
      }
      
      // Delete user's challenges subcollection
      final challengesQuery = await doc.reference.collection('challenges').get();
      for (var challenge in challengesQuery.docs) {
        await challenge.reference.delete();
      }
      
      usersReset++;
      print('  ✓ Reset stats for user ${doc.id}');
    }
    print('✅ Reset $usersReset users');
    
    // Summary
    print('\n' + '━' * 50);
    print('✨ Data reset complete!');
    print('━' * 50);
    print('📊 Summary:');
    print('  • Posts deleted: $postsDeleted');
    print('  • Claims deleted: $claimsDeleted');
    print('  • Users reset: $usersReset');
    print('\n✅ All data cleared successfully!');
    print('\n⚠️  Note: User accounts, profiles, and activities remain intact.');
    
  } catch (e) {
    print('\n❌ Error during reset: $e');
    print('Please check your Firebase connection and try again.');
  }
}
