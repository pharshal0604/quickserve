import '../repositories/user_repository_interface.dart';
import 'add_address.dart'; // Reuse AddressParams

/// Use case to remove an address.
class RemoveAddress {
  /// Creates the usecase.
  const RemoveAddress(this._repository);
  final UserRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(AddressParams params) =>
      _repository.removeAddress(uid: params.uid, address: params.address);
}
