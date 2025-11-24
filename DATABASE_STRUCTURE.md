# Lost Items Database Structure

## Overview
This document describes the Firebase Firestore database structure for the Lost & Found items system with photo upload support.

## Collection: `lost_items`

### Document Structure

```json
{
  "itemId": "string (auto-generated)",
  "userId": "string (from Firebase Auth)",
  "userName": "string",
  "userEmail": "string",
  "itemName": "string",
  "description": "string",
  "category": "string",
  "location": "string",
  "images": ["array of image URLs"],
  "dateFound": "ISO 8601 string",
  "datePosted": "Firestore timestamp",
  "status": "string (available/claimed/returned)",
  "claimedBy": "string (userId) or null",
  "claimedAt": "Firestore timestamp or null",
  "returnedAt": "Firestore timestamp or null",
  "views": "number",
  "likes": "number",
  "comments": [
    {
      "userId": "string",
      "userName": "string",
      "comment": "string",
      "timestamp": "ISO 8601 string"
    }
  ],
  "tags": ["array of strings"]
}
```

### Field Descriptions

#### Required Fields
- **itemId** (string): Unique identifier for the item
- **userId** (string): ID of the user who posted the item
- **userName** (string): Display name of the poster
- **userEmail** (string): Email of the poster
- **itemName** (string): Name/title of the lost item
- **description** (string): Detailed description of the item
- **category** (string): Category of the item (e.g., "Electronics", "Personal Items", "Documents", "Clothing")
- **location** (string): Where the item was found
- **images** (array): Array of image URLs from Firebase Storage
- **datePosted** (timestamp): When the post was created
- **status** (string): Current status of the item

#### Optional Fields
- **dateFound** (string): When the item was found (defaults to current date)
- **claimedBy** (string): User ID of who claimed the item
- **claimedAt** (timestamp): When the item was claimed
- **returnedAt** (timestamp): When the item was marked as returned
- **views** (number): Number of times the item was viewed
- **likes** (number): Number of likes
- **comments** (array): Array of comment objects
- **tags** (array): Array of searchable tags

### Status Values
- `available`: Item is available to be claimed
- `claimed`: Item has been claimed by someone
- `returned`: Item has been returned to owner

## Firebase Storage Structure

### Image Storage Path
```
lost_items/
  └── {itemId}/
      ├── {timestamp1}.jpg
      ├── {timestamp2}.jpg
      └── ...
```

## Service Methods

### LostItemService Class

#### Create Operations
- `createLostItem()`: Create a new lost item post with images
- `uploadItemImage()`: Upload a single image to Firebase Storage
- `uploadMultipleImages()`: Upload multiple images for an item

#### Read Operations
- `getLostItems()`: Get all lost items (with optional filters)
- `getUserLostItems()`: Get items posted by a specific user
- `getLostItem()`: Get a single item by ID
- `searchLostItems()`: Search items by name
- `getItemsByLocation()`: Get items by location

#### Update Operations
- `updateLostItem()`: Update item details
- `claimItem()`: Mark item as claimed
- `markAsReturned()`: Mark item as returned
- `incrementViews()`: Increment view count
- `addComment()`: Add a comment to an item

#### Delete Operations
- `deleteLostItem()`: Delete item and associated images

## Usage Example

```dart
import 'package:flutter_ibalik/services/lost_item_service.dart';
import 'dart:io';

// Initialize service
final lostItemService = LostItemService();

// Create a new lost item post
final String itemId = await lostItemService.createLostItem(
  itemName: 'Black iPhone 13',
  description: 'Found near the library computer section',
  category: 'Electronics',
  location: 'Library',
  images: [File('path/to/image1.jpg'), File('path/to/image2.jpg')],
  dateFound: DateTime.now().toIso8601String(),
);

// Get all available items
Stream<QuerySnapshot> items = lostItemService.getLostItems(
  status: 'available',
  limit: 20,
);

// Claim an item
await lostItemService.claimItem(itemId, currentUserId);

// Mark as returned
await lostItemService.markAsReturned(itemId);
```

## Image Handling

### Supported Image Operations
1. **Multiple Image Upload**: Up to 5 images per item
2. **Image Compression**: Images should be compressed before upload
3. **Image Formats**: JPG, PNG supported
4. **Storage Location**: Firebase Storage with public read access

### Image Picker Usage
```dart
import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();

// Pick single image
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

// Pick multiple images
final List<XFile> images = await picker.pickMultiImage();
```

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /lost_items/{itemId} {
      // Allow read for all authenticated users
      allow read: if request.auth != null;
      
      // Allow create for authenticated users
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      
      // Allow update only for item owner or when claiming
      allow update: if request.auth != null 
                    && (resource.data.userId == request.auth.uid 
                        || request.resource.data.status == 'claimed');
      
      // Allow delete only for item owner
      allow delete: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Security Rules (Storage)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /lost_items/{itemId}/{imageId} {
      // Allow read for all authenticated users
      allow read: if request.auth != null;
      
      // Allow write only for authenticated users
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
      
      // Allow delete for authenticated users (should match item owner in app logic)
      allow delete: if request.auth != null;
    }
  }
}
```

## Indexes Required

For optimal query performance, create these composite indexes in Firestore:

1. **Collection: lost_items**
   - Fields: `status` (Ascending), `datePosted` (Descending)
   - Fields: `category` (Ascending), `datePosted` (Descending)
   - Fields: `userId` (Ascending), `datePosted` (Descending)
   - Fields: `location` (Ascending), `datePosted` (Descending)

## Best Practices

1. **Image Optimization**
   - Compress images before upload
   - Resize large images to max 1920x1080
   - Use JPG format for photos

2. **Data Validation**
   - Validate all required fields before submission
   - Sanitize user input (especially description and comments)
   - Limit description to 500 characters
   - Limit comment length to 200 characters

3. **Performance**
   - Use pagination for large lists
   - Cache frequently accessed items
   - Lazy load images

4. **Error Handling**
   - Handle network errors gracefully
   - Provide user feedback on upload progress
   - Retry failed uploads

5. **Privacy**
   - Don't store sensitive information in item descriptions
   - Blur faces in photos if needed
   - Allow users to delete their posts
