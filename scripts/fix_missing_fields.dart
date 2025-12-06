import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to add missing fields to existing user documents
/// Run with: dart run scripts/fix_missing_fields.dart
void main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  print('Fetching all users...');
  final usersSnapshot = await firestore.collection('users').get();
  
  print('Found ${usersSnapshot.docs.length} users');
  
  int updated = 0;
  int skipped = 0;
  
  for (var doc in usersSnapshot.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};
    
    // Check and add missing fields
    if (!data.containsKey('itemsPosted')) {
      updates['itemsPosted'] = 0;
    }
    if (!data.containsKey('itemsReturned')) {
      updates['itemsReturned'] = 0;
    }
    if (!data.containsKey('currentStreak')) {
      updates['currentStreak'] = 0;
    }
    
    if (updates.isNotEmpty) {
      print('Updating user ${doc.id} (${data['username']})...');
      await doc.reference.update(updates);
      updated++;
    } else {
      skipped++;
    }
  }
  
  print('\n✅ Migration complete!');
  print('   Updated: $updated users');
  print('   Skipped: $skipped users (already had all fields)');
}
