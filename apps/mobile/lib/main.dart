import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase/emulator_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestoreEmulatorPort,
    );
  }

  runApp(const ProviderScope(child: QuickServeApp()));
}
