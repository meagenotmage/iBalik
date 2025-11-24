import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'lost_item_service.dart';

/// Service to automatically clean up old items to stay within Cloudinary free tier
/// Also works to keep Firestore database clean
class StorageCleanupService {
  final LostItemService _lostItemService = LostItemService();
  static const String _lastCleanupKey = 'last_storage_cleanup';
  static const int _cleanupIntervalDays = 7; // Run cleanup weekly
  
  /// Check if cleanup is needed and run it
  Future<void> checkAndRunCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getString(_lastCleanupKey);
      
      bool shouldRunCleanup = false;
      
      if (lastCleanup == null) {
        // First time - run cleanup
        shouldRunCleanup = true;
      } else {
        final lastCleanupDate = DateTime.parse(lastCleanup);
        final daysSinceCleanup = DateTime.now().difference(lastCleanupDate).inDays;
        
        if (daysSinceCleanup >= _cleanupIntervalDays) {
          shouldRunCleanup = true;
        }
      }
      
      if (shouldRunCleanup) {
        await runCleanup();
      }
    } catch (e) {
      print('Error checking cleanup: $e');
    }
  }
  
  /// Run the storage cleanup
  Future<Map<String, int>> runCleanup() async {
    try {
      print('Running storage cleanup...');
      
      // Delete items older than 90 days (unclaimed)
      // Delete returned items older than 30 days
      final result = await _lostItemService.cleanupStorage(
        oldItemsDays: 90,
        returnedItemsDays: 30,
      );
      
      // Save cleanup timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
      
      print('Cleanup complete: ${result['totalDeleted']} items deleted');
      print('  - Old unclaimed items: ${result['oldItemsDeleted']}');
      print('  - Returned items: ${result['returnedItemsDeleted']}');
      
      return result;
    } catch (e) {
      print('Error running cleanup: $e');
      return {'oldItemsDeleted': 0, 'returnedItemsDeleted': 0, 'totalDeleted': 0};
    }
  }
  
  /// Manually trigger cleanup (for admin or settings page)
  Future<Map<String, int>> manualCleanup({
    int oldItemsDays = 90,
    int returnedItemsDays = 30,
  }) async {
    final result = await _lostItemService.cleanupStorage(
      oldItemsDays: oldItemsDays,
      returnedItemsDays: returnedItemsDays,
    );
    
    // Update last cleanup time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
    
    return result;
  }
  
  /// Get last cleanup date
  Future<DateTime?> getLastCleanupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getString(_lastCleanupKey);
      
      if (lastCleanup != null) {
        return DateTime.parse(lastCleanup);
      }
      return null;
    } catch (e) {
      print('Error getting last cleanup date: $e');
      return null;
    }
  }
  
  /// Get days until next cleanup
  Future<int> getDaysUntilNextCleanup() async {
    final lastCleanup = await getLastCleanupDate();
    
    if (lastCleanup == null) {
      return 0; // Cleanup needed now
    }
    
    final daysSinceCleanup = DateTime.now().difference(lastCleanup).inDays;
    final daysUntilNext = _cleanupIntervalDays - daysSinceCleanup;
    
    return daysUntilNext < 0 ? 0 : daysUntilNext;
  }
}
