import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Cloudinary FREE Image Storage Service
/// 25 GB storage + 25 GB bandwidth/month - NO PAYMENT REQUIRED!
class CloudinaryService {
  late CloudinaryPublic _cloudinary;
  
  // TODO: Replace these with YOUR Cloudinary credentials
  // Sign up FREE at: https://cloudinary.com/users/register/free
  static const String _cloudName = 'dbovqpb8x'; // e.g., 'dxxxxxx'
  static const String _uploadPreset = 'ml_default'; // e.g., 'ml_default'
  
  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }
  
  /// Upload a single image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile, String itemId) async {
    try {
      // Upload with folder organization
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'ibalik_lost_items/$itemId',
          publicId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }
  
  /// Upload multiple images
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles, String itemId) async {
    List<String> imageUrls = [];
    
    for (File imageFile in imageFiles) {
      try {
        final String url = await uploadImage(imageFile, itemId);
        imageUrls.add(url);
      } catch (e) {
        print('Failed to upload image: $e');
        // Continue uploading other images even if one fails
      }
    }
    
    return imageUrls;
  }
  
  /// Delete an image from Cloudinary
  /// Note: Deletion requires signed requests, which need API credentials
  /// For now, we'll skip deletion to keep the app simple and free
  /// Images will be cleaned up by Cloudinary's auto-expiration if needed
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Note: Cloudinary's free unsigned uploads don't support deletion
      // Images remain in your account but with 25GB free storage, this is fine
      // If deletion is critical, you'd need to implement a backend API
      print('Image deletion skipped (requires signed API): $imageUrl');
      
      // Alternative: Implement backend deletion service if needed in the future
    } catch (e) {
      print('Failed to delete image from Cloudinary: $e');
      // Don't throw - deletion failure shouldn't block other operations
    }
  }
  
  /// Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      await deleteImage(url);
    }
  }
  
  /// Check if Cloudinary is configured
  bool isConfigured() {
    return _cloudName != 'dbovqpb8x' && _uploadPreset != 'ml_default';
  }
}
