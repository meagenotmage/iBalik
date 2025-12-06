import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Cloud Messaging for push notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission for notifications');
        }

        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveFCMToken(token);
          if (kDebugMode) {
            print('FCM Token: $token');
          }
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages (when app is in background but not terminated)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        
        // Check if app was opened from a notification
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          print('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notifications: $e');
      }
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
    
    // You can show a local notification here or update UI
    // For now, the in-app notification system will handle this
  }

  /// Handle when user taps on a notification (app in background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened app:');
      print('Data: ${message.data}');
    }
    
    // Navigate to appropriate screen based on notification type
    final String? type = message.data['type'];
    final String? actionRoute = message.data['actionRoute'];
    
    if (type != null && actionRoute != null) {
      // Handle navigation based on type
      // You can emit an event or use a global navigator key to navigate
      if (kDebugMode) {
        print('Should navigate to: $actionRoute');
      }
    }
  }

  /// Send push notification to a specific user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if user has push notifications enabled
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final settings = userData['settings'] as Map<String, dynamic>?;
      final notifications = settings?['notifications'] as Map<String, dynamic>?;
      
      // Check if push notifications are enabled for this user
      final pushEnabled = notifications?['pushNotifications'] as bool? ?? true;
      if (!pushEnabled) {
        if (kDebugMode) {
          print('Push notifications disabled for user $userId');
        }
        return;
      }

      // Check if claim notifications are enabled (if this is a claim notification)
      final isClaimNotification = data?['type']?.toString().contains('claim') ?? false;
      if (isClaimNotification) {
        final claimNotifEnabled = notifications?['claimNotifications'] as bool? ?? true;
        if (!claimNotifEnabled) {
          if (kDebugMode) {
            print('Claim notifications disabled for user $userId');
          }
          return;
        }
      }

      final fcmToken = userData['fcmToken'] as String?;
      if (fcmToken == null) {
        if (kDebugMode) {
          print('No FCM token found for user $userId');
        }
        return;
      }

      // In a production app, you would call your backend API here
      // which would use Firebase Admin SDK to send the notification
      // For now, we'll just log it
      if (kDebugMode) {
        print('Would send push notification to $userId:');
        print('Token: $fcmToken');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // TODO: Implement backend API call to send push notification via Firebase Admin SDK
      // Example: await http.post('YOUR_BACKEND_API/send-notification', body: {...})
      
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification: $e');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  if (kDebugMode) {
    print('Background message received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }
}
