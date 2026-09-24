import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides notification reads and updates for a user.
final class NotificationsRepository {
  /// Creates a notifications repository.
  const NotificationsRepository();

  /// Streams the notifications for [userId], ordered by most recent first.
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Marks a single notification as read.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
