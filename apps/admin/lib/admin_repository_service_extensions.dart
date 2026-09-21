import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

import 'admin_repository.dart';

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
    final ref = await firestore.collection(CollectionNames.services).add({
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
    await firestore.collection(CollectionNames.services).doc(serviceId).update({
      'name': normalizedName,
      'description': normalizedDescription,
      'active': active,
    });
  }
}
