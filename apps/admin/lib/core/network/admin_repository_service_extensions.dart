import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';

extension AdminRepositoryServiceMutations on AdminRepository {
  Future<String> createService({
    required String name,
    required String description,
    required bool active,
  }) async {
    final normalizedName = name.trim();
    final normalizedDescription = description.trim();
    if (!ServiceNames.values.contains(normalizedName)) {
      throw ArgumentError(
        'Service must be one of: ${ServiceNames.values.join(', ')}.',
      );
    }
    if (normalizedDescription.isEmpty) {
      throw ArgumentError('Service description is required.');
    }
    final duplicate = await firestore
        .collection(CollectionNames.services)
        .where('name', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw StateError('A service with this name already exists.');
    }
    final serviceId = ServiceNames.documentIdFor(normalizedName);
    final ref = firestore.collection(CollectionNames.services).doc(serviceId);
    final canonical = await ref.get();
    if (canonical.exists) {
      throw StateError('A service with this name already exists.');
    }
    await ref.set({
      'name': normalizedName,
      'description': normalizedDescription,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateService({
    required String serviceId,
    required String name,
    required String description,
    required bool active,
  }) async {
    final normalizedName = name.trim();
    final normalizedDescription = description.trim();
    if (!ServiceNames.values.contains(normalizedName)) {
      throw ArgumentError(
        'Service must be one of: ${ServiceNames.values.join(', ')}.',
      );
    }
    if (normalizedDescription.isEmpty) {
      throw ArgumentError('Service description is required.');
    }
    final canonicalId = ServiceNames.documentIdFor(normalizedName);
    final currentRef = firestore
        .collection(CollectionNames.services)
        .doc(serviceId);
    final canonicalRef = firestore
        .collection(CollectionNames.services)
        .doc(canonicalId);

    if (serviceId != canonicalId) {
      final current = await currentRef.get();
      final canonical = await canonicalRef.get();
      if (canonical.exists) {
        throw StateError(
          'The canonical service record already exists. Refresh the service list and edit that record instead.',
        );
      }
      await canonicalRef.set({
        'name': normalizedName,
        'description': normalizedDescription,
        'active': active,
        'createdAt':
            current.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      // Deletes are intentionally disallowed by Firestore rules, so leave the
      // legacy record in place but make it unavailable to customers.
      await currentRef.update({'active': false});
      return;
    }

    await canonicalRef.update({
      'name': normalizedName,
      'description': normalizedDescription,
      'active': active,
    });
  }
}
