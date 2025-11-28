# Supabase Storage Integration Guide

## Overview
This document explains the Supabase Storage integration for the iBalik app, which provides photo uploading and storage functionality for lost and found items.

## Architecture

### Storage Structure
```
lost-item (bucket)
├── posts/
│   ├── {itemId}/
│   │   ├── {timestamp}_{filename}.jpg
│   │   └── ...
└── claims/
    ├── {claimId}/
        ├── {timestamp}_{filename}.jpg
        └── ...
```

### Key Components

#### 1. SupabaseStorageService (`lib/services/supabase_storage_service.dart`)
Core service handling all Supabase Storage operations:

**Features:**
- Image compression before upload (85% quality, max 1024x1024)
- Multiple image upload with progress tracking
- Public URL generation
- Image deletion
- Bucket access validation

**Key Methods:**
```dart
// Upload single image
Future<String> uploadImage({
  required File imageFile,
  required String itemId,
  required String type, // 'posts' or 'claims'
})

// Upload multiple images with progress
Future<List<String>> uploadMultipleImages({
  required List<File> imageFiles,
  required String itemId,
  required String type,
  Function(int current, int total)? onProgress,
})

// Delete images
Future<void> deleteImage(String imageUrl)
Future<void> deleteMultipleImages(List<String> imageUrls)
```

#### 2. LostItemService Updates (`lib/services/lost_item_service.dart`)
Modified to use Supabase instead of Cloudinary:

**Changes:**
- Replaced `CloudinaryService` with `SupabaseStorageService`
- Added progress callback support to `createLostItem()`
- Updated upload methods to use Supabase paths

#### 3. Post Found Item Page (`lib/screens/posts/post_found_item_page.dart`)
Enhanced with upload progress visualization:

**New Features:**
- Upload progress state tracking (`_uploadedCount`, `_totalImages`)
- Real-time progress overlay during upload
- Progress bar showing upload percentage
- Disabled navigation during upload

## User Experience Flow

### Posting a Found Item
1. User selects images (up to 5) from gallery or camera
2. User fills in item details and clicks "Post Item"
3. **Upload Progress Overlay Appears:**
   - Green cloud upload icon
   - "Uploading X of Y photos..."
   - Linear progress bar with percentage
   - Prevents navigation/interaction
4. Images are compressed and uploaded to Supabase
5. Progress updates in real-time as each image uploads
6. On success: Navigate to Home page
7. On error: Show error snackbar with retry option

### Progress Visualization
```
┌─────────────────────────────────┐
│     [Cloud Upload Icon]         │
│                                  │
│    Uploading Images              │
│  Uploading 2 of 5 photos...      │
│                                  │
│  ████████░░░░░░░░░░ 40%          │
└─────────────────────────────────┘
```

## Image Compression

### Compression Settings
- **Quality:** 85% (good balance between size and quality)
- **Max Dimensions:** 1024x1024 pixels
- **Format:** JPEG
- **Compression Library:** flutter_image_compress

### Benefits
- Reduced upload time
- Lower bandwidth usage
- Better user experience on slow connections
- Reduced storage costs

### Fallback
If compression fails, the original image is uploaded to ensure the post succeeds.

## Error Handling

### Permission Errors
```dart
try {
  await uploadImage(...);
} catch (e) {
  if (e is StorageException) {
    if (e.statusCode == 403) {
      // Permission denied
      showDialog(...);
    }
  }
}
```

### Network Errors
- Automatic retry option in snackbar
- User-friendly error messages
- Maintains form state for retry

### Upload Failures
- Continues uploading remaining images if one fails
- Returns list of successfully uploaded URLs
- Logs errors for debugging

## Firestore Integration

### Stored Metadata
When a post is created, Firestore stores:
```dart
{
  'itemId': 'doc_id',
  'images': [
    'https://erljzvaikyztphsamptd.supabase.co/storage/v1/object/public/lost-item/posts/{itemId}/{filename}.jpg',
    // ... more URLs
  ],
  'uploadedBy': 'user_uid',
  'datePosted': Timestamp,
  // ... other fields
}
```

## Home (Recent Finds) Integration

### Displaying Images
The Home feed fetches posts from Firestore and displays images using:

```dart
// Fetch posts
StreamBuilder<QuerySnapshot>(
  stream: getLostItems(status: 'available'),
  builder: (context, snapshot) {
    // Get image URLs from post data
    final images = post['images'] as List<dynamic>;
    final imageUrl = images.isNotEmpty ? images[0] : null;
    
    // Display with CachedNetworkImage
    CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => Shimmer(...),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
)
```

### Performance Optimizations
- Uses `CachedNetworkImage` for efficient image loading
- Shimmer loading effect for better UX
- Lazy loading of images as user scrolls
- Thumbnail-first loading strategy

## Supabase Storage Configuration

### Bucket Settings
- **Name:** `lost-items`
- **Public Access:** Yes (read-only public URLs)
- **File Size Limit:** 10MB per file
- **Allowed MIME Types:** image/jpeg, image/png, image/jpg, image/webp

