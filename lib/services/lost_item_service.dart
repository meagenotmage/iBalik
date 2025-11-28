import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'supabase_storage_service.dart';
import 'notification_service.dart';
import 'activity_service.dart';

class LostItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseStorageService _storage = SupabaseStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _lostItemsCollection =>
      _firestore.collection('lost_items');

  /// Upload image to Supabase Storage (mobile/desktop only)
  Future<String> uploadItemImage(File imageFile, String itemId) async {
    if (kIsWeb) {
      throw UnsupportedError('Use uploadItemImageBytes for web');
    }
    try {
      return await _storage.uploadImage(
        imageFile: imageFile,
        itemId: itemId,
        type: 'posts',
      );
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image bytes to Supabase Storage (works on all platforms)
  Future<String> uploadItemImageBytes(
    Uint8List imageBytes,
    String fileName,
    String itemId,
  ) async {
    try {
      return await _storage.uploadImageBytes(
        imageBytes: imageBytes,
        fileName: fileName,
        itemId: itemId,
        type: 'posts',
      );
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images with progress callback (mobile/desktop only)
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String itemId, {
    Function(int current, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Use uploadMultipleImagesBytes for web');
    }
    return await _storage.uploadMultipleImages(
      imageFiles: imageFiles,
      itemId: itemId,
      type: 'posts',
      onProgress: onProgress,
    );
  }

  /// Upload multiple images bytes with progress callback (works on all platforms)
  Future<List<String>> uploadMultipleImagesBytes(
    List<Uint8List> imagesBytes,
    List<String> fileNames,
    String itemId, {
    Function(int current, int total)? onProgress,
  }) async {
    return await _storage.uploadMultipleImagesBytes(
      imagesBytes: imagesBytes,
      fileNames: fileNames,
      itemId: itemId,
      type: 'posts',
      onProgress: onProgress,
    );
  }

  /// Create a new lost item post (accepts both File and bytes)
  Future<String> createLostItem({
    required String itemName,
    required String description,
    required String category,
    required String location,
    List<File>? images,
    List<Uint8List>? imagesBytes,
    List<String>? imageFileNames,
    String? dateFound,
    Function(int current, int total)? onImageUploadProgress,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate image inputs
      if ((images == null || images.isEmpty) && 
          (imagesBytes == null || imagesBytes.isEmpty)) {
        throw Exception('At least one image is required');
      }

      if (imagesBytes != null && imageFileNames != null && 
          imagesBytes.length != imageFileNames.length) {
        throw Exception('imagesBytes and imageFileNames must have the same length');
      }

      // Create document reference to get ID
      final docRef = _lostItemsCollection.doc();
      final String itemId = docRef.id;

      // Upload images with progress callback
      final List<String> imageUrls;
      if (kIsWeb || (imagesBytes != null && imagesBytes.isNotEmpty)) {
        // Web or bytes provided: use bytes upload
        imageUrls = await uploadMultipleImagesBytes(
          imagesBytes!,
          imageFileNames ?? List.generate(imagesBytes.length, (i) => 'image_$i.jpg'),
          itemId,
          onProgress: onImageUploadProgress,
        );
      } else {
        // Mobile/Desktop: use file upload
        imageUrls = await uploadMultipleImages(
          images!,
          itemId,
          onProgress: onImageUploadProgress,
        );
      }

      // Create lost item data
      final Map<String, dynamic> lostItemData = {
        'itemId': itemId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email,
        'itemName': itemName,
        'description': description,
        'category': category,
        'location': location,
        'images': imageUrls,
        'dateFound': dateFound ?? DateTime.now().toIso8601String(),
        'datePosted': FieldValue.serverTimestamp(),
        'status': 'available', // available, claimed, returned
        'claimedBy': null,
        'claimedAt': null,
        'views': 0,
        'likes': 0,
        'comments': [],
        'tags': [],
        ...?additionalDetails,
      };

      // Save to Firestore
      await docRef.set(lostItemData);

      return itemId;
    } catch (e) {
      throw Exception('Failed to create lost item: $e');
    }
  }

  /// Get all lost items
  // In your LostItemService class
Stream<QuerySnapshot> getLostItems({String status = 'available', int limit = 50}) {
  return FirebaseFirestore.instance
      .collection('lost_items')
      .where('status', isEqualTo: status) // Ensure this filter is working
      .orderBy('datePosted', descending: true)
      .limit(limit)
      .snapshots();
}

  /// Get lost items by user
  Stream<QuerySnapshot> getUserLostItems(String userId) {
    return _lostItemsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('datePosted', descending: true)
        .snapshots();
  }

  /// Get single lost item
  Future<DocumentSnapshot> getLostItem(String itemId) async {
    return await _lostItemsCollection.doc(itemId).get();
  }

  /// Update lost item
  Future<void> updateLostItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _lostItemsCollection.doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update lost item: $e');
    }
  }

  /// Mark item as claimed
  Future<void> claimItem(String itemId, String claimerId) async {
    try {
      await _lostItemsCollection.doc(itemId).update({
        'status': 'claimed',
        'claimedBy': claimerId,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to claim item: $e');
    }
  }

  /// Mark item as returned
  Future<void> markAsReturned(String itemId) async {
    try {
      // Get item details before updating
      final doc = await _lostItemsCollection.doc(itemId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final itemName = data?['itemName'] ?? data?['name'] ?? data?['title'] ?? 'Item';
      final foundById = data?['foundBy'] ?? data?['foundById'];
      final claimedBy = data?['claimedBy'];

      await _lostItemsCollection.doc(itemId).update({
        'status': 'returned',
        'returnedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications and record activities for return completion
      final notificationService = NotificationService();
      final activityService = ActivityService();
      
      // Reward points for successful return
      const karmaReward = 10;
      const pointsReward = 50;

      // Notify claimer (owner) about successful return
      if (claimedBy != null) {
        await notificationService.notifyUserReturnCompleted(
          userId: claimedBy,
          itemName: itemName,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
        await activityService.recordReturnCompleted(
          itemName: itemName,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
      }

      // Notify founder about successful return completion
      if (foundById != null) {
        await notificationService.notifyUserReturnCompleted(
          userId: foundById,
          itemName: itemName,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
        await activityService.recordUserReturnCompleted(
          userId: foundById,
          itemName: itemName,
          karmaEarned: karmaReward,
          pointsEarned: pointsReward,
        );
      }
    } catch (e) {
      throw Exception('Failed to mark item as returned: $e');
    }
  }

  /// Delete lost item
  Future<void> deleteLostItem(String itemId) async {
    try {
      // Get item data to delete images
      final doc = await _lostItemsCollection.doc(itemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> images = data['images'] ?? [];

        // Delete images from Supabase Storage
        for (String imageUrl in images) {
          try {
            await _storage.deleteImage(imageUrl);
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }
      }

      // Delete document
      await _lostItemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete lost item: $e');
    }
  }

  /// Increment view count
  Future<void> incrementViews(String itemId) async {
    try {
      await _lostItemsCollection.doc(itemId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to increment views: $e');
    }
  }

  /// Add comment
  Future<void> addComment(String itemId, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _lostItemsCollection.doc(itemId).update({
        'comments': FieldValue.arrayUnion([commentData]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Search lost items
  Stream<QuerySnapshot> searchLostItems(String searchQuery) {
    return _lostItemsCollection
        .where('itemName', isGreaterThanOrEqualTo: searchQuery)
        .where('itemName', isLessThanOrEqualTo: '$searchQuery\uf8ff')
        .snapshots();
  }

  /// Get items by location
  Stream<QuerySnapshot> getItemsByLocation(String location) {
    return _lostItemsCollection
        .where('location', isEqualTo: location)
        .orderBy('datePosted', descending: true)
        .snapshots();
  }

  /// Delete old items (older than specified days)
  /// This helps manage storage costs by removing old, unclaimed items
  Future<int> deleteOldItems({int daysOld = 90}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Query items older than cutoff date with status 'available'
      final QuerySnapshot oldItems = await _lostItemsCollection
          .where('status', isEqualTo: 'available')
          .where('datePosted', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deletedCount = 0;
      
      for (var doc in oldItems.docs) {
        try {
          await deleteLostItem(doc.id);
          deletedCount++;
        } catch (e) {
          print('Failed to delete item ${doc.id}: $e');
        }
      }

      return deletedCount;
    } catch (e) {
      print('Failed to delete old items: $e');
      return 0;
    }
  }

  /// Delete returned items (older than specified days)
  /// Removes items that have been successfully returned to free up storage
  Future<int> deleteReturnedItems({int daysOld = 30}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Query returned items older than cutoff date
      final QuerySnapshot returnedItems = await _lostItemsCollection
          .where('status', isEqualTo: 'returned')
          .where('returnedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deletedCount = 0;
      
      for (var doc in returnedItems.docs) {
        try {
          await deleteLostItem(doc.id);
          deletedCount++;
        } catch (e) {
          print('Failed to delete returned item ${doc.id}: $e');
        }
      }

      return deletedCount;
    } catch (e) {
      print('Failed to delete returned items: $e');
      return 0;
    }
  }

  /// Cleanup storage - Delete both old and returned items
  /// Call this periodically to maintain free tier limits
  Future<Map<String, int>> cleanupStorage({
    int oldItemsDays = 90,
    int returnedItemsDays = 30,
  }) async {
    final int oldDeleted = await deleteOldItems(daysOld: oldItemsDays);
    final int returnedDeleted = await deleteReturnedItems(daysOld: returnedItemsDays);
    
    return {
      'oldItemsDeleted': oldDeleted,
      'returnedItemsDeleted': returnedDeleted,
      'totalDeleted': oldDeleted + returnedDeleted,
    };
  }
}
