# Firebase Setup Instructions for iBalik

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter project name: `ibalik` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Register Your App

### For Web App:
1. In Firebase Console, click the Web icon (</>) to add a web app
2. App nickname: `iBalik Web`
3. Check "Also set up Firebase Hosting"
4. Click "Register app"
5. Copy the Firebase configuration

### For Android App:
1. Click the Android icon to add an Android app
2. Android package name: `com.wvsu.flutter_ibalik` (check android/app/build.gradle)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### For iOS App (if needed):
1. Click the iOS icon to add an iOS app
2. iOS bundle ID: Check in Xcode or ios/Runner.xcodeproj
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

## Step 3: Enable Authentication

1. In Firebase Console, go to "Build" > "Authentication"
2. Click "Get started"
3. Enable "Email/Password" authentication
4. Click "Save"

## Step 4: Set Up Firestore Database

1. In Firebase Console, go to "Build" > "Firestore Database"
2. Click "Create database"
3. Start in **production mode** (we'll add rules later)
4. Choose a location (closest to Philippines: asia-southeast1)
5. Click "Enable"

## Step 5: Configure Firestore Security Rules

Go to "Firestore Database" > "Rules" and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Allow users to read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to create their own document on signup
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to update their own data
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to delete their own account
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Add more collections rules here as needed
  }
}
```

Click "Publish"

## Step 6: Install FlutterFire CLI

Run these commands in your terminal:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Automatically generate `firebase_options.dart`
- Configure all platforms (Web, Android, iOS, etc.)

## Step 7: Update main.dart

The main.dart has already been updated to initialize Firebase.
Make sure to import the generated `firebase_options.dart`:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## Step 8: Test the App

1. Run `flutter pub get`
2. Run your app: `flutter run`
3. Try signing up with a WVSU email
4. Check your email for verification
5. Verify and try logging in

## Email Domain Restriction

The app is configured to only accept `@wvsu.edu.ph` email addresses.
This is handled in `auth_service.dart`.

## Troubleshooting

### If you get "MissingPluginException":
```bash
flutter clean
flutter pub get
```

### If Firebase is not initialized:
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists
- Verify Firebase.initializeApp() is called before runApp()

### If authentication doesn't work:
- Check Firebase Console > Authentication is enabled
- Verify email/password provider is enabled
- Check browser console for errors (if testing on web)

## Next Steps

After Firebase is set up:
1. Test user registration
2. Test email verification
3. Test login
4. Add more features (lost items, found items, etc.)
