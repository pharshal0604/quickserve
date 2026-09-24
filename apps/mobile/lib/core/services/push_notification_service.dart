import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickserve_mobile/app.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
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

          final notification = message.notification;
          if (notification != null) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF2C3E50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 5),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.title != null)
                      Text(
                        notification.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    if (notification.body != null) Text(notification.body!),
                  ],
                ),
                action: SnackBarAction(
                  label: 'View',
                  textColor: const Color(0xFF1ABC9C),
                  onPressed: () {
                    // Could use router here to navigate to specific request if data contains requestId
                  },
                ),
              ),
            );
          }
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
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
      log('=============================================');
      log('YOUR FCM TOKEN:');
      log(token);
      log('=============================================');
    } catch (e) {
      log('Failed to save FCM token: $e');
    }
  }

  Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
      }
      await _messaging.deleteToken();
    } catch (e) {
      log('Error removing FCM token: $e');
    }
  }
}
