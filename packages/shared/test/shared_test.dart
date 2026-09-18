import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

Timestamp _time() => Timestamp.fromDate(DateTime.utc(2026, 1, 1));

void main() {
  group('enums', () {
    test('UserRole round-trips every stored value', () {
      for (final value in UserRole.values) {
        expect(UserRole.fromStoredValue(value.toStoredValue()), value);
      }
    });

    test('RequestStatus round-trips every stored value', () {
      for (final value in RequestStatus.values) {
        expect(RequestStatus.fromStoredValue(value.toStoredValue()), value);
      }
    });

    test('RequestPriority round-trips every stored value', () {
      for (final value in RequestPriority.values) {
        expect(
          RequestPriority.fromStoredValue(value.toStoredValue()),
          value,
        );
      }
    });

    test('AuditEvent round-trips every stored value', () {
      for (final value in AuditEvent.values) {
        expect(AuditEvent.fromStoredValue(value.toStoredValue()), value);
      }
    });

    test('invalid enum values throw SharedParseException', () {
      expect(
        () => UserRole.fromStoredValue('invalid_role'),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => RequestStatus.fromStoredValue('invalid_status'),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => RequestPriority.fromStoredValue('invalid_priority'),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => AuditEvent.fromStoredValue('UNKNOWN'),
        throwsA(isA<SharedParseException>()),
      );
    });
  });

  group('models', () {
    final timestamp = _time();

    test('User round-trips through Firestore field names', () {
      final map = {
        'role': 'customer',
        'name': 'Asha Rao',
        'email': 'asha@example.test',
        'phone': '+919876543210',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };
      final user = User.fromMap(map);
      expect(user.toMap(), map);
      expect(user, User.fromMap(user.toMap()));
    });

    test('Service round-trips through Firestore field names', () {
      final map = {
        'name': 'Electrical',
        'description': 'Electrical service',
        'active': true,
        'createdAt': timestamp,
      };
      final service = Service.fromMap(map);
      expect(service.toMap(), map);
      expect(service, Service.fromMap(service.toMap()));
    });

    test('Request round-trips with nullable fields', () {
      final map = {
        'requestCode': 'REQ-2026-000123',
        'customerId': 'customer-1',
        'agentId': null,
        'serviceType': 'Electrical',
        'description': 'Repair a socket',
        'preferredDateTime': timestamp,
        'address': '12 Main Street',
        'priority': 'medium',
        'status': 'created',
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'cancellationReason': null,
      };
      final request = Request.fromMap(map);
      expect(request.toMap(), map);
      expect(request, Request.fromMap(request.toMap()));
    });

    test('StatusHistory round-trips nullable fields', () {
      final map = {
        'fromStatus': null,
        'toStatus': 'created',
        'changedBy': 'customer-1',
        'changedAt': timestamp,
        'note': null,
      };
      final history = StatusHistory.fromMap(map);
      expect(history.toMap(), map);
      expect(history, StatusHistory.fromMap(history.toMap()));
    });

    test('AuditLog round-trips nested values', () {
      final map = {
        'actorUserId': 'admin-1',
        'actorRole': 'admin',
        'action': 'REQUEST_ASSIGNED',
        'targetType': 'request',
        'targetId': 'request-1',
        'oldValue': {'agentId': null},
        'newValue': {'agentId': 'agent-1'},
        'result': 'success',
        'timestamp': timestamp,
      };
      final log = AuditLog.fromMap(map);
      expect(log.toMap(), map);
      expect(log, AuditLog.fromMap(log.toMap()));
    });

    test('Counter round-trips through Firestore field names', () {
      final map = {'lastRequestNumber': 123};
      final counter = Counter.fromMap(map);
      expect(counter.toMap(), map);
      expect(counter, Counter.fromMap(counter.toMap()));
    });

    test('models reject missing or malformed fields with SharedParseException', () {
      expect(
        () => User.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => Service.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => Request.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => StatusHistory.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => AuditLog.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
      expect(
        () => Counter.fromMap(<String, dynamic>{}),
        throwsA(isA<SharedParseException>()),
      );
    });
  });

  group('validators', () {
    test('name validator accepts and rejects expected values', () {
      expect(validateName('Asha Rao').isValid, isTrue);
      expect(validateName('').isValid, isFalse);
      expect(validateName('A').isValid, isFalse);
    });

    test('email validator accepts and rejects expected values', () {
      expect(validateEmail('asha@example.test').isValid, isTrue);
      expect(validateEmail('not-an-email').isValid, isFalse);
    });

    test('phone validator accepts and rejects expected values', () {
      expect(validatePhone('+919876543210').isValid, isTrue);
      expect(validatePhone('123').isValid, isFalse);
    });

    test('description validator accepts and rejects expected values', () {
      expect(validateDescription('Repair a socket').isValid, isTrue);
      expect(validateDescription('').isValid, isFalse);
      expect(validateDescription('x' * 2001).isValid, isFalse);
    });

    test('address validator accepts and rejects expected values', () {
      expect(validateAddress('12 Main Street').isValid, isTrue);
      expect(validateAddress('No').isValid, isFalse);
    });

    test('priority validator accepts only fixed priorities', () {
      expect(validatePriority('low').isValid, isTrue);
      expect(validatePriority('invalid_priority').isValid, isFalse);
    });

    test('status validator accepts only fixed statuses', () {
      expect(validateStatus('in_progress').isValid, isTrue);
      expect(validateStatus('invalid_status').isValid, isFalse);
    });

    test('role validator accepts only fixed roles', () {
      expect(validateRole('admin').isValid, isTrue);
      expect(validateRole('invalid_role').isValid, isFalse);
    });

    test('request-code validator accepts only the fixed format', () {
      expect(validateRequestCode('REQ-2026-000123').isValid, isTrue);
      expect(validateRequestCode('REQ-26-123').isValid, isFalse);
    });

    test('invalid validation result carries a reason', () {
      final result = validateEmail('invalid');
      expect(result.reason, isNotNull);
      expect(const ValidationResult.valid().reason, isNull);
    });
  });

  group('lifecycle', () {
    test('allows every valid lifecycle edge', () {
      expect(canTransition('created', 'assigned'), isTrue);
      expect(canTransition('created', 'cancelled'), isTrue);
      expect(canTransition('assigned', 'accepted'), isTrue);
      expect(canTransition('assigned', 'cancelled'), isTrue);
      expect(canTransition('accepted', 'in_progress'), isTrue);
      expect(canTransition('accepted', 'cancelled'), isTrue);
      expect(canTransition('in_progress', 'completed'), isTrue);
      expect(canTransition('in_progress', 'cancelled'), isTrue);
    });

    test('rejects invalid lifecycle edges', () {
      expect(canTransition('created', 'completed'), isFalse);
      expect(canTransition('completed', 'created'), isFalse);
      expect(canTransition('cancelled', 'assigned'), isFalse);
      expect(canTransition('assigned', 'in_progress'), isFalse);
    });

    test('enforces customer cancellation restriction', () {
      expect(
        isValidTransitionForRole('created', 'cancelled', 'customer'),
        isTrue,
      );
      expect(
        isValidTransitionForRole('assigned', 'cancelled', 'customer'),
        isTrue,
      );
      expect(
        isValidTransitionForRole('accepted', 'cancelled', 'customer'),
        isFalse,
      );
      expect(
        isCancellableByCustomer('in_progress'),
        isFalse,
      );
    });

    test('prevents Agents from cancelling', () {
      expect(
        isValidTransitionForRole('assigned', 'cancelled', 'agent'),
        isFalse,
      );
      expect(
        isValidTransitionForRole('assigned', 'accepted', 'agent'),
        isTrue,
      );
    });

    test('allows Admin cancellation from every non-terminal state', () {
      for (final status in [
        'created',
        'assigned',
        'accepted',
        'in_progress',
      ]) {
        expect(
          isValidTransitionForRole(status, 'cancelled', 'admin'),
          isTrue,
        );
      }
    });

    test('identifies terminal statuses', () {
      expect(isTerminalStatus('completed'), isTrue);
      expect(isTerminalStatus('cancelled'), isTrue);
      expect(isTerminalStatus('assigned'), isFalse);
    });

    test('requireValidTransition throws only for illegal role transitions', () {
      expect(
        () => requireValidTransition('assigned', 'accepted', 'agent'),
        returnsNormally,
      );
      expect(
        () => requireValidTransition('assigned', 'cancelled', 'agent'),
        throwsA(isA<SharedLifecycleException>()),
      );
    });
  });

  group('request codes', () {
    test('formats and parses a request code', () {
      const code = 'REQ-2026-000123';
      expect(formatRequestCode(2026, 123), code);
      expect(parseRequestCode(code), const ParsedRequestCode(year: 2026, sequence: 123));
      expect(isValidRequestCode(code), isTrue);
    });

    test('pads zero and six-digit sequences', () {
      expect(formatRequestCode(2026, 0), 'REQ-2026-000000');
      expect(formatRequestCode(2026, 999999), 'REQ-2026-999999');
    });

    test('rejects invalid request-code input', () {
      expect(
        () => formatRequestCode(99, 1),
        throwsA(isA<SharedValidationException>()),
      );
      expect(
        () => formatRequestCode(2026, 1000000),
        throwsA(isA<SharedValidationException>()),
      );
      expect(
        () => parseRequestCode('REQ-2026-123'),
        throwsA(isA<SharedParseException>()),
      );
      expect(isValidRequestCode('REQ-2026-123'), isFalse);
    });
  });

  group('errors', () {
    test('typed error constructors preserve messages and causes', () {
      final cause = StateError('cause');
      final validation = SharedValidationException('bad', cause: cause);
      final parse = SharedParseException('bad parse');
      final lifecycle = SharedLifecycleException('bad transition');

      expect(validation.message, 'bad');
      expect(validation.cause, cause);
      expect(parse.message, 'bad parse');
      expect(lifecycle.message, 'bad transition');
      expect(validation.toString(), 'bad');
    });
  });
}
