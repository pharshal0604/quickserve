/// A pure-Dart domain entity representing a yearly request-code counter.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `Counter` model.
class CounterEntity {
  /// Creates a counter entity.
  const CounterEntity({required this.lastRequestNumber});

  /// The last allocated request sequence number.
  final int lastRequestNumber;

  @override
  bool operator ==(Object other) {
    return other is CounterEntity &&
        other.lastRequestNumber == lastRequestNumber;
  }

  @override
  int get hashCode => lastRequestNumber.hashCode;
}
