# Push Notifications Setup Guide

## Overview
The iBalik app now supports push notifications for claim-related events. Users will receive phone notifications when:

1. **Founder receives notification when:**
   - Someone requests to claim their posted item

2. **Claimer receives notification when:**
   - Their claim is approved by the founder
   - Their claim is rejected by the founder

## Features Implemented

### 1. Push Notification Service (`push_notification_service.dart`)
- Handles Firebase Cloud Messaging (FCM) initialization
- Requests notification permissions
- Manages FCM tokens (stores in Firestore)
- Checks user notification preferences before sending
- Respects both "Push Notifications" and "Claim Notifications" toggle settings

### 2. Settings Page Integration
The settings toggles in the Profile page now properly work:

**Notifications Section:**
- **Push Notifications** - Master toggle for all push notifications
- **Email Notifications** - For future email integration
- **Claim Notifications** - Specific toggle for claim-related notifications

**Privacy Section:**
- **Public Profile** - Controls profile visibility
- **Show Statistics** - Controls stats on leaderboards

All settings are persisted to Firestore at: `users/{userId}/settings/`

### 3. Notification Flow

#### When a Claim is Submitted:
```
User submits claim → NotificationService.notifyUserClaimReceived() 
→ Creates in-app notification 
→ PushNotificationService.sendPushNotification()
→ Checks user preferences
→ Sends push notification (if enabled)
```

#### When a Claim is Approved:
```
Founder approves claim → NotificationService.notifyUserClaimApproved()
→ Creates in-app notification
→ PushNotificationService.sendPushNotification()
→ Checks user preferences
→ Sends push notification (if enabled)
```

#### When a Claim is Rejected:
```
Founder rejects claim → NotificationService.notifyUserClaimDenied()
→ Creates in-app notification
→ PushNotificationService.sendPushNotification()
→ Checks user preferences
→ Sends push notification (if enabled)
```

## Firestore Data Structure

### User Document (`users/{userId}`)
```json
{
  "username": "johndoe",
  "email": "johndoe@wvsu.edu.ph",
  "fcmToken": "dXYZ123...",
  "fcmTokenUpdatedAt": Timestamp,
  "settings": {
    "notifications": {
      "pushNotifications": true,
      "emailNotifications": true,
      "claimNotifications": true
    },
    "privacy": {
      "publicProfile": true,
      "showStatistics": true
    }
  }
}
```

### Notification Document (`notifications/{notificationId}`)
```json
{
  "userId": "user123",
  "type": "claimReceived",
  "title": "📬 New Claim Request",
  "message": "John Doe wants to claim your 'Blue Backpack'",
  "metadata": {
    "itemName": "Blue Backpack",
    "claimerName": "John Doe",
    "itemId": "item123"
  },
  "actionRoute": "/claims",
  "actionId": "claim123",
  "isRead": false,
  "createdAt": Timestamp
}
```

## Backend Requirements (For Production)

### Important: Server-Side Push Notification Delivery

The current implementation checks user preferences and prepares notification data, but **actual push notification delivery requires a backend server** with Firebase Admin SDK.

#### Why Backend is Needed:
- Firebase Cloud Messaging requires server credentials to send push notifications
- Client apps cannot send push notifications directly for security reasons
- You need Firebase Admin SDK running on a secure server

#### Recommended Setup Options:

##### Option 1: Firebase Cloud Functions (Recommended)
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendClaimNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const userId = notification.userId;
    
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;
    
    // Send push notification
    const message = {
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: notification.metadata || {},
      token: fcmToken,
    };
    
    await admin.messaging().send(message);
  });
```

##### Option 2: Custom Backend Server (Node.js, Python, etc.)
Create an API endpoint that:
1. Receives notification data from your app
2. Uses Firebase Admin SDK to send push notifications
3. Returns success/failure status

##### Option 3: Firebase Extensions
Use Firebase's official "Trigger Email" or similar extensions that can be customized.

### Setup Steps for Cloud Functions:

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Cloud Functions:**
   ```bash
   cd c:\Users\meagie\Desktop\iBalik
   firebase init functions
   ```

3. **Install dependencies:**
   ```bash
   cd functions
   npm install firebase-admin firebase-functions
   ```

4. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```

## Testing Push Notifications

### Testing in Development:

1. **Enable notifications in app settings**
   - Open Profile → Settings tab
   - Ensure "Push Notifications" is ON
   - Ensure "Claim Notifications" is ON

2. **Test claim flow:**
   - User A posts an item
   - User B submits a claim
   - User A should receive notification
   - User A approves/rejects
   - User B should receive notification

3. **Check FCM tokens in Firestore:**
   - Go to Firebase Console → Firestore
   - Check `users/{userId}` document
   - Verify `fcmToken` field exists

### Testing with Firebase Console:

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and body
4. Target: Select a specific FCM token from Firestore
5. Send test message

## Troubleshooting

### Push notifications not appearing:

1. **Check permissions:**
   - Android: Settings → Apps → iBalik → Notifications (should be ON)
   - iOS: Settings → Notifications → iBalik (allow notifications)

2. **Check settings in app:**
   - Profile → Settings → Push Notifications (should be ON)

3. **Check Firestore:**
   - Verify user has `fcmToken` field
   - Verify `settings.notifications.pushNotifications = true`

4. **Check logs:**
   - Look for "FCM Token: ..." in debug console
   - Look for "Would send push notification to..." messages

5. **Backend not set up:**
   - Remember: Push notifications require backend implementation
   - See "Backend Requirements" section above

## Current Status

✅ **Completed:**
- FCM integration in Flutter app
- Permission requests
- Token management
- User preference checks
- Settings UI with persistence
- Notification service integration
- Android manifest configuration

⚠️ **Requires Setup:**
- Backend server (Cloud Functions or custom API)
- Actual push notification sending via Firebase Admin SDK

## Files Modified

1. **New files:**
   - `lib/services/push_notification_service.dart` - Push notification handling
   - `PUSH_NOTIFICATIONS_GUIDE.md` - This documentation

2. **Modified files:**
   - `lib/services/notification_service.dart` - Integrated push service
   - `lib/main.dart` - Initialize FCM and background handler
   - `lib/screens/home/home_page.dart` - Initialize on login
   - `android/app/src/main/AndroidManifest.xml` - FCM permissions and service
   - `pubspec.yaml` - Added firebase_messaging dependency

3. **Settings already working:**
   - `lib/screens/home/profile_page.dart` - Settings toggles with Firestore persistence

## Next Steps

1. **For immediate testing:**
   - Use Firebase Console to send test notifications
   - Verify tokens are being saved

2. **For production:**
   - Implement Cloud Functions (recommended)
   - Deploy notification sending logic
   - Test end-to-end flow

3. **Future enhancements:**
   - Add notification channels (Android)
   - Custom notification sounds
   - Rich notifications with images
   - Action buttons on notifications
   - Email notifications
