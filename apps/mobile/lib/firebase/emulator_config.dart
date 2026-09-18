const bool useEmulators = bool.fromEnvironment('FIREBASE_USE_EMULATORS');

const String emulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

const int authEmulatorPort = int.fromEnvironment(
  'FIREBASE_AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);

const int firestoreEmulatorPort = int.fromEnvironment(
  'FIREBASE_FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);
