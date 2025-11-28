# Troubleshooting Guide

## Image Upload Issues

### Images Not Showing in Posts

**Symptoms:**
- Images upload successfully to Supabase Storage
- Images are visible in Supabase dashboard
- Thumbnails don't show on posts page

**Common Causes & Solutions:**

#### 1. Bucket Name Mismatch
**Problem:** Code uses `lost-item` but Supabase bucket is named `lost-items`

**Solution:** 
✅ **FIXED** - Updated `supabase_storage_service.dart` to use `lost-items`

```dart
// Changed from:
static const String bucketName = 'lost-item';

// To:
static const String bucketName = 'lost-items';
```

#### 2. Missing Storage Policies
**Problem:** Supabase RLS (Row Level Security) policies not configured

**Solution:** Run these SQL commands in Supabase SQL Editor:

```sql
-- 1. Public Read Access (allows anyone to view images)
CREATE POLICY "Public read access" ON storage.objects
FOR SELECT
USING (bucket_id = 'lost-items');

-- 2. Authenticated Upload (allows logged-in users to upload)
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'lost-items' AND
  auth.role() = 'authenticated'
);

-- 3. Owner Delete (allows users to delete their own uploads)
CREATE POLICY "Users can delete own uploads" ON storage.objects
FOR DELETE
USING (
  bucket_id = 'lost-items' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

#### 3. Bucket Not Public
**Problem:** Bucket is private, public URLs don't work

**Solution:**
1. Go to Supabase Dashboard → Storage → `lost-items` bucket
2. Click on bucket settings (gear icon)
3. Enable "Public bucket" option
4. Save changes

#### 4. Invalid Image URLs
**Problem:** URLs in Firestore point to wrong bucket or malformed

**Solution:** Check URL format in Firestore:
```
✅ Correct: https://[project-id].supabase.co/storage/v1/object/public/lost-items/posts/[itemId]/[filename].jpg

❌ Wrong: https://[project-id].supabase.co/storage/v1/object/public/lost-item/posts/[itemId]/[filename].jpg
```

## Firestore Permission Errors

### Error: Missing or insufficient permissions

**Symptoms:**
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

**Common Causes & Solutions:**

#### 1. User Not Authenticated
**Problem:** Trying to access Firestore before user logs in

**Solution:**
```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // Handle not authenticated case
  return;
}
```

#### 2. Firestore Rules Too Restrictive
**Problem:** Security rules blocking legitimate operations

**Current Rules (Debugging - TEMPORARY):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Note:** These rules allow any authenticated user to read/write. For production, implement proper security:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Lost Items - Anyone can read, only owners can update/delete
    match /lost_items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }
    
    // User profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Claims
    match /claims/{claimId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (request.auth.uid == resource.data.claimedBy || 
                        request.auth.uid == resource.data.foundById);
    }
  }
}
```

#### 3. Firestore Rules Not Deployed
**Problem:** Updated rules in file but not deployed

**Solution:**
```bash
firebase deploy --only firestore:rules
```

## Storage Cleanup Errors

### Error: StorageException 403 (Unauthorized)

**Symptoms:**
```
Failed to create bucket (may need manual creation): StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

**Cause:** Anon/public key cannot create buckets (admin operation)

**Solution:** 
1. Create bucket manually in Supabase Dashboard
2. Code will detect existing bucket and continue
3. This error can be safely ignored if bucket already exists

### Cleanup Running But Failing

**Problem:** Storage cleanup tries to delete items but fails

**Common Issues:**
1. **Firestore permissions** - User needs delete access
2. **Authentication expired** - Re-authenticate user
3. **Network issues** - Check internet connection

**Debug Steps:**
```dart
try {
  final result = await cleanupService.runCleanup();
  print('Deleted: ${result['totalDeleted']} items');
} catch (e) {
  print('Cleanup error: $e');
  print('Error type: ${e.runtimeType}');
}
```

## Network & Caching Issues

### Images Not Loading (Network Error)

**Symptoms:**
- Broken image icon shows
- Network error in console
- Works on some devices but not others

**Solutions:**

#### 1. Check CORS Settings
Supabase storage should allow cross-origin requests. Verify in Supabase Dashboard → Storage → Settings.

#### 2. Clear Image Cache
```dart
// Clear cache for specific image
CachedNetworkImage.evictFromCache(imageUrl);

// Clear all image cache
await CachedNetworkImage.evictFromCache();
```

#### 3. Test URL Directly
Copy image URL from Firestore and open in browser. If it doesn't load:
- Check if bucket is public
- Verify URL format is correct
- Check if file actually exists in storage

## Testing After Fixes

### Verify Image Upload & Display

1. **Post New Item:**
   ```
   - Select/take photo
   - Fill in item details
   - Submit post
   - Check Firestore: lost_items/{itemId}/images array has URLs
   - Check Supabase Storage: lost-items/posts/{itemId}/ has image files
   ```

2. **View Posts Page:**
   ```
   - Open posts page
   - Verify thumbnails load
   - Click item to view details
   - All images should display
   ```

3. **Test All Image Upload Points:**
   ```
   ✓ Posting found item (posts/)
   ✓ Claiming item with proof (claims/)
   ✓ Confirming return with image (claims/)
   ```

### Debug Checklist

- [ ] Bucket name is `lost-items` in code
- [ ] Bucket exists in Supabase
- [ ] Bucket is public
- [ ] Storage policies are created
- [ ] Firestore rules allow authenticated access
- [ ] User is logged in before operations
- [ ] Image URLs in Firestore are valid
- [ ] CachedNetworkImage package is working

## Quick Fixes Reference

### Restart App After Changes
```bash
flutter clean
flutter pub get
flutter run
```

### Check Current Configuration
```dart
// In supabase_storage_service.dart
print('Bucket name: ${SupabaseStorageService.bucketName}');
print('Supabase URL: ${Supabase.instance.client.supabaseUrl}');

// Check if bucket is accessible
final accessible = await _storage.checkBucketAccess();
print('Bucket accessible: $accessible');
```

### Force Firestore Rules Deployment
```bash
firebase deploy --only firestore:rules --force
```

### View Logs
```bash
# Flutter logs
flutter logs

# Filter for storage/image errors
flutter logs | grep -i "storage\|image\|supabase"
```

## Contact & Support

If issues persist after trying all solutions:

1. Check bucket exists: Supabase Dashboard → Storage
2. Verify policies: Supabase Dashboard → Storage → Policies
3. Test authentication: Firebase Console → Authentication
4. Check Firestore rules: Firebase Console → Firestore → Rules
5. Examine logs: Both Flutter console and Firebase/Supabase dashboards

## Common Error Messages Decoded

| Error | Meaning | Solution |
|-------|---------|----------|
| `StorageException 403` | No permission to access storage | Check storage policies |
| `permission-denied` | Firestore rules blocking access | Update Firestore rules |
| `User not authenticated` | No Firebase user logged in | Ensure user is signed in |
| `Bucket not found` | Bucket name mismatch | Verify bucket name matches |
| `Network error` | Can't reach server | Check internet connection |
| `Invalid image URL` | Malformed or wrong URL | Check URL format |

