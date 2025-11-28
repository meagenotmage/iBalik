import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'lost-item';
  
  /// Compress image before upload to optimize performance
  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result != null) {
        return await result.readAsBytes();
      } else {
        // Fallback to original if compression fails
        return await imageFile.readAsBytes();
      }
    } catch (e) {
      debugPrint('Image compression error: $e');
      // Fallback to original
      return await imageFile.readAsBytes();
    }
  }

  /// Upload a single image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    required String itemId,
    required String type, // 'posts' or 'claims'
  }) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final filePath = '$type/$itemId/$fileName';

      // Compress image
      final compressedBytes = await _compressImage(imageFile);

      // Upload to Supabase
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Supabase Storage
  /// Returns list of public URLs
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String itemId,
    required String type, // 'posts' or 'claims'
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadImage(
          imageFile: imageFiles[i],
          itemId: itemId,
          type: type,
        );
        uploadedUrls.add(url);
        
        // Report progress
        if (onProgress != null) {
          onProgress(i + 1, imageFiles.length);
        }
      } catch (e) {
        debugPrint('Error uploading image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Delete an image from Supabase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name and get path after it
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1) {
        throw Exception('Invalid image URL: bucket not found');
      }
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      // Delete from Supabase
      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);

      debugPrint('Image deleted successfully: $filePath');
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }

  /// Delete multiple images from Supabase Storage
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await deleteImage(url);
      } catch (e) {
        debugPrint('Error deleting image: $e');
        // Continue with other images even if one fails
      }
    }
  }

  /// Get download URL for an image (same as public URL for public buckets)
  String getPublicUrl(String filePath) {
    return _supabase.storage
        .from(bucketName)
        .getPublicUrl(filePath);
  }

  /// Check if bucket exists and is accessible
  Future<bool> checkBucketAccess() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      return buckets.any((bucket) => bucket.name == bucketName);
    } catch (e) {
      debugPrint('Error checking bucket access: $e');
      return false;
    }
  }

  /// Create the lost-item bucket if it doesn't exist (admin only)
  Future<void> createBucket() async {
    try {
      await _supabase.storage.createBucket(
        bucketName,
        const BucketOptions(
          public: true,
          fileSizeLimit: '10485760', // 10MB per file
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg'],
        ),
      );
      debugPrint('Bucket created successfully: $bucketName');
    } catch (e) {
      debugPrint('Error creating bucket: $e');
      rethrow;
    }
  }
}
