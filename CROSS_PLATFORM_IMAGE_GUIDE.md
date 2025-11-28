# Cross-Platform Image Upload and Rendering Guide

## Overview

This guide documents the cross-platform image upload and rendering system for the iBalik app, supporting **Flutter Web, Mobile (Android/iOS), and Desktop** platforms.

## Architecture

### Key Components

1. **ImagePickerData** (`lib/utils/image_picker_data.dart`)
   - Wrapper class that holds both `File` (mobile/desktop) and `Uint8List` (web) representations
   - Provides platform-agnostic access to image data
   - Automatically converts `XFile` from image_picker to cross-platform format

2. **CrossPlatformImage** (`lib/utils/cross_platform_image.dart`)
   - Reusable widget for displaying images across all platforms
   - Automatically selects the correct image source:
     - **Web**: `Image.memory(Uint8List)`
     - **Mobile/Desktop**: `Image.file(File)`
     - **Network**: `Image.network(String)` (for uploaded images)
   - Includes loading and error states

3. **SupabaseStorageService** (`lib/services/supabase_storage_service.dart`)
   - Enhanced with web-specific upload methods
   - `uploadImageBytes()` - Accepts `Uint8List` (works on all platforms)
   - `uploadImage()` - Accepts `File` (mobile/desktop only)
   - Automatic image compression using `flutter_image_compress`

4. **LostItemService** (`lib/services/lost_item_service.dart`)
   - Platform-aware upload methods
   - Automatically detects platform and calls appropriate Supabase methods
   - Supports both `List<File>` and `List<Uint8List>` inputs

---

## Implementation Details

### Image Picking (Post Found Item Page)

#### Before (Mobile-Only)
```dart
final List<File> _selectedImages = [];

// Picking images
final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
if (image != null) {
  setState(() {
    _selectedImages.add(File(image.path)); // ❌ Fails on web
  });
}

// Displaying images
Image.file(_selectedImages[index]); // ❌ Fails on web
```

#### After (Cross-Platform)
```dart
final List<ImagePickerData> _selectedImages = [];

// Picking images
final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
if (image != null) {
  final imageData = await ImagePickerData.fromXFile(image); // ✅ Works everywhere
  setState(() {
    _selectedImages.add(imageData);
  });
}

// Displaying images
CrossPlatformImage(
  imageData: _selectedImages[index], // ✅ Works everywhere
  width: 120,
  height: 120,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
);
```

### Upload Flow

#### Mobile/Desktop Upload
```dart
if (!kIsWeb) {
  final files = _selectedImages
      .map((img) => img.file)
      .where((file) => file != null)
      .cast<File>()
      .toList();
  
  itemId = await _lostItemService.createLostItem(
    itemName: title,
    description: description,
    images: files, // ✅ Use File list
    // ...
  );
}
```

#### Web Upload
```dart
if (kIsWeb) {
  itemId = await _lostItemService.createLostItem(
    itemName: title,
    description: description,
    imagesBytes: _selectedImages.map((img) => img.bytes).toList(), // ✅ Use Uint8List
    imageFileNames: _selectedImages.map((img) => img.name).toList(),
    // ...
  );
}
```

### Image Display

