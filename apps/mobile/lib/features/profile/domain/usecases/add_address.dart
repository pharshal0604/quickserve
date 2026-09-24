import '../repositories/user_repository_interface.dart';

/// Parameters for address operations.
class AddressParams {
  const AddressParams({required this.uid, required this.address});

  final String uid;
  final String address;
}

/// Use case to add an address.
class AddAddress {
  /// Creates the usecase.
  const AddAddress(this._repository);
  final UserRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(AddressParams params) =>
      _repository.addAddress(uid: params.uid, address: params.address);
}
