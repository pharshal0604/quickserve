import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickserve_mobile/utils/app_exceptions.dart';
import 'package:quickserve_mobile/utils/firebase_error_mapper.dart';

const genericFallback = 'Something went wrong. Please try again.';
const unknownAuthCode = 'unknown-auth-error';
const unknownUserRepoCode = 'unknown-user-repository-error';

void main() {
  group('mapAuthError', () {
    final authCases = <({String code, String expected})>[
      (
        code: 'user-not-found',
        expected: 'No account was found for that email.',
      ),
      (code: 'wrong-password', expected: 'The email or password is incorrect.'),
      (code: 'invalid-email', expected: 'Enter a valid email address.'),
      (code: 'user-disabled', expected: 'This account has been disabled.'),
      (
        code: 'too-many-requests',
        expected: 'Too many attempts. Please try again later.',
      ),
      (
        code: 'network-request-failed',
        expected:
            'A network error occurred. Check your connection and try again.',
      ),
      (
        code: 'email-already-in-use',
        expected: 'An account already uses that email.',
      ),
      (code: 'weak-password', expected: 'Choose a stronger password.'),
      (
        code: 'operation-not-allowed',
        expected: 'This sign-in method is unavailable.',
      ),
      (
        code: 'invalid-credential',
        expected: 'The email or password is incorrect.',
      ),
    ];

    for (final c in authCases) {
      test('maps ${c.code}', () {
        final result = mapAuthError(
          FirebaseAuthException(code: c.code, message: 'ignored'),
        );
        expect(result, isA<AuthException>());
        expect(result.code, equals(c.code));
        expect(result.userMessage, equals(c.expected));
      });
    }

    final firebaseCases = <({String code, String expected})>[
      (
        code: 'permission-denied',
        expected: 'You are not authorized to perform this action.',
      ),
      (
        code: 'unavailable',
        expected: 'The service is unavailable. Please try again.',
      ),
      (
        code: 'deadline-exceeded',
        expected: 'The request took too long. Please try again.',
      ),
      (code: 'not-found', expected: 'The requested record was not found.'),
      (
        code: 'failed-precondition',
        expected: 'The operation cannot be completed right now.',
      ),
    ];

    for (final c in firebaseCases) {
      test('maps ${c.code}', () {
        final result = mapAuthError(
          FirebaseException(
            code: c.code,
            message: 'ignored',
            plugin: 'cloud_firestore',
          ),
        );
        expect(result, isA<AuthException>());
        expect(result.code, equals(c.code));
        expect(result.userMessage, equals(c.expected));
      });
    }

    test('maps an unknown FirebaseException code to the generic fallback', () {
      final result = mapAuthError(
        FirebaseException(
          code: 'any-unknown-code',
          message: 'ignored',
          plugin: 'cloud_firestore',
        ),
      );
      expect(result, isA<AuthException>());
      expect(result.code, equals('any-unknown-code'));
      expect(result.userMessage, equals(genericFallback));
    });

    test(
      'maps non-Firebase inputs to the unknown auth marker and fallback',
      () {
        final results = [
          mapAuthError(Exception('boom')),
          mapAuthError(ArgumentError('bad')),
          mapAuthError('a string'),
        ];

        for (final result in results) {
          expect(result, isA<AuthException>());
          expect(result.code, equals(unknownAuthCode));
          expect(result.userMessage, equals(genericFallback));
        }
      },
    );
  });

  group('mapUserRepoError', () {
    final cases = <({String code, String expected})>[
      (
        code: 'permission-denied',
        expected: 'You are not authorized to load your profile.',
      ),
      (
        code: 'unavailable',
        expected: 'Your profile is temporarily unavailable.',
      ),
      (
        code: 'deadline-exceeded',
        expected: 'Loading your profile took too long.',
      ),
      (code: 'not-found', expected: 'Your profile was not found.'),
      (
        code: 'failed-precondition',
        expected: 'Your profile cannot be loaded right now.',
      ),
    ];

    for (final c in cases) {
      test('maps ${c.code}', () {
        final result = mapUserRepoError(
          FirebaseException(
            code: c.code,
            message: 'ignored',
            plugin: 'cloud_firestore',
          ),
        );
        expect(result, isA<UserRepositoryException>());
        expect(result.code, equals(c.code));
        expect(result.userMessage, equals(c.expected));
      });
    }

    test('maps an unknown FirebaseException code to the generic fallback', () {
      final result = mapUserRepoError(
        FirebaseException(
          code: 'any-unknown-code',
          message: 'ignored',
          plugin: 'cloud_firestore',
        ),
      );
      expect(result, isA<UserRepositoryException>());
      expect(result.code, equals('any-unknown-code'));
      expect(result.userMessage, equals(genericFallback));
    });

    test('maps non-Firebase inputs to the unknown user repository marker and fallback', () {
      final results = [
        mapUserRepoError(Exception('boom')),
        mapUserRepoError(ArgumentError('bad')),
        mapUserRepoError(42),
      ];

      for (final result in results) {
        expect(result, isA<UserRepositoryException>());
        expect(result.code, equals(unknownUserRepoCode));
        expect(result.userMessage, equals(genericFallback));
      }
    });
  });

  group('toString safety', () {
    test('returns the exact output for both exception subclasses', () {
      expect(
        const AuthException('user-not-found', 'msg').toString(),
        equals('AuthException(code: user-not-found)'),
      );
      expect(
        const UserRepositoryException('permission-denied', 'msg').toString(),
        equals('UserRepositoryException(code: permission-denied)'),
      );
    });

    test('toString does not contain the userMessage', () {
      const authMessage = 'auth message';
      const userRepoMessage = 'user repository message';
      const authException = AuthException('user-not-found', authMessage);
      const userRepoException = UserRepositoryException(
        'permission-denied',
        userRepoMessage,
      );

      expect(authException.toString(), isNot(contains(authMessage)));
      expect(userRepoException.toString(), isNot(contains(userRepoMessage)));
    });

    test('both exception subclasses are AppException subtypes', () {
      const authException = AuthException('user-not-found', 'msg');
      const userRepoException = UserRepositoryException(
        'permission-denied',
        'msg',
      );

      expect(authException, isA<AppException>());
      expect(userRepoException, isA<AppException>());
    });
  });

  group('no raw error text leaks', () {
    const sentinel = 'SENTINEL_DO_NOT_LEAK_TO_USER';

    test('does not leak raw FirebaseAuthException text', () {
      final result = mapAuthError(
        FirebaseAuthException(code: 'wrong-password', message: sentinel),
      );

      expect(result.userMessage, isNot(contains(sentinel)));
    });

    test('does not leak raw FirebaseException text', () {
      final error = FirebaseException(
        code: 'permission-denied',
        message: sentinel,
        plugin: 'cloud_firestore',
      );

      final authResult = mapAuthError(error);
      final userRepoResult = mapUserRepoError(error);

      expect(authResult.userMessage, isNot(contains(sentinel)));
      expect(userRepoResult.userMessage, isNot(contains(sentinel)));
    });

    test('does not leak raw non-Firebase exception text', () {
      final authResult = mapAuthError(Exception(sentinel));
      final userRepoResult = mapUserRepoError(Exception(sentinel));

      expect(authResult.userMessage, isNot(contains(sentinel)));
      expect(userRepoResult.userMessage, isNot(contains(sentinel)));
    });
  });
}
