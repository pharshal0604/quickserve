import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    try {
      // 1. Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted FCM permission');
        
        // 2. Get the device token
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(userId, token);
        }

        // 3. Listen to token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(userId, newToken);
        });

        // 4. Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          log('Received FCM message in foreground: ${message.messageId}');
          // In a real app, you might show a local notification here
          // using flutter_local_notifications if desired.
        });
      } else {
        log('User declined or has not accepted FCM permission');
      }
    } catch (e) {
      log('Error initializing FCM: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
      log('Saved FCM token for user $userId');
    } catch (e) {
      log('Failed to save FCM token: $e');
    }
  }

  Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set(
          {
            'fcmTokens': FieldValue.arrayRemove([token]),
          },
          SetOptions(merge: true),
        );
      }
      await _messaging.deleteToken();
    } catch (e) {
      log('Error removing FCM token: $e');
    }
  }
}
