import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import '../utils/app_exceptions.dart';

/// Reads the QuickServe service catalog from Firestore.
final class ServiceRepository {
  /// Creates a service repository.
  const ServiceRepository();

  /// Streams active services ordered by their display name.
  Stream<List<shared.Service>> watchActiveServices() {
    return FirebaseFirestore.instance
        .collection(shared.CollectionNames.services)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => shared.Service.fromMap(doc.data()))
              .toList();
          services.sort((left, right) => left.name.compareTo(right.name));
          return services;
        });
  }

  /// Loads all service records available to the authenticated user.
  Future<List<shared.Service>> getServices() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(shared.CollectionNames.services)
          .where('active', isEqualTo: true)
          .get();
      final services = snapshot.docs
          .map((doc) => shared.Service.fromMap(doc.data()))
          .toList();
      services.sort((left, right) => left.name.compareTo(right.name));
      return services;
    } catch (error) {
      throw _mapError(error, 'Could not load services. Please try again.');
    }
  }
}

RequestRepositoryException _mapError(Object error, String message) {
  if (error is RequestRepositoryException) return error;
  if (error is FirebaseException) {
    final safeMessage = switch (error.code) {
      'permission-denied' => 'You are not authorized to view these services.',
      'unavailable' || 'deadline-exceeded' =>
        'The service is temporarily unavailable. Please try again.',
      _ => message,
    };
    return RequestRepositoryException(error.code, safeMessage);
  }
  return RequestRepositoryException('service-read-failed', message);
}