#### Picked Images (Before Upload)
```dart
CrossPlatformImage(
  imageData: imagePickerData, // Uses memory/file based on platform
  width: 120,
  height: 120,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

#### Uploaded Images (From Supabase)
```dart
CrossPlatformImage(
  networkUrl: 'https://supabase.co/storage/v1/object/public/...', // ✅ Works everywhere
  width: 120,
  height: 120,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

Or use `Image.network()` directly:
```dart
Image.network(
  imageUrl,
  width: 120,
  height: 120,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.broken_image, color: Colors.grey);
  },
)
```

---

## UI/UX Features

### Responsive Grid Layout

**Before**: Horizontal scrolling list
```dart
ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: _selectedImages.length,
  itemBuilder: (context, index) {
    // ...
  },
)
```

**After**: Responsive 3-column grid
```dart
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 1,
  ),
  itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
  itemBuilder: (context, index) {
    // Display images or add button
  },
)
```

### Upload Progress Tracking

Real-time progress overlay during upload:
```dart
if (_isUploading)
  Container(
    color: Colors.black.withOpacity(0.7),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.cloud_upload),
          Text('Uploading $_uploadedCount of $_totalImages photos...'),
          LinearProgressIndicator(
            value: _uploadedCount / _totalImages,
          ),
          Text('${(_uploadedCount / _totalImages * 100).toStringAsFixed(0)}%'),
        ],
      ),
    ),
  ),
```

### Error Handling with Retry

Enhanced error handling for web-specific issues:
```dart
catch (e) {
  String errorMessage = 'Error posting item';
  bool showRetry = true;
  
  if (e.toString().contains('network') || e.toString().contains('timeout')) {
    errorMessage = 'Network error. Please check your connection';
  } else if (e.toString().contains('permission')) {
    errorMessage = 'Permission denied. Please sign in again';
    showRetry = false;
  } else if (kIsWeb && e.toString().contains('CORS')) {
    errorMessage = 'Upload error. Please try again';
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      action: showRetry
          ? SnackBarAction(
              label: 'Retry',
              onPressed: () => _postItem(),
            )
          : null,
    ),
  );
}
```

---

## Platform-Specific Considerations

### Web

#### Limitations
- ❌ Cannot use `dart:io` File class
- ❌ Cannot use `Image.file()` widget
- ❌ No direct file system access

#### Solutions
- ✅ Use `Uint8List` from `XFile.readAsBytes()`
- ✅ Use `Image.memory()` for previews
- ✅ Use `uploadBinary()` for Supabase uploads

#### CORS Configuration
Ensure Supabase Storage bucket allows CORS from your web domain:
```sql
-- Run in Supabase SQL Editor
CREATE POLICY "Allow public uploads for authenticated users"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'lost-item');

CREATE POLICY "Allow public read access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'lost-item');
```

### Mobile (Android/iOS)

#### Permissions Required
```yaml
# android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

# ios/Runner/Info.plist
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos of found items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

#### Permission Handling
```dart
if (!kIsWeb) {
  bool hasPermission = false;
  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.request();
    hasPermission = storageStatus.isGranted;
  } else {
    final photoStatus = await Permission.photos.request();
    hasPermission = photoStatus.isGranted;
  }
  
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permission required'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
    return;
  }
}
```

### Desktop (Windows/macOS/Linux)

#### File Picker
- ✅ Works like mobile with `File` access
- ✅ Can use `Image.file()` directly
- ✅ Upload with `uploadImage()` method

---

## Image Compression

All images are automatically compressed before upload:

### Compression Settings
```dart
var result = await FlutterImageCompress.compressWithList(
  imageBytes,
  quality: 85,        // 85% quality
  minWidth: 1024,     // Max width 1024px
  minHeight: 1024,    // Max height 1024px
);
```

### Benefits
- 📉 Reduces file size by 70-80%
- ⚡ Faster uploads
- 💾 Saves storage space
- 🌐 Better for slow networks

---

## Testing Checklist

### Web Testing
- [ ] Pick single image from file picker
- [ ] Pick multiple images (up to 5)
- [ ] Preview images before upload (grid layout)
- [ ] Remove individual images
- [ ] Upload progress displays correctly
- [ ] Successful upload shows Supabase URLs in Firestore
- [ ] View uploaded images in Home feed
- [ ] View uploaded images in Item Details
- [ ] Handle network errors gracefully
- [ ] Handle file size limit errors (>10MB)
- [ ] Handle CORS errors with retry
- [ ] No console errors about `dart:io` or `Image.file`

### Mobile Testing (Android/iOS)
- [ ] Request camera permission
- [ ] Request photo library permission
- [ ] Pick from gallery (multiple selection)
- [ ] Take photo with camera
- [ ] Preview images in grid layout
- [ ] Remove individual images
- [ ] Upload progress displays correctly
- [ ] Successful upload shows Supabase URLs
- [ ] View uploaded images in app
- [ ] Handle permission denied scenario
- [ ] Handle network errors
- [ ] Handle file size limit errors

### Desktop Testing (Windows/macOS/Linux)
- [ ] Pick images from file picker
- [ ] Preview images in grid layout
- [ ] Upload functionality works
- [ ] View uploaded images

---

## Performance Optimization

### Lazy Loading
```dart
Image.network(
  imageUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded / 
            loadingProgress.expectedTotalBytes!
          : null,
    );
  },
)
```

### Caching
Consider using `cached_network_image` for better performance:
```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### Image Size Limits
- **Per Image**: 10MB (enforced by Supabase bucket)
- **Total Upload**: 5 images max per post
- **Compression**: Automatic (85% quality, 1024x1024 max)