### Storage Policies
Required Supabase policies for the `lost-items` bucket:

#### 1. Public Read Access
```sql
CREATE POLICY "Public read access" ON storage.objects
FOR SELECT
USING (bucket_id = 'lost-items');
```

#### 2. Authenticated Upload
```sql
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'lost-items' AND
  auth.role() = 'authenticated'
);
```

#### 3. Owner Delete
```sql
CREATE POLICY "Users can delete own uploads" ON storage.objects
FOR DELETE
USING (
  bucket_id = 'lost-items' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

## Testing Checklist

### Image Upload
- [ ] Select image from gallery
- [ ] Take photo with camera
- [ ] Select multiple images (up to 5)
- [ ] Upload progress shows correctly
- [ ] Images appear compressed
- [ ] Public URLs are generated
- [ ] Firestore updated with URLs

### Error Scenarios
- [ ] Network disconnected during upload
- [ ] Permission denied error
- [ ] Invalid file type
- [ ] File too large (>10MB)
- [ ] Retry after error works

### UI/UX
- [ ] Progress overlay appears during upload
- [ ] Progress bar updates smoothly
- [ ] Back button disabled during upload
- [ ] Navigation works after success
- [ ] Error messages are clear

### Home Feed
- [ ] Recent posts show images
- [ ] Images load with shimmer effect
- [ ] Cached images load instantly
- [ ] Broken image handled gracefully

## Deployment Steps

### 1. Set Up Supabase Bucket
```bash
# In Supabase Dashboard:
1. Go to Storage
2. Create new bucket: lost-item
3. Enable public access
4. Set file size limit: 10MB
5. Add MIME type restrictions
```

### 2. Apply Storage Policies
```sql
-- Run in Supabase SQL Editor
-- (See policies section above)
```

### 3. Update Environment
```dart
// Already configured in lib/main.dart
await Supabase.initialize(
  url: 'https://erljzvaikyztphsamptd.supabase.co',
  anonKey: 'your_anon_key',
);
```

### 4. Test Upload Flow
```bash
# Run app
flutter run

# Test scenarios
1. Post item with photos
2. Verify upload progress
3. Check Supabase Storage dashboard
4. Verify Firestore has URLs
5. Check Home feed displays images
```

## Monitoring

### Supabase Dashboard
Monitor storage usage:
- **Total Storage:** Check against free tier limit (1GB)
- **Bandwidth:** Monitor monthly transfer
- **File Count:** Track number of uploads
- **Error Logs:** Check for failed uploads

### Firebase Console
Monitor Firestore operations:
- **Document Writes:** Post creation with image URLs
- **Read Operations:** Home feed queries
- **Error Rates:** Failed document updates

## Troubleshooting

### Images Not Uploading
**Problem:** Upload fails silently
**Solutions:**
1. Check Supabase bucket exists
2. Verify authentication token is valid
3. Check network connectivity
4. Review Supabase logs for errors

### Permission Denied
**Problem:** 403 error during upload
**Solutions:**
1. Verify storage policies are applied
2. Check user is authenticated
3. Verify bucket permissions
4. Test with Supabase SQL editor

### Images Not Showing in Feed
**Problem:** Posts have URLs but images don't load
**Solutions:**
1. Verify URLs are properly formatted
2. Check bucket is public
3. Test URL in browser
4. Clear app cache and retry

### Slow Upload
**Problem:** Upload takes too long
**Solutions:**
1. Ensure compression is working
2. Check network speed
3. Reduce max image dimensions
4. Lower compression quality

## Cost Considerations

### Supabase Free Tier
- **Storage:** 1GB
- **Bandwidth:** 2GB/month
- **API Requests:** Unlimited

### Estimated Usage
- **Average image size:** ~200KB (after compression)
- **Images per post:** ~3
- **Posts per day:** ~50
- **Monthly storage:** ~900MB (within free tier)
- **Monthly bandwidth:** ~1.5GB (within free tier)

### Scaling Plan
If limits are reached:
1. Upgrade to Supabase Pro ($25/month): 8GB storage, 50GB bandwidth
2. Implement image CDN for better performance
3. Add automatic cleanup of old/unclaimed items
4. Compress images more aggressively

## Future Enhancements

### Planned Features
- [ ] Image cropping before upload
- [ ] Thumbnail generation (multiple sizes)
- [ ] Image filters/enhancement
- [ ] Drag-and-drop image reordering
- [ ] Batch upload optimization
- [ ] Progressive image loading
- [ ] WebP format support
- [ ] Video upload support

### Performance Improvements
- [ ] Parallel image upload
- [ ] Background upload with notifications
- [ ] Resumable uploads
- [ ] Image CDN integration
- [ ] Client-side caching strategy

## References

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Flutter Image Compress](https://pub.dev/packages/flutter_image_compress)
- [CachedNetworkImage](https://pub.dev/packages/cached_network_image)
- [Image Picker](https://pub.dev/packages/image_picker)

## Support

For issues or questions:
1. Check this documentation
2. Review Supabase logs
3. Check Firebase console
4. Contact development team
