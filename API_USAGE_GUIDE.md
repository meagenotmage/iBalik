# Lost Items API Usage Guide

## Overview
This guide demonstrates how to use the Lost Items API integrated with Firebase Firestore and Firebase Storage.

## Features Implemented

### ✅ Image Upload
- Multiple image selection (up to 5 images)
- Image preview before posting
- Remove selected images
- Upload to Firebase Storage

### ✅ Real-time Data Sync
- Live updates when new items are posted
- StreamBuilder for real-time Firestore data
- Automatic refresh when data changes

### ✅ Filtering & Search
- Filter by category (Electronics, Personal Items, Bags, Documents, Accessories)
- Filter by location (Library, Cafeteria, Engineering Building, etc.)
- Search by item name or description
- Real-time filter updates

### ✅ Item Management
- Create new lost item posts with photos
- View all available items
- Display item details with images
- Track post timestamp and relative time display

## How to Use

### 1. Posting a Lost Item

**Location:** `PostFoundItemPage`

```dart
// Navigate to post page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PostFoundItemPage()),
);
```

**Steps:**
1. Fill in item details (name, description, category, location)
2. Select found date
3. Tap "Add Photos" to select images (1-5 images)
4. Choose availability option:
   - "Keep with me" - Posts immediately to Firebase
   - "Drop off at location" - Navigates to drop-off confirmation
   - "College-specific hub" - Navigates to college selection
5. Tap "Post Item and Earn Points"

**What Happens:**
- Images are uploaded to Firebase Storage at `lost_items/{itemId}/{timestamp}.jpg`
- Item data is saved to Firestore collection `lost_items`
- User receives success confirmation
- Item appears in real-time on Posts page

### 2. Viewing Posted Items

**Location:** `PostsPage`

The page automatically displays all available lost items from Firebase:

```dart
StreamBuilder<QuerySnapshot>(
  stream: _lostItemService.getLostItems(status: 'available', limit: 50),
  builder: (context, snapshot) {
    // Display items in list
  },
)
```

**Features:**
- Real-time updates (no refresh needed)
- Item cards show:
  - First image from Firebase Storage
  - Item name and description
  - Location where found
  - Time posted (relative: "2h ago", "1d ago")
  - Finder's name
- Loading states and error handling
- Empty state when no items found

### 3. Filtering Items

**Options:**
- **Category Filter:**
  - All
  - Electronics
  - Personal Items
  - Bags
  - Documents
  - Accessories

- **Location Filter:**
  - All Locations
  - Library
  - Cafeteria
  - Engineering Building
  - Main Parking
  - Main Building
  - Gym

- **Search:**
  - Type in search bar to filter by item name or description
  - Real-time results as you type

### 4. Firebase Service Methods

#### Create Item
```dart
final String itemId = await lostItemService.createLostItem(
  itemName: 'Black iPhone 13',
  description: 'Found near library',
  category: 'Electronics',
  location: 'Library',
  images: [File('/path/to/image1.jpg'), File('/path/to/image2.jpg')],
  dateFound: DateTime.now().toIso8601String(),
);
```

#### Get Items Stream
```dart
Stream<QuerySnapshot> items = lostItemService.getLostItems(
  status: 'available',  // optional: 'available', 'claimed', 'returned'
  category: 'Electronics',  // optional
  limit: 20,  // optional
);
```

#### Get User's Items
```dart
Stream<QuerySnapshot> myItems = lostItemService.getUserLostItems(userId);
```

#### Search Items
```dart
List<QueryDocumentSnapshot> results = 
  await lostItemService.searchLostItems('iPhone');
```

#### Update Item
```dart
await lostItemService.updateLostItem(
  itemId,
  {'status': 'claimed', 'claimedBy': currentUserId},
);
```

#### Delete Item
```dart
await lostItemService.deleteLostItem(itemId);
```

## Data Structure

### Firestore Document (lost_items collection)
```json
{
  "itemId": "auto-generated-id",
  "userId": "user-firebase-auth-id",
  "userName": "John Cruz",
  "userEmail": "john@example.com",
  "itemName": "Black iPhone 13",
  "description": "Found near the computer section",
  "category": "Electronics",
  "location": "Library",
  "images": [
    "https://firebasestorage.googleapis.com/.../image1.jpg",
    "https://firebasestorage.googleapis.com/.../image2.jpg"
  ],
  "dateFound": "2025-11-24T10:30:00.000Z",
  "datePosted": Timestamp(1732446600),
  "status": "available",
  "claimedBy": null,
  "views": 0,
  "likes": 0,
  "comments": [],
  "tags": []
}
```

### Firebase Storage Structure
```
lost_items/
  └── {itemId}/
      ├── 1732446600000.jpg
      ├── 1732446605000.jpg
      └── ...
```

## Error Handling

### Common Errors & Solutions

1. **"Permission denied" on upload**
   - Solution: Check Firebase Storage rules (see DATABASE_STRUCTURE.md)
   - Ensure user is authenticated

2. **"No items found"**
   - Solution: Check if items exist in Firestore
   - Verify collection name is "lost_items"
   - Check filter settings

3. **Images not loading**
   - Solution: Verify Firebase Storage URLs are public
   - Check network connection
   - Verify Storage rules allow read access

4. **Upload fails**
   - Solution: Check image file size (< 5MB)
   - Verify Firebase Storage is enabled
   - Check authentication state

## Testing Checklist

- [ ] Post item with single image
- [ ] Post item with multiple images (up to 5)
- [ ] View posted items on Posts page
- [ ] Filter by category
- [ ] Filter by location
- [ ] Search by item name
- [ ] Check real-time updates (post from different device)
- [ ] Verify images load correctly
- [ ] Test "Keep with me" flow
- [ ] Test "Drop off at location" flow
- [ ] Test error states (no internet, upload failure)

## Next Steps

1. **Set Up Firebase Security Rules**
   - Copy rules from DATABASE_STRUCTURE.md
   - Deploy to Firebase Console

2. **Test Real Data**
   - Post actual items with photos
   - Verify real-time sync
   - Test on multiple devices

3. **Add Features**
   - Item claiming functionality
   - User profiles with posted items
   - Notifications for claims
   - Image compression before upload
   - Offline support

## Support

For issues or questions:
1. Check DATABASE_STRUCTURE.md for database schema
2. Review Firebase Console for data/storage
3. Check Flutter console for error logs
4. Verify Firebase configuration in firebase_options.dart

## Performance Tips

1. **Image Optimization**
   - Compress images before upload
   - Use cached_network_image package for better performance
   - Implement lazy loading for large lists

2. **Query Optimization**
   - Use pagination (limit parameter)
   - Create Firestore indexes for filtered queries
   - Cache frequently accessed data

3. **Storage Optimization**
   - Resize images to max 1920x1080
   - Use WebP format for smaller file sizes
   - Implement progressive image loading