---

## Deployment

### Supabase Configuration

1. **Create Bucket**
```dart
await _supabase.storage.createBucket(
  'lost-item',
  const BucketOptions(
    public: true,
    fileSizeLimit: '10485760', // 10MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg'],
  ),
);
```

2. **Apply Storage Policies** (see SUPABASE_STORAGE_GUIDE.md)

### Web Deployment

1. **Build for Web**
```bash
flutter build web --release
```

2. **Deploy to Firebase Hosting**
```bash
firebase deploy --only hosting
```

3. **Verify CORS Headers**
- Ensure your hosting platform allows CORS from Supabase domain
- Test uploads in production environment

---

## Troubleshooting

### Issue: "dart:io not available on web"
**Solution**: Ensure all `File` usage is wrapped in `!kIsWeb` checks

### Issue: Image.file() fails on web
**Solution**: Use `CrossPlatformImage` widget instead

### Issue: CORS errors on web uploads
**Solution**: 
1. Check Supabase bucket policies
2. Verify bucket is public
3. Ensure authenticated users can upload

### Issue: Images not displaying after upload
**Solution**:
1. Verify Supabase public URLs are stored in Firestore
2. Check Image.network error builder
3. Verify bucket is public

### Issue: Upload progress not updating
**Solution**:
1. Ensure `mounted` check before setState
2. Verify callback is passed to upload methods
3. Check state variables are initialized

---

## Code Examples

### Complete Cross-Platform Upload
```dart
Future<void> _uploadImages() async {
  setState(() {
    _isUploading = true;
    _totalImages = _selectedImages.length;
    _uploadedCount = 0;
  });

  try {
    final String itemId;
    
    if (kIsWeb) {
      // Web upload
      itemId = await _lostItemService.createLostItem(
        itemName: title,
        imagesBytes: _selectedImages.map((img) => img.bytes).toList(),
        imageFileNames: _selectedImages.map((img) => img.name).toList(),
        onImageUploadProgress: (current, total) {
          if (mounted) {
            setState(() {
              _uploadedCount = current;
            });
          }
        },
      );
    } else {
      // Mobile/Desktop upload
      final files = _selectedImages
          .map((img) => img.file!)
          .toList();
      
      itemId = await _lostItemService.createLostItem(
        itemName: title,
        images: files,
        onImageUploadProgress: (current, total) {
          if (mounted) {
            setState(() {
              _uploadedCount = current;
            });
          }
        },
      );
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
      // Navigate to success page
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isUploading = false;
      });
      // Show error with retry
    }
  }
}
```

---

## Related Files

### Modified Files
- `lib/utils/image_picker_data.dart` (NEW)
- `lib/utils/cross_platform_image.dart` (NEW)
- `lib/services/supabase_storage_service.dart` (UPDATED)
- `lib/services/lost_item_service.dart` (UPDATED)
- `lib/screens/posts/post_found_item_page.dart` (UPDATED)

### Unmodified Files (Already Compatible)
- `lib/screens/home/home_page.dart` (uses Image.network ✅)
- `lib/screens/claims/claims_page.dart` (uses Image.network ✅)
- `lib/screens/posts/item_details_page.dart` (uses Image.network ✅)
- `lib/screens/claims/claim_item_page.dart` (uses Image.network ✅)

---

## Support

For issues or questions:
1. Check this guide first
2. Review SUPABASE_STORAGE_GUIDE.md
3. Test on target platform (web/mobile/desktop)
4. Check Flutter console for specific error messages

## Version History

- **v1.0** (Nov 2025) - Initial cross-platform implementation
  - Added ImagePickerData and CrossPlatformImage
  - Updated Supabase service for web uploads
  - Implemented grid layout for image previews
  - Added comprehensive error handling
