import 'package:shared/entities/counter_entity.dart';
import 'package:shared/utils/model_helpers.dart';

/// A yearly request-code counter stored in `counters/{year}`.
class Counter {
  /// Creates a request counter.
  const Counter({required this.lastRequestNumber});

  /// Parses a counter from Firestore field names.
  factory Counter.fromMap(Map<String, dynamic> map) {
    return Counter(
      lastRequestNumber: readRequired<int>(map, 'lastRequestNumber'),
    );
  }

  /// The last allocated request sequence number.
  final int lastRequestNumber;

  /// Converts this counter to Firestore field names and values.
  Map<String, dynamic> toMap() => {'lastRequestNumber': lastRequestNumber};

  @override
  bool operator ==(Object other) {
    return other is Counter && other.lastRequestNumber == lastRequestNumber;
  }

  @override
  int get hashCode => lastRequestNumber.hashCode;

  /// Converts this model to a pure-Dart domain entity.
  CounterEntity toEntity() =>
      CounterEntity(lastRequestNumber: lastRequestNumber);

  /// Creates this model from a pure-Dart domain entity.
  factory Counter.fromEntity(CounterEntity entity) =>
      Counter(lastRequestNumber: entity.lastRequestNumber);
}
